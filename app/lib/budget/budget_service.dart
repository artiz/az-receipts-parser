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
import 'dart:isolate';

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

/// Totals of a year's expense bookings, by category and overall.
class YearSummary {
  const YearSummary({required this.expenses, required this.income, required this.byCategory});
  final double expenses;
  final double income;
  final Map<String, double> byCategory;

  static YearSummary of(BudgetFile f) {
    var expenses = 0.0;
    var income = 0.0;
    final by = <String, double>{};
    for (final e in f.entries) {
      final cat = f.category(e.category);
      if (cat == null) continue;
      if (cat.isIncome) {
        income += -e.amount;
      } else if (cat.isExpense) {
        expenses += e.amount;
        by[e.category] = (by[e.category] ?? 0) + e.amount;
      }
    }
    return YearSummary(expenses: expenses, income: income, byCategory: by);
  }
}

class YearFileRef {
  const YearFileRef({required this.year, required this.entry});
  final int year;
  final FileEntry entry;
}

/// Loads the bundled empty workbook for a template language.
typedef TemplateLoader = Future<Uint8List> Function(String language);

class BudgetService extends ChangeNotifier {
  BudgetService({
    required this.folder,
    required this.settings,
    this.queueDir,
    DateTime Function()? clock,
    this.templateLoader,
    String Function()? systemLanguage,
  })  : _clock = clock ?? DateTime.now,
        _systemLanguage = systemLanguage ?? (() => PlatformDispatcher.instance.locale.languageCode);

  final FolderAccess folder;
  final AppSettings settings;

  /// Bundled templates (`assets/templates/budget_<lang>.xlsx`); without one
  /// a new year can only be cloned from an existing file.
  final TemplateLoader? templateLoader;
  final String Function() _systemLanguage;

  /// Year of a file the app just created from a template, until the user
  /// dismisses the hint about it.
  int? freshFileYear;

  /// Folder for which creating the first file from a template was tried, so
  /// a failing folder is not hammered on every sync.
  String? _templateTriedFolder;

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

  /// Year totals computed off the UI thread, dropped on every sync.
  final Map<int, Future<YearSummary?>> _yearSummaries = {};

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

  /// Categories in alphabetical order, for lists and pickers.
  List<BudgetCategory> get categoriesByName => file?.categoriesByName ?? const [];

  EntrySuggestions get suggestions => EntrySuggestions(entries, now: _clock());

  double? get monthLimit1 => file?.setting('Monatslimit 1');
  double? get monthLimit2 => file?.setting('Monatslimit 2');

  /// Expense limits for single entries (Ausgabenlimit 1..3), ascending.
  List<double> get entryLimits {
    final f = file;
    if (f == null) return const [];
    final out = <double>[];
    for (final s in f.settings) {
      if (BudgetLabels.settingMatches(s.label, 'ausgabenlimit') && s.value != null) out.add(s.value!);
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
  /// from the latest file or a template).
  bool get currentYearMissing => settings.hasFolder && state != SyncState.syncing && _refForYear(_clock().year) == null && (yearFiles.isNotEmpty || templateLoader != null);

  /// Language a new template file gets: the app language, else the system's.
  String get templateLanguageCode => templateLanguage(settings.localeCode, _systemLanguage());

  void dismissFreshFile() {
    freshFileYear = null;
    notifyListeners();
  }

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

  /// Delete an entry: a queued one leaves the queue, a file row is removed
  /// and the rows below move up.
  Future<void> deleteEntry(BudgetEntry e) async {
    if (e.isPending) return removePending(e.pendingId!);
    final row = e.row;
    if (row == null) return;
    await _withFile(e.date.year, (f) => f.deleteEntryRow(row));
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
      await _withFile(old.date.year, (f) => f.deleteEntryRow(row));
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
    final note = entry.note.isEmpty ? piece : '${entry.note}\n$piece';
    await updateEntry(entry, entry.copyWith(amount: newAmount, note: note));
  }

  /// Append text to an existing entry's note (receipt scanned after the
  /// purchase was typed by hand).
  Future<void> appendNote(BudgetEntry entry, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final note = entry.note.isEmpty ? t : (entry.note.contains(t) ? entry.note : '${entry.note}\n$t');
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

  /// Change a category (name, hint, icon, colour) in the loaded year's file;
  /// queued entries follow a rename.
  Future<void> updateCategory(BudgetCategory old, BudgetCategory updated, {int? year}) async {
    final y = year ?? this.year ?? currentYear;
    // Queued entries are renamed first: the sync after the write flushes them
    // into the file, where the category already has its new name.
    final renamed = updated.name != old.name && await _renamePending({old.name: updated.name}, y);
    try {
      await _withFile(y, (f) {
        final current = f.category(old.name) ?? (throw StateError('category "${old.name}" not found'));
        f.updateCategory(current, updated);
      });
    } catch (_) {
      if (renamed) await _renamePending({updated.name: old.name}, y);
      rethrow;
    }
  }

  /// Add a category to the loaded year's file (see [BudgetFile.addCategory]).
  Future<void> addCategory(BudgetCategory c, {int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) => f.addCategory(c));
  }

  /// Translate the loaded year's file into [language] (see
  /// [BudgetFile.translateTo]); returns the number of changed cells.
  Future<int> translateFile(String language, {int? year}) async {
    final y = year ?? this.year ?? currentYear;
    final ref = _refForYear(y) ?? (throw StateError('no file for $y'));
    // Dry run on the file as it is, to learn which categories get renamed.
    final probe = BudgetFile.open(await folder.readFile(ref.entry.uri), yearHint: y);
    final before = {for (final c in probe.categories) c.row!: c.name};
    probe.translateTo(language);
    final renames = <String, String>{};
    for (final c in BudgetFile.open(probe.save()).categories) {
      final old = before[c.row!];
      if (old != null && old != c.name) renames[old] = c.name;
    }
    final renamed = await _renamePending(renames, y);
    var changed = 0;
    try {
      await _withFile(y, (f) => changed = f.translateTo(language));
    } catch (_) {
      if (renamed) await _renamePending({for (final e in renames.entries) e.value: e.key}, y);
      rethrow;
    }
    return changed;
  }

  /// Rename categories of the queued entries of year [y]; true when any changed.
  Future<bool> _renamePending(Map<String, String> renames, int y) async {
    if (renames.isEmpty) return false;
    var any = false;
    pending = [
      for (final e in pending)
        if (e.date.year == y && renames.containsKey(e.category)) () {
          any = true;
          return e.copyWith(category: renames[e.category]);
        }() else e,
    ];
    if (!any) return false;
    await _saveQueue();
    notifyListeners();
    return true;
  }

  /// The loaded file is in another language than the app.
  bool get fileLanguageMismatch => file != null && file!.language != templateLanguageCode;

  Future<void> _withFile(int y, void Function(BudgetFile) change) async {
    final ref = _refForYear(y);
    if (ref == null) throw StateError('no file for $y');
    await _modify(ref, change);
    await sync();
  }

  /// Backups taken per year in this session, to take at most one per
  /// [backupInterval] (a burst of edits is one backup).
  final Map<int, DateTime> _lastBackup = {};
  static const Duration backupInterval = Duration(minutes: 10);
  static const String backupFolder = '.backup';

  /// Read, change and write back a year file, the way a second editor is not
  /// overwritten: the file's modification time is read before and compared
  /// right before the write; a change in between (the laptop saved) throws
  /// the work away and applies [change] to the fresh file again. A copy of
  /// the file as it was goes to `.backup/` first (see [backupInterval]).
  Future<void> _modify(YearFileRef ref, void Function(BudgetFile) change) async {
    final uri = ref.entry.uri;
    for (var attempt = 0; attempt < 4; attempt++) {
      final before = (await folder.fileInfo(uri))?.lastModified;
      final bytes = await folder.readFile(uri);
      final f = BudgetFile.open(bytes, yearHint: ref.year);
      change(f);
      final saved = f.save();
      final again = (await folder.fileInfo(uri))?.lastModified;
      if (before != null && again != null && again != before) {
        lastError = 'file changed while editing, retrying';
        continue; // someone else wrote meanwhile: redo on their version
      }
      await _backup(ref, bytes);
      await folder.writeFile(uri, saved);
      return;
    }
    throw FolderAccessException('Budget ${ref.year}.xlsx keeps changing while writing; try again');
  }

  Future<void> _backup(YearFileRef ref, Uint8List bytes) async {
    if (!settings.backups) return;
    final root = settings.folderUri;
    if (root == null) return;
    final now = _clock();
    final last = _lastBackup[ref.year];
    if (last != null && now.difference(last) < backupInterval) return;
    try {
      final dir = await folder.ensureFolder(root, const [backupFolder]);
      final stamp = now.toIso8601String().substring(0, 19).replaceAll(':', '-');
      await folder.createFile(dir, 'Budget ${ref.year} $stamp.xlsx', xlsxMime, bytes);
      _lastBackup[ref.year] = now;
      await _prune(dir);
    } catch (_) {
      // A backup must never block the booking; the provider may not support folders.
    }
  }

  /// Delete the backups beyond [AppSettings.backupsKept] per year, oldest
  /// first (the names sort by time). Runs after each backup, after the
  /// first sync of a session and when the setting changes, so lowering it
  /// cleans up right away. Returns the number of deleted files.
  Future<int> pruneBackups() async {
    if (!settings.backups) return 0;
    final root = settings.folderUri;
    if (root == null) return 0;
    try {
      return await _prune(await folder.ensureFolder(root, const [backupFolder]));
    } catch (_) {
      return 0; // never in the way of the app; the provider may not support folders
    }
  }

  static final _backupName = RegExp(r'^Budget (\d{4}) .+\.xlsx$');

  Future<int> _prune(String dir) async {
    final byYear = <String, List<FileEntry>>{};
    for (final f in await folder.listFiles(dir)) {
      final m = _backupName.firstMatch(f.name);
      if (m != null) byYear.putIfAbsent(m.group(1)!, () => []).add(f);
    }
    var n = 0;
    for (final files in byYear.values) {
      files.sort((a, b) => b.name.compareTo(a.name));
      for (final f in files.skip(settings.backupsKept)) {
        await folder.deleteFile(f.uri);
        n++;
      }
    }
    return n;
  }

  bool _prunedThisSession = false;

  /// Store a receipt (photo or PDF) as `Belege/<year>/<date>_<merchant>.<ext>`
  /// next to the budget files; returns that relative path for the note.
  /// Null when receipt files are switched off or there is no folder.
  Future<String?> storeReceiptPhoto(Uint8List bytes, DateTime date, String merchant, {String extension = 'jpg'}) async {
    if (!settings.savePhotos) return null;
    final root = settings.folderUri;
    if (root == null) return null;
    final dir = await folder.ensureFolder(root, ['Belege', '${date.year}']);
    final d = date.toIso8601String().substring(0, 10);
    final m = merchant.trim().replaceAll(RegExp(r'[^\p{L}\p{N}.-]+', unicode: true), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    var name = '${d}_${m.isEmpty ? 'Beleg' : m}';
    final taken = {for (final f in await folder.listFiles(dir)) f.name};
    var candidate = '$name.$extension';
    for (var i = 2; taken.contains(candidate); i++) {
      candidate = '${name}_$i.$extension';
    }
    name = candidate;
    await folder.createFile(dir, name, extension == 'pdf' ? 'application/pdf' : 'image/jpeg', bytes);
    return 'Belege/${date.year}/$name';
  }

  /// Add a rule to the loaded year's `Regeln` sheet (created when missing).
  /// The loaded file is older than the layout the app writes.
  bool get fileOutdated => file != null && file!.version < BudgetFile.currentVersion;

  /// Bring the year file up to the current layout (see [BudgetFile.migrate]).
  Future<void> migrateFile({int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) => f.migrate());
  }

  Future<void> addRule(BudgetRule rule, {int? year}) async {
    await _withFile(year ?? this.year ?? currentYear, (f) => f.addRule(rule));
  }

  /// Write the loaded year's bookings as `Budget <year>.csv` into the
  /// folder (replaced when it exists); returns the file name.
  Future<String> exportCsv({int? year}) async {
    final y = year ?? this.year ?? currentYear;
    final f = await fileForYear(y) ?? (throw StateError('no file for $y'));
    final root = settings.folderUri ?? (throw StateError('no folder'));
    final name = 'Budget $y.csv';
    final bytes = Uint8List.fromList(utf8.encode(f.toCsv()));
    final existing = (await folder.listFiles(root)).where((e) => e.name == name).firstOrNull;
    if (existing != null) {
      await folder.writeFile(existing.uri, bytes);
    } else {
      await folder.createFile(root, name, 'text/csv', bytes);
    }
    return name;
  }


  /// Create `Budget <newYear>.xlsx` from the latest existing file: same
  /// categories, settings and plan, no bookings, empty account inputs. With
  /// no file in the folder, from the bundled template in [language] (the
  /// app language by default).
  Future<void> createYearFile(int newYear, {String? language}) async {
    final uri = settings.folderUri;
    if (uri == null) throw StateError('no folder');
    if (_refForYear(newYear) != null) return;
    if (yearFiles.isEmpty) {
      await _createFromTemplate(uri, newYear, language ?? templateLanguageCode);
    } else {
      final source = yearFiles.first;
      final bytes = await folder.readFile(source.entry.uri);
      final f = BudgetFile.open(bytes, yearHint: source.year);
      f.clearEntries();
      f.clearOverviewInputs();
      f.setTitleYear(newYear);
      await folder.createFile(uri, 'Budget $newYear.xlsx', xlsxMime, f.save());
    }
    _yearPinned = false;
    await sync();
  }

  Future<void> _createFromTemplate(String folderUri, int newYear, String language) async {
    final load = templateLoader ?? (throw StateError('no file to copy from and no template'));
    final f = BudgetFile.open(await load(language));
    f.setTitleYear(newYear);
    await folder.createFile(folderUri, 'Budget $newYear.xlsx', xlsxMime, f.save());
    freshFileYear = newYear;
  }

  Future<List<YearFileRef>> _listYearFiles(String uri) async {
    final files = await folder.listFiles(uri);
    return [
      for (final f in files)
        if (budgetFileName.hasMatch(f.name)) YearFileRef(year: int.parse(budgetFileName.firstMatch(f.name)!.group(1)!), entry: f),
    ]..sort((a, b) => b.year.compareTo(a.year));
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
    // Once per session, after the folder answered: trim backups left over
    // from a larger setting (or the old default of five).
    if (!_prunedThisSession && state != SyncState.noFolder && file != null) {
      _prunedThisSession = true;
      await pruneBackups();
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
    _yearSummaries.clear();
    notifyListeners();
    try {
      yearFiles = await _listYearFiles(uri);

      // A new user: the folder has no budget file yet, so the current year
      // starts from the template in the app language (once per folder).
      if (yearFiles.isEmpty && templateLoader != null && _templateTriedFolder != uri) {
        _templateTriedFolder = uri;
        await _createFromTemplate(uri, currentYear, templateLanguageCode);
        yearFiles = await _listYearFiles(uri);
      }

      // Flush the queue, grouped by the year each entry belongs to.
      final byYear = <int, List<BudgetEntry>>{};
      for (final e in pending) {
        byYear.putIfAbsent(e.date.year, () => []).add(e);
      }
      for (final entry in byYear.entries) {
        final ref = _refForYear(entry.key);
        if (ref == null) continue; // stays queued (see strandedPending) until a file for that year exists
        await _modify(ref, (f) => f.appendEntries([for (final e in entry.value) e.copyWith(clearPending: true)]));
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

  /// Expense totals of year [y] (file rows only), parsed in an isolate so
  /// a large past year does not stall the UI; null without a file.
  Future<YearSummary?> yearSummary(int y) {
    return _yearSummaries[y] ??= () async {
      final ref = _refForYear(y);
      if (ref == null) return null;
      final bytes = await folder.readFile(ref.entry.uri);
      return _summarizeInIsolate(bytes, y);
    }();
  }

  // A static method: the closure sent to the isolate must not capture `this`.
  static Future<YearSummary> _summarizeInIsolate(Uint8List bytes, int y) => Isolate.run(() => YearSummary.of(BudgetFile.open(bytes, yearHint: y)));

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
