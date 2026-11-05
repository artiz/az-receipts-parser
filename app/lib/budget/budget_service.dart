/// The budget as the app sees it: the year file in the chosen folder plus a
/// local queue of entries that have not reached the file yet.
///
/// Works like a Drive client: adding an entry is instant and local, the
/// queue is flushed into the xlsx whenever the file is reachable (app start,
/// resume, after each add, manual sync). Reading always re-fetches the file
/// so edits made on the laptop show up. A sync re-reads the file right
/// before writing, so a concurrent edit is only lost in the few hundred
/// milliseconds between that read and the write.
///
/// The displayed year follows the calendar: the current year's file is
/// loaded unless the user picked another one; when the year changes the app
/// moves on by itself (and can create the new file from the previous one).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/app_settings.dart';
import '../theme.dart' show LimitLevel;
import '../storage/folder_access.dart';
import 'budget_file.dart';
import 'entry_suggest.dart';
import 'xlsx_workbook.dart';

enum SyncState { noFolder, idle, syncing, offline, error }

final RegExp budgetFileName = RegExp(r'^Budget (20\d\d)\.xlsx$', caseSensitive: false);

const String xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class YearFileRef {
  const YearFileRef({required this.year, required this.entry});
  final int year;
  final FileEntry entry;
}

class BudgetService extends ChangeNotifier {
  BudgetService({required this.folder, required this.settings, this.queueDir, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final FolderAccess folder;
  final AppSettings settings;

  /// Where the pending queue is stored (app support dir by default).
  final Directory? queueDir;
  final DateTime Function() _clock;

  SyncState state = SyncState.noFolder;
  String? lastError;

  /// Files found in the folder, newest year first.
  List<YearFileRef> yearFiles = const [];

  /// The loaded year (the one entries are shown from).
  int? year;

  /// Set when the user picked a year by hand; otherwise the calendar year.
  bool _yearPinned = false;
  BudgetFile? file;
  Uint8List? _fileBytes;

  /// Entries waiting for the file, newest last.
  List<BudgetEntry> pending = [];

  /// Other years' files read for the overview, dropped on every sync.
  final Map<int, BudgetFile> _otherYears = {};

  Future<void>? _running;
  bool _syncAgain = false;

  // --- derived data ----------------------------------------------------------------

  /// File entries plus pending ones for the loaded year, oldest first.
  List<BudgetEntry> get entries {
    final out = <BudgetEntry>[...?file?.entries, ...pending.where((e) => year == null || e.date.year == year)];
    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return (a.row ?? 1 << 30).compareTo(b.row ?? 1 << 30);
    });
    return out;
  }

  /// Queued entries whose year has no file in the folder: they can never be
  /// written as they are (usually a mis-read receipt date).
  List<BudgetEntry> get strandedPending => [
        for (final e in pending)
          if (_refForYear(e.date.year) == null) e,
      ];

  List<BudgetCategory> get categories => file?.categories ?? const [];

  EntrySuggestions get suggestions => EntrySuggestions(entries, now: _clock());

  double? get monthLimit1 => file?.setting('Monatslimit 1');
  double? get monthLimit2 => file?.setting('Monatslimit 2');

  /// Expense limits for single entries (Ausgabenlimit 1..3), ascending.
  List<double> get entryLimits {
    final f = file;
    if (f == null) return const [];
    final out = <double>[];
    for (final s in f.settings) {
      if (s.label.toLowerCase().startsWith('ausgabenlimit') && s.value != null) out.add(s.value!);
    }
    out.sort();
    return out;
  }

  /// Expenses (expense categories only) booked in [month] of the loaded year.
  double monthExpenses(int month) {
    final f = file;
    if (f == null) return 0;
    var sum = 0.0;
    for (final e in entries) {
      if (e.month != month) continue;
      if (f.category(e.category)?.isExpense ?? false) sum += e.amount;
    }
    return sum;
  }

  /// Traffic light for [expenses] against Monatslimit 1 and 2.
  LimitLevel limitLevel(double expenses) {
    final l2 = monthLimit2;
    final l1 = monthLimit1;
    if (l2 != null && l2 > 0 && expenses >= l2) return LimitLevel.over;
    if (l1 != null && l1 > 0 && expenses >= l1) return LimitLevel.warn;
    return LimitLevel.ok;
  }

  /// The calendar month's level (only meaningful when the loaded year is the
  /// calendar year).
  LimitLevel get currentMonthLevel => year == currentYear ? limitLevel(monthExpenses(_clock().month)) : LimitLevel.ok;

  /// Set Monatslimit 1 and 2 in `Einstellungen`.
  Future<void> setMonthLimits(double limit1, double limit2, {int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) {
      f.setSetting('Monatslimit 1', limit1);
      f.setSetting('Monatslimit 2', limit2);
    });
  }

  /// True when the calendar year has no file yet (and one could be created
  /// from the latest file).
  bool get currentYearMissing => settings.hasFolder && yearFiles.isNotEmpty && _refForYear(_clock().year) == null;

  int get currentYear => _clock().year;

  /// An existing entry that looks like [entry] (same category and amount,
  /// date within [days]): what a scanned receipt of an already typed
  /// purchase produces.
  BudgetEntry? findSimilar(BudgetEntry entry, {int days = 3}) {
    BudgetEntry? best;
    var bestDays = days + 1;
    for (final e in entries) {
      if (e.category != entry.category) continue;
      if ((e.amount - entry.amount).abs() > 0.011) continue;
      final d = e.date.difference(entry.date).inDays.abs();
      if (d <= days && d < bestDays) {
        best = e;
        bestDays = d;
      }
    }
    return best;
  }

  // --- lifecycle --------------------------------------------------------------------

  Future<void> init() async {
    await _loadQueue();
    if (!settings.hasFolder) {
      state = SyncState.noFolder;
      notifyListeners();
      return;
    }
    await sync();
  }

  Future<bool> chooseFolder() async {
    final info = await folder.pickFolder();
    if (info == null) return false;
    await settings.setFolder(info.uri, info.name);
    await sync();
    return true;
  }

  Future<void> forgetFolder() async {
    await settings.setFolder(null, null);
    file = null;
    _fileBytes = null;
    year = null;
    _yearPinned = false;
    yearFiles = const [];
    state = SyncState.noFolder;
    notifyListeners();
  }

  // --- adding and editing -------------------------------------------------------------

  /// Queue an entry and try to push it right away.
  Future<void> addEntry(BudgetEntry entry) => addEntries([entry]);

  Future<void> addEntries(List<BudgetEntry> newEntries) async {
    for (final e in newEntries) {
      pending.add(e.copyWith(pendingId: _newId()));
    }
    await _saveQueue();
    notifyListeners();
    unawaited(sync());
  }

  /// Delete an entry: a queued one leaves the queue, a file row is blanked
  /// (the row stays empty so nothing else moves).
  Future<void> deleteEntry(BudgetEntry e) async {
    if (e.isPending) return removePending(e.pendingId!);
    final row = e.row;
    if (row == null) return;
    await _withFile(e.date.year, (f) => f.clearEntryRow(row));
  }

  Future<void> removePending(String pendingId) async {
    pending.removeWhere((e) => e.pendingId == pendingId);
    await _saveQueue();
    notifyListeners();
  }

  /// Replace [old] with [updated]: a queued entry is swapped in the queue, a
  /// file row is rewritten in place (same row, same year file).
  Future<void> updateEntry(BudgetEntry old, BudgetEntry updated) async {
    if (old.isPending) {
      final i = pending.indexWhere((e) => e.pendingId == old.pendingId);
      if (i < 0) return addEntry(updated);
      if (updated.date.year == old.date.year || _refForYear(updated.date.year) != null) {
        pending[i] = updated.copyWith(pendingId: old.pendingId);
      }
      await _saveQueue();
      notifyListeners();
      unawaited(sync());
      return;
    }
    final row = old.row;
    if (row == null) throw StateError('entry has neither a row nor a queue id');
    if (updated.date.year != old.date.year) {
      // Moving a booking to another year: the row of the old file is cleared
      // and the entry queued for the other file.
      await _withFile(old.date.year, (f) => f.clearEntryRow(row));
      await addEntry(updated);
      return;
    }
    await _withFile(old.date.year, (f) => f.updateEntry(row, updated.copyWith(row: row)));
  }

  /// "+6 Glühwein": add to the amount and append the detail to the note.
  Future<void> addToEntry(BudgetEntry entry, double amount, String detail) async {
    final sign = entry.amount < 0 ? -1 : 1;
    final newAmount = ((entry.amount + sign * amount.abs()) * 100).round() / 100;
    final piece = '+${_fmt(amount.abs())}${detail.trim().isEmpty ? '' : ' ${detail.trim()}'}';
    final note = entry.note.isEmpty ? piece : '${entry.note}; $piece';
    await updateEntry(entry, entry.copyWith(amount: newAmount, note: note));
  }

  /// Append text to an existing entry's note (receipt scanned after the
  /// purchase was typed by hand).
  Future<void> appendNote(BudgetEntry entry, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final note = entry.note.isEmpty ? t : (entry.note.contains(t) ? entry.note : '${entry.note}; $t');
    if (note == entry.note) return;
    await updateEntry(entry, entry.copyWith(note: note));
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll('.', ',');

  /// Change an input cell of `Übersicht` (Kontostand, Sparkonto, Kreditkarte
  /// offen) in the loaded year file. Written through immediately.
  Future<void> setOverviewInput(String labelPrefix, int month, double? value, {String? formula, int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) => f.setOverviewInput(labelPrefix, month, value, formula: formula));
  }

  Future<void> setPlan(String category, int month, double value, {int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) => f.setPlan(category, month, value));
  }

  Future<void> setBudgetSetting(String label, double value, {String note = ''}) async {
    await _withFile(year ?? currentYear, (f) => f.setSetting(label, value, note: note));
  }

  Future<void> _withFile(int y, void Function(BudgetFile) change) async {
    final ref = _refForYear(y);
    if (ref == null) throw StateError('no file for $y');
    final bytes = await folder.readFile(ref.entry.uri);
    final f = BudgetFile.open(bytes, yearHint: ref.year);
    change(f);
    await folder.writeFile(ref.entry.uri, f.save());
    await sync();
  }

  /// Create `Budget <newYear>.xlsx` from the latest existing file: same
  /// categories, settings and plan, no bookings, empty account inputs.
  Future<void> createYearFile(int newYear) async {
    final uri = settings.folderUri;
    if (uri == null) throw StateError('no folder');
    if (_refForYear(newYear) != null) return;
    if (yearFiles.isEmpty) throw StateError('no file to copy from');
    final source = yearFiles.first;
    final bytes = await folder.readFile(source.entry.uri);
    final f = BudgetFile.open(bytes, yearHint: source.year);
    f.clearEntries();
    f.clearOverviewInputs();
    f.setTitleYear(newYear);
    await folder.createFile(uri, 'Budget $newYear.xlsx', xlsxMime, f.save());
    _yearPinned = false;
    await sync();
  }

  // --- sync -------------------------------------------------------------------------

  /// Re-read the folder, flush the queue into the matching year files, reload.
  Future<void> sync() {
    final running = _running;
    if (running != null) {
      // One more pass after the current one, so a change made meanwhile is
      // picked up; callers await the whole thing.
      _syncAgain = true;
      return running;
    }
    return _running = _runSync();
  }

  Future<void> _runSync() async {
    try {
      do {
        _syncAgain = false;
        await _syncOnce();
      } while (_syncAgain);
    } finally {
      _running = null;
    }
  }

  Future<void> _syncOnce() async {
    final uri = settings.folderUri;
    if (uri == null) {
      state = SyncState.noFolder;
      notifyListeners();
      return;
    }
    state = SyncState.syncing;
    lastError = null;
    _otherYears.clear();
    notifyListeners();
    try {
      final files = await folder.listFiles(uri);
      yearFiles = [
        for (final f in files)
          if (budgetFileName.hasMatch(f.name)) YearFileRef(year: int.parse(budgetFileName.firstMatch(f.name)!.group(1)!), entry: f),
      ]..sort((a, b) => b.year.compareTo(a.year));

      // Flush the queue, grouped by the year each entry belongs to.
      final byYear = <int, List<BudgetEntry>>{};
      for (final e in pending) {
        byYear.putIfAbsent(e.date.year, () => []).add(e);
      }
      for (final entry in byYear.entries) {
        final ref = _refForYear(entry.key);
        if (ref == null) continue; // stays queued (see strandedPending) until a file for that year exists
        final bytes = await folder.readFile(ref.entry.uri);
        final f = BudgetFile.open(bytes, yearHint: ref.year);
        f.appendEntries([for (final e in entry.value) e.copyWith(clearPending: true)]);
        await folder.writeFile(ref.entry.uri, f.save());
        final ids = entry.value.map((e) => e.pendingId).toSet();
        pending.removeWhere((e) => ids.contains(e.pendingId));
        await _saveQueue();
      }

      // The year to show: the calendar year unless pinned, else the newest file.
      final wanted = _yearPinned && year != null ? year! : currentYear;
      final ref = _refForYear(wanted) ?? (yearFiles.isEmpty ? null : yearFiles.first);
      if (ref == null) {
        file = null;
        _fileBytes = null;
        year = null;
        lastError = 'no Budget <year>.xlsx in the folder';
        state = SyncState.error;
      } else {
        final bytes = await folder.readFile(ref.entry.uri);
        _fileBytes = bytes;
        file = BudgetFile.open(bytes, yearHint: ref.year);
        year = ref.year;
        await settings.setLastSync(_clock());
        state = SyncState.idle;
      }
    } on FolderAccessException catch (e) {
      lastError = e.message;
      state = file == null ? SyncState.error : SyncState.offline;
    } on XlsxException catch (e) {
      lastError = e.message;
      state = SyncState.error;
    } catch (e) {
      lastError = e.toString();
      state = file == null ? SyncState.error : SyncState.offline;
    }
    notifyListeners();
  }

  /// The file of any year in the folder, for looking at past months without
  /// switching the home screen. The loaded year comes from memory.
  Future<BudgetFile?> fileForYear(int y) async {
    if (y == year && file != null) return file;
    final cached = _otherYears[y];
    if (cached != null) return cached;
    final ref = _refForYear(y);
    if (ref == null) return null;
    final bytes = await folder.readFile(ref.entry.uri);
    return _otherYears[y] = BudgetFile.open(bytes, yearHint: ref.year);
  }

  /// File entries plus queued ones for [y], oldest first.
  List<BudgetEntry> entriesForYear(int y, BudgetFile f) {
    final out = <BudgetEntry>[...f.entries, ...pending.where((e) => e.date.year == y)];
    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return (a.row ?? 1 << 30).compareTo(b.row ?? 1 << 30);
    });
    return out;
  }

  /// Traffic light against the limits of [f] (another year's file).
  static LimitLevel limitLevelOf(BudgetFile f, double expenses) {
    final l2 = f.setting('Monatslimit 2');
    final l1 = f.setting('Monatslimit 1');
    if (l2 != null && l2 > 0 && expenses >= l2) return LimitLevel.over;
    if (l1 != null && l1 > 0 && expenses >= l1) return LimitLevel.warn;
    return LimitLevel.ok;
  }

  /// Switch the displayed year (the file must exist in the folder); the
  /// calendar year un-pins it.
  Future<void> selectYear(int y) async {
    year = y;
    _yearPinned = y != currentYear;
    await sync();
  }

  YearFileRef? _refForYear(int y) {
    for (final f in yearFiles) {
      if (f.year == y) return f;
    }
    return null;
  }

  /// Raw bytes of the loaded file (for sharing/debugging).
  Uint8List? get fileBytes => _fileBytes;

  // --- queue persistence ------------------------------------------------------------

  Future<File> _queueFile() async {
    final dir = queueDir ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'pending_entries.json'));
  }

  Future<void> _loadQueue() async {
    try {
      final f = await _queueFile();
      if (!f.existsSync()) return;
      final list = jsonDecode(await f.readAsString()) as List<dynamic>;
      pending = [for (final m in list) BudgetEntry.fromJson(m as Map<String, dynamic>)];
    } catch (_) {
      pending = [];
    }
  }

  Future<void> _saveQueue() async {
    final f = await _queueFile();
    await f.writeAsString(jsonEncode([for (final e in pending) e.toJson()]), flush: true);
  }

  int _idCounter = 0;
  String _newId() => '${_clock().microsecondsSinceEpoch}-${_idCounter++}';
}
