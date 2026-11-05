import 'dart:io';

import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late AppSettings settings;
  late FakeFolder folder;
  late BudgetService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
    tmp = await Directory.systemTemp.createTemp('azbudget');
    folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    await settings.setFolder('tree', 'Budget');
    await service.sync();
  });
  tearDown(() => tmp.delete(recursive: true));

  test('file rows are edited in place', () async {
    final e = service.entries.first;
    expect(e.row, 2);
    await service.updateEntry(e, e.copyWith(amount: 99.5, note: 'edited'));
    final again = service.entries.firstWhere((x) => x.row == 2);
    expect(again.amount, 99.5);
    expect(again.note, 'edited');
    expect(service.entries.length, 36);
    expect(folder.writes, 1);
  });

  test('+ adds to the amount and the note', () async {
    final e = service.entries.firstWhere((x) => x.description == 'Marina');
    await service.addToEntry(e, 6, 'Glühwein');
    final again = service.entries.firstWhere((x) => x.row == e.row);
    expect(again.amount, e.amount + 6);
    expect(again.note, '+6 Glühwein');
    await service.addToEntry(again, 2.5, '');
    final third = service.entries.firstWhere((x) => x.row == e.row);
    expect(third.amount, e.amount + 8.5);
    expect(third.note, '+6 Glühwein; +2,50');
  });

  test('similar entries are found and the note merged', () async {
    final typed = BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Elka', amount: 90);
    await service.addEntry(typed);
    await service.sync();
    final scanned = BudgetEntry(date: DateTime(2026, 4, 10), category: 'Haushalt', description: 'OBI', amount: 90, note: 'Tanne 90,00');
    final similar = service.findSimilar(scanned);
    expect(similar, isNotNull);
    expect(similar!.description, 'Elka');
    expect(service.findSimilar(scanned.copyWith(amount: 91)), isNull);
    expect(service.findSimilar(scanned.copyWith(category: 'Kinder')), isNull);
    await service.appendNote(similar, 'Tanne 90,00; OBI');
    expect(service.entries.firstWhere((x) => x.description == 'Elka').note, 'Tanne 90,00; OBI');
  });

  test('queued entries of a year without a file are reported, not lost', () async {
    await service.addEntry(BudgetEntry(date: DateTime(2024, 4, 9), category: 'Kinder', description: 'Marina', amount: 5));
    await service.sync();
    expect(service.state, SyncState.idle);
    expect(service.pending.length, 1);
    expect(service.strandedPending.length, 1);
    expect(service.entries.length, 36);
    final stuck = service.strandedPending.first;
    await service.updateEntry(stuck, stuck.copyWith(date: DateTime(2026, 4, 9)));
    await service.sync();
    expect(service.strandedPending, isEmpty);
    expect(service.pending, isEmpty);
    expect(service.entries.length, 37);
  });

  test('another year is readable for the overview without switching', () async {
    final s2 = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2027, 1, 2));
    await s2.sync();
    folder.createdName = 'Budget 2027.xlsx';
    await s2.createYearFile(2027);
    expect(s2.year, 2027);
    final old = await s2.fileForYear(2026);
    expect(old, isNotNull);
    expect(s2.entriesForYear(2026, old!).length, 36);
    expect(s2.year, 2027);
    expect(await s2.fileForYear(2020), isNull);
    expect(BudgetService.limitLevelOf(old, 3500), LimitLevel.warn);
    // Edits can target the other year.
    await s2.setPlan('Wohnen', 2, 777, year: 2026);
    expect((await s2.fileForYear(2026))!.overview.plan['Wohnen']!.$2[1], 777);
    expect(s2.year, 2027);
  });

  test('a new year file is created from the latest one', () async {
    final s2 = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2027, 1, 2));
    await s2.sync();
    expect(s2.year, 2026);
    expect(s2.currentYearMissing, isTrue);
    folder.createdName = 'Budget 2027.xlsx';
    await s2.createYearFile(2027);
    expect(s2.year, 2027);
    expect(s2.entries, isEmpty);
    expect(s2.categories.length, 18);
    expect(s2.monthLimit1, 3000);
    final f = s2.file!;
    expect(f.overview.byLabelPrefix('Kontostand')!.$2.every((v) => v == null), isTrue);
    expect(f.overview.plan['Wohnen']!.$2[0], 1300);
    expect(f.workbook.sheet('Übersicht')!.readRow(1)['A']!.text, 'Budget 2027');
    // Bookings now land in the new file.
    await s2.addEntry(BudgetEntry(date: DateTime(2027, 1, 2), category: 'Kinder', description: 'Marina', amount: 5));
    await s2.sync();
    expect(s2.entries.length, 1);
    expect(s2.entries.first.row, 2);
  });
}
