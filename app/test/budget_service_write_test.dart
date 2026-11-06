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

  test('every write backs the previous version up, at most once per interval, five kept', () async {
    final s = service();
    await s.sync();
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
    for (var i = 1; i <= 6; i++) {
      now = now.add(const Duration(minutes: 11));
      await s.setOverviewInput('Sparkonto', 4, 200 + i.toDouble());
    }
    backups = await folder.listFiles(dir);
    expect(backups.length, BudgetService.backupsKept);
    expect(folder.deleted.length, 2);
    expect(backups.map((b) => b.name), isNot(contains(startsWith('Budget 2026 2026-04-10T12-00-00'))), reason: 'the oldest were dropped');

    await settings.setBackups(false);
    now = now.add(const Duration(minutes: 11));
    await s.setOverviewInput('Sparkonto', 4, 300);
    expect((await folder.listFiles(dir)).length, BudgetService.backupsKept, reason: 'switched off');
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
