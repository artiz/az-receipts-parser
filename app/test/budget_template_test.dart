import 'dart:io';
import 'dart:typed_data';

import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/budget/receipt_to_entry.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

/// The bundled templates (built by tools/budget_template.py) as the app
/// reads them: every language must look the same to the code.
Uint8List template(String lang) => File('assets/templates/budget_$lang.xlsx').readAsBytesSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expected = {
    'de': ('Buchungen', 'Lebensmittel', 'Einnahmen', 'Kreditkarte', 'Monatslimit 1', 'Kontostand'),
    'en': ('Entries', 'Groceries', 'Income', 'Credit card', 'Month limit 1', 'Balance'),
    'ru': ('Записи', 'Продукты', 'Доходы', 'Кредитка', 'Месячный лимит 1', 'Остаток'),
  };

  for (final lang in BudgetLabels.languages) {
    final (sheet, groceries, income, card, limitLabel, balance) = expected[lang]!;
    group('template $lang', () {
      test('reads like the German file', () {
        final f = BudgetFile.open(template(lang));
        expect(f.language, lang);
        expect(f.year, 2026);
        expect(f.workbook.sheet(sheet), isNotNull);
        expect(f.categories.length, 18);
        expect(f.expenseCategories.length, 16);
        expect(f.category(groceries)!.type, CategoryType.expense);
        expect(f.category(income)!.type, CategoryType.income);
        expect(f.category(card)!.type, CategoryType.transfer);
        expect(f.categories.where((c) => c.hint.isNotEmpty).length, greaterThan(10));
        expect(f.settings.map((s) => s.label), contains(limitLabel));
        expect(f.setting('Monatslimit 1'), 3000);
        expect(f.setting('Monatslimit 2'), 4000);
        expect(f.entries, isEmpty);
        expect(f.overview.rows.length, 3);
        expect(f.overview.byLabelPrefix('Kontostand')!.$1, 5);
        expect(f.overview.rows.keys.first, startsWith(balance));
        expect(f.overview.plan.length, 16);
        expect(f.overview.plan.keys.first, f.expenseCategories.first.name);
        expect(mapRuleCategory('groceries', f.categories), groceries);
      });

      test('a new year: entries, limits, inputs and plan are written in place', () {
        final f = BudgetFile.open(template(lang));
        f.setTitleYear(2027);
        f.appendEntries([BudgetEntry(date: DateTime(2027, 3, 4), category: groceries, description: 'Spar', amount: 12.5)]);
        f.setSetting('Monatslimit 1', 3500);
        f.setOverviewInput('Sparkonto', 3, 1000);
        f.setPlan(groceries, 3, 400);
        final g = BudgetFile.open(f.save());
        expect(g.year, 2027);
        expect(g.entries.single.category, groceries);
        expect(g.entries.single.row, 2);
        expect(g.setting('Monatslimit 1'), 3500);
        expect(g.settings.length, 5, reason: 'the existing row is updated, not a German one appended');
        expect(g.overview.byLabelPrefix('Sparkonto')!.$2[2], 1000);
        expect(g.overview.plan[groceries]!.$2[2], 400);
        final history = g.workbook.sheet(BudgetLabels.historySheet[lang]!)!;
        expect(history.readRow(5)['A']?.text, '2027-01');
        expect(history.readRow(16)['A']?.text, '2027-12');
        // A setting the template does not have gets the file's own language.
        g.setSetting('Ausgabenlimit 4', 2000);
        final h = BudgetFile.open(g.save());
        expect(h.settings.length, 6);
        expect(h.setting('Ausgabenlimit 4'), 2000);
        expect(h.settings.last.label, BudgetLabels.settingInLanguage('Ausgabenlimit 4', lang));
      });
    });
  }

  test('labels: spellings and translations', () {
    expect(BudgetLabels.spellings('Monatslimit 2', BudgetLabels.settings), ['monatslimit 2', 'month limit 2', 'месячный лимит 2']);
    expect(BudgetLabels.spellings('Kreditkarte', BudgetLabels.inputRows), ['kreditkarte', 'credit card', 'кредитка']);
    expect(BudgetLabels.spellings('Something', BudgetLabels.settings), ['something']);
    expect(BudgetLabels.settingInLanguage('Ausgabenlimit 1', 'en'), 'Expense limit 1');
    expect(BudgetLabels.settingInLanguage('Ausgabenlimit 1', 'ru'), 'Лимит записи 1');
    expect(BudgetLabels.settingInLanguage('Ausgabenlimit 1', 'de'), 'Ausgabenlimit 1');
    expect(categoryTypeFrom('Доход'), CategoryType.income);
    expect(categoryTypeFrom('Transfer'), CategoryType.transfer);
    expect(categoryTypeFrom('Расход'), CategoryType.expense);
    expect(templateLanguage('', 'ru'), 'ru');
    expect(templateLanguage('de', 'ru'), 'de');
    expect(templateLanguage('', 'fr'), 'en');
  });

  group('service with an empty folder', () {
    late Directory tmp;
    late AppSettings settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = await AppSettings.load();
      tmp = await Directory.systemTemp.createTemp('azbudget');
    });
    tearDown(() => tmp.delete(recursive: true));

    test('creates the year file from the template in the app language', () async {
      final folder = FakeFolder.empty();
      await settings.setLocaleCode('ru');
      await settings.setFolder('tree', 'Budget');
      final loaded = <String>[];
      final service = BudgetService(
        folder: folder,
        settings: settings,
        queueDir: tmp,
        clock: () => DateTime(2026, 4, 10),
        templateLoader: (lang) async {
          loaded.add(lang);
          return template(lang);
        },
      );
      await service.sync();
      expect(loaded, ['ru']);
      expect(service.state, SyncState.idle);
      expect(folder.names.values, ['Budget 2026.xlsx']);
      expect(service.year, 2026);
      expect(service.file!.language, 'ru');
      expect(service.freshFileYear, 2026);
      expect(service.monthLimit1, 3000);
      expect(service.currentYearMissing, isFalse);

      // Bookings go into the new file right away, in the file's categories.
      await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Продукты', description: 'Spar', amount: 10));
      await service.sync();
      expect(service.pending, isEmpty);
      expect(service.entries.single.row, 2);
      expect(loaded.length, 1, reason: 'the template is used once per folder');
    });

    test('system language when none is chosen, English for unknown ones', () async {
      await settings.setFolder('tree', 'Budget');
      for (final (system, want) in [('de', 'de'), ('fr', 'en')]) {
        final folder = FakeFolder.empty();
        final loaded = <String>[];
        final service = BudgetService(
          folder: folder,
          settings: settings,
          queueDir: tmp,
          clock: () => DateTime(2026, 4, 10),
          systemLanguage: () => system,
          templateLoader: (lang) async {
            loaded.add(lang);
            return template(lang);
          },
        );
        await service.sync();
        expect(loaded, [want]);
        expect(service.file!.language, want);
      }
    });

    test('a failing template is tried once, no file without a loader', () async {
      await settings.setFolder('tree', 'Budget');
      final folder = FakeFolder.empty();
      var calls = 0;
      final service = BudgetService(
        folder: folder,
        settings: settings,
        queueDir: tmp,
        clock: () => DateTime(2026, 4, 10),
        templateLoader: (lang) async {
          calls++;
          throw StateError('asset missing');
        },
      );
      await service.sync();
      await service.sync();
      expect(calls, 1);
      expect(service.state, SyncState.error);
      expect(folder.files, isEmpty);
      expect(service.currentYearMissing, isTrue, reason: 'the button to try again by hand stays');

      final plain = BudgetService(folder: FakeFolder.empty(), settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
      await plain.sync();
      expect(plain.state, SyncState.error);
      expect(plain.currentYearMissing, isFalse);
    });

    test('createYearFile with a chosen language, clone once a file exists', () async {
      await settings.setFolder('tree', 'Budget');
      final folder = FakeFolder.empty();
      final service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2027, 1, 2), templateLoader: (lang) async => template(lang));
      service.dismissFreshFile();
      await service.createYearFile(2026, language: 'en');
      expect(folder.names.values, ['Budget 2026.xlsx']);
      expect(service.year, 2026);
      expect(service.file!.language, 'en');
      expect(service.currentYearMissing, isTrue);
      await service.createYearFile(2027);
      expect(folder.names.values, containsAll(['Budget 2026.xlsx', 'Budget 2027.xlsx']));
      expect(service.year, 2027);
      expect(service.file!.language, 'en', reason: 'cloned from the English file, not the template');
      expect(service.file!.workbook.sheet('Overview')!.readRow(1)['A']?.text, 'Budget 2027');
    });
  });
}
