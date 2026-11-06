import 'dart:io';
import 'dart:typed_data';

import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/storage/folder_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory folder with the fixture as "Budget 2026.xlsx"; can be
/// switched offline to simulate a Drive provider without network.
class FakeFolder implements FolderAccess {
  FakeFolder(Uint8List bytes)
      : files = {'f1': bytes},
        names = {'f1': 'Budget 2026.xlsx'};

  /// A fresh folder, as a new user's.
  FakeFolder.empty()
      : files = {},
        names = {};
  final Map<String, Uint8List> files;
  final Map<String, String> names;
  bool offline = false;
  int writes = 0;
  String? createdName;

  void _check() {
    if (offline) throw FolderAccessException('offline');
  }

  @override
  Future<FolderInfo?> pickFolder() async => const FolderInfo(uri: 'tree', name: 'Budget');
  @override
  Future<PickedDocument?> pickDocument(List<String> mimeTypes) async => null;
  @override
  Future<bool> hasFolderPermission(String uri) async => true;
  @override
  Future<List<FileEntry>> listFiles(String folderUri) async {
    _check();
    return [for (final e in files.entries) FileEntry(uri: e.key, name: names[e.key]!, size: e.value.length)];
  }

  @override
  Future<Uint8List> readFile(String uri) async {
    _check();
    return files[uri]!;
  }

  @override
  Future<void> writeFile(String uri, Uint8List bytes) async {
    _check();
    writes++;
    files[uri] = bytes;
  }

  @override
  Future<String> createFile(String folderUri, String name, String mimeType, Uint8List bytes) async {
    _check();
    final uri = 'f${files.length + 1}';
    files[uri] = bytes;
    names[uri] = createdName ?? name;
    return uri;
  }
  @override
  Future<FileEntry?> fileInfo(String uri) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
    tmp = await Directory.systemTemp.createTemp('azbudget');
  });
  tearDown(() => tmp.delete(recursive: true));

  test('sync loads the year file, queue flushes into it, offline keeps the queue', () async {
    final folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    final clock = DateTime(2026, 4, 10);
    final service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => clock);
    await service.init();
    expect(service.state, SyncState.noFolder);

    await settings.setFolder('tree', 'Budget');
    await service.sync();
    expect(service.state, SyncState.idle);
    expect(service.year, 2026);
    expect(service.entries.length, 36);
    expect(service.monthLimit1, 3000);
    expect(service.categories.map((c) => c.name), contains('Kinder'));

    // Offline: the entry stays in the queue and is still visible.
    folder.offline = true;
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Kinder', description: 'Marina', amount: 10));
    await service.sync();
    expect(service.state, SyncState.offline);
    expect(service.pending.length, 1);
    expect(service.entries.last.isPending, isTrue);
    expect(service.entries.length, 37);
    expect(folder.writes, 0);

    // Queue survives a restart.
    final restarted = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => clock);
    await restarted.init();
    expect(restarted.pending.length, 1);

    // Back online: flushed into the file, re-read from it.
    folder.offline = false;
    await restarted.sync();
    expect(restarted.state, SyncState.idle);
    expect(restarted.pending, isEmpty);
    expect(folder.writes, 1);
    expect(restarted.entries.length, 37);
    final last = restarted.entries.last;
    expect(last.isPending, isFalse);
    expect(last.row, 38);
    expect(last.description, 'Marina');
    expect(BudgetFile.open(folder.files['f1']!).entries.length, 37);

    // Quick tiles come from the data.
    final tiles = restarted.suggestions.quickTiles();
    expect(tiles.map((t) => t.description), contains('Marina'));
  });

  test('overview inputs are written through', () async {
    final folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    final service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    await settings.setFolder('tree', 'Budget');
    await service.sync();
    await service.setOverviewInput('Kreditkarte', 4, 2361.08);
    expect(service.file!.overview.byLabelPrefix('Kreditkarte')!.$2[3], 2361.08);
    expect(folder.writes, 1);
  });
}
