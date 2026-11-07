import 'dart:io';
import 'dart:typed_data';

import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late AppSettings settings;
  late FakeFolder folder;
  var now = DateTime(2026, 4, 10, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
    await settings.setFolder('tree', 'Budget');
    tmp = await Directory.systemTemp.createTemp('azbudget');
    folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    now = DateTime(2026, 4, 10, 12);
  });
  tearDown(() => tmp.delete(recursive: true));

  BudgetService service() => BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => now);

  test('a laptop edit between read and write is not lost: the change is redone on the fresh file', () async {
    final s = service();
    await s.sync();
    final before = s.entries.length;
    // While the app flushes its queued booking, the laptop saves a row of its own.
    folder.onAfterRead = (uri) {
      final laptop = BudgetFile.open(folder.files[uri]!);
      laptop.appendEntries([BudgetEntry(date: DateTime(2026, 4, 9), category: 'Wohnen', description: 'Laptop row', amount: 1)]);
      folder.externalWrite(uri, laptop.save());
    };
    await s.addEntry(BudgetEntry(date: DateTime(2026, 4, 10), category: 'Kinder', description: 'Phone row', amount: 2));
    await s.sync();
    expect(s.pending, isEmpty);
    final names = s.entries.map((e) => e.description).toList();
    expect(names, contains('Laptop row'));
    expect(names, contains('Phone row'));
    expect(s.entries.length, before + 2);
    expect(folder.writes, 1, reason: 'the first attempt was discarded before writing');
  });

  test('every write backs the previous version up, at most once per interval, three kept by default', () async {
    final s = service();
    await s.sync();
    expect(settings.backupsKept, 3, reason: 'default');
    final original = Uint8List.fromList(folder.files['f1']!);
    await s.setOverviewInput('Sparkonto', 4, 100);
    final dir = 'tree/${BudgetService.backupFolder}';
    expect(folder.folders, contains(dir));
    var backups = await folder.listFiles(dir);
    expect(backups.length, 1);
    expect(backups.single.name, startsWith('Budget 2026 2026-04-10T12-00-00'));
    expect(folder.files[backups.single.uri], original, reason: 'the copy is the file as it was before the write');

    await s.setOverviewInput('Sparkonto', 4, 200); // 0 s later: within the interval, no new backup
    expect((await folder.listFiles(dir)).length, 1);
    Future<void> writeLater(double v) async {
      now = now.add(const Duration(minutes: 11));
      await s.setOverviewInput('Sparkonto', 4, v);
    }

    for (var i = 1; i <= 4; i++) {
      await writeLater(200 + i.toDouble());
    }
    backups = await folder.listFiles(dir);
    expect(backups.length, 3);
    expect(folder.deleted.length, 2);
    expect(backups.map((b) => b.name), isNot(contains(startsWith('Budget 2026 2026-04-10T12-00-00'))), reason: 'the oldest were dropped');

    // More kept: nothing is deleted until the new limit is reached.
    await settings.setBackupsKept(5);
    for (var i = 0; i < 2; i++) {
      await writeLater(300 + i.toDouble());
    }
    expect((await folder.listFiles(dir)).length, 5);
    expect(folder.deleted.length, 2);
    // Fewer kept: the next backup trims the older ones down to it.
    await settings.setBackupsKept(1);
    await writeLater(400);
    backups = await folder.listFiles(dir);
    expect(backups.length, 1);
    expect(backups.single.name, startsWith('Budget 2026 ${now.toIso8601String().substring(0, 19).replaceAll(':', '-')}'), reason: 'the newest stays');

    await settings.setBackups(false);
    await writeLater(500);
    expect((await folder.listFiles(dir)).length, 1, reason: 'switched off');
  });

  test('backups beyond the setting are deleted right after the first sync and when the setting is lowered', () async {
    // Left over from the old default of five, plus one of another year and a foreign file.
    final dir = await folder.ensureFolder('tree', const [BudgetService.backupFolder]);
    for (var h = 10; h < 15; h++) {
      await folder.createFile(dir, 'Budget 2026 2026-04-09T$h-00-00.xlsx', 'x', Uint8List(1));
    }
    await folder.createFile(dir, 'Budget 2025 2025-12-31T10-00-00.xlsx', 'x', Uint8List(1));
    await folder.createFile(dir, 'notes.txt', 'text/plain', Uint8List(1));
    Future<List<String>> names() async => [for (final f in await folder.listFiles(dir)) f.name]..sort();

    final s = service();
    final writesBefore = folder.writes;
    await s.sync();
    expect(await names(), [
      'Budget 2025 2025-12-31T10-00-00.xlsx',
      'Budget 2026 2026-04-09T12-00-00.xlsx',
      'Budget 2026 2026-04-09T13-00-00.xlsx',
      'Budget 2026 2026-04-09T14-00-00.xlsx',
      'notes.txt',
    ], reason: 'the newest three of 2026 stay; other years and other files are not touched');
    expect(folder.writes, writesBefore, reason: 'cleaning up writes nothing to the budget file');

    await s.sync();
    expect((await names()).length, 5, reason: 'once per session');

    await settings.setBackupsKept(1);
    expect(await s.pruneBackups(), 2);
    expect(await names(), ['Budget 2025 2025-12-31T10-00-00.xlsx', 'Budget 2026 2026-04-09T14-00-00.xlsx', 'notes.txt']);

    await settings.setBackups(false);
    await settings.setBackupsKept(1);
    expect(await s.pruneBackups(), 0, reason: 'switched off: the copies that are there stay');
  });

  test('year summary is computed off the UI thread, cached per year until the next sync', () async {
    final s = service();
    await s.sync();
    final summary = await s.yearSummary(2026);
    expect(summary, isNotNull);
    expect(summary!.expenses, closeTo(s.monthExpenses(1) + s.monthExpenses(2) + s.monthExpenses(3), 0.001));
    expect(summary.income, greaterThan(0));
    expect(summary.byCategory['Lebensmittel'], greaterThan(0));
    expect(identical(await s.yearSummary(2026), summary), isTrue, reason: 'cached');
    expect(await s.yearSummary(2024), isNull, reason: 'no file');
    await s.sync();
    expect(identical(await s.yearSummary(2026), summary), isFalse, reason: 'recomputed after a sync');
  });

  test('receipt photos go to Belege/<year>/ with a unique name', () async {
    final s = service();
    await s.sync();
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
    final a = await s.storeReceiptPhoto(jpeg, DateTime(2026, 11, 6), 'BILLA');
    final b = await s.storeReceiptPhoto(jpeg, DateTime(2026, 11, 6), 'BILLA');
    final c = await s.storeReceiptPhoto(jpeg, DateTime(2026, 11, 6), 'Café & Bar / Wien');
    expect(a, 'Belege/2026/2026-11-06_BILLA.jpg');
    expect(b, 'Belege/2026/2026-11-06_BILLA_2.jpg');
    expect(c, 'Belege/2026/2026-11-06_Café_Bar_Wien.jpg');
    expect(folder.folders, contains('tree/Belege/2026'));
    expect((await folder.listFiles('tree/Belege/2026')).length, 3);
    await settings.setSavePhotos(false);
    expect(await s.storeReceiptPhoto(jpeg, DateTime(2026, 11, 6), 'X'), isNull);
  });
}
