/// The budget as the app sees it: the year file in the chosen folder plus a
/// local queue of entries that have not reached the file yet.
///
/// Works like a Drive client: adding an entry is instant and local, the
/// queue is flushed into the xlsx whenever the file is reachable (app start,
/// resume, after each add, manual sync). Reading always re-fetches the file
/// so edits made on the laptop show up. A sync re-reads the file right
/// before writing, so a concurrent edit is only lost in the few hundred
/// milliseconds between that read and the write.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/app_settings.dart';
import '../storage/folder_access.dart';
import 'budget_file.dart';
import 'entry_suggest.dart';
import 'xlsx_workbook.dart';

enum SyncState { noFolder, idle, syncing, offline, error }

final RegExp budgetFileName = RegExp(r'^Budget (20\d\d)\.xlsx$', caseSensitive: false);

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
  BudgetFile? file;
  Uint8List? _fileBytes;

  /// Entries waiting for the file, newest last.
  List<BudgetEntry> pending = [];

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
    yearFiles = const [];
    state = SyncState.noFolder;
    notifyListeners();
  }

  // --- adding ---------------------------------------------------------------------

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

  Future<void> removePending(String pendingId) async {
    pending.removeWhere((e) => e.pendingId == pendingId);
    await _saveQueue();
    notifyListeners();
  }

  /// Change an input cell of `Übersicht` (Kontostand, Sparkonto, Kreditkarte
  /// offen) in the loaded year file. Written through immediately.
  Future<void> setOverviewInput(String labelPrefix, int month, double? value) async {
    await _withFile((f) => f.setOverviewInput(labelPrefix, month, value));
  }

  Future<void> setPlan(String category, int month, double value) async {
    await _withFile((f) => f.setPlan(category, month, value));
  }

  Future<void> setBudgetSetting(String label, double value, {String note = ''}) async {
    await _withFile((f) => f.setSetting(label, value, note: note));
  }

  Future<void> _withFile(void Function(BudgetFile) change) async {
    final ref = _refForYear(year ?? _clock().year);
    if (ref == null) throw StateError('no year file loaded');
    final bytes = await folder.readFile(ref.entry.uri);
    final f = BudgetFile.open(bytes, yearHint: ref.year);
    change(f);
    await folder.writeFile(ref.entry.uri, f.save());
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
        if (ref == null) continue; // stays queued until a file for that year exists
        final bytes = await folder.readFile(ref.entry.uri);
        final f = BudgetFile.open(bytes, yearHint: ref.year);
        f.appendEntries([for (final e in entry.value) e.copyWith(clearPending: true)]);
        await folder.writeFile(ref.entry.uri, f.save());
        final ids = entry.value.map((e) => e.pendingId).toSet();
        pending.removeWhere((e) => ids.contains(e.pendingId));
        await _saveQueue();
      }

      // Load the year to show: the current year, else the newest file.
      final wanted = year ?? _clock().year;
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

  /// Switch the displayed year (the file must exist in the folder).
  Future<void> selectYear(int y) async {
    year = y;
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
