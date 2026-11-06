import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/budget/receipt_to_entry.dart';
import 'package:az_budget/budget/xlsx_workbook.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

/// The bundled templates (built by tools/budget_template.py) as the app
/// reads them: every language must look the same to the code.
Uint8List template(String lang) => File('assets/templates/budget_$lang.xlsx').readAsBytesSync();

/// The XML of the first worksheet (the entries sheet) inside a saved workbook.
String entriesXml(Uint8List bytes) => String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/worksheets/sheet1.xml')!.content as List<int>);

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

  _categoryTests();
  _typeTests();

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

    test('a renamed category and a translation rename queued entries too', () async {
      await settings.setFolder('tree', 'Budget');
      await settings.setLocaleCode('de');
      final folder = FakeFolder.empty();
      final service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10), templateLoader: (lang) async => template(lang));
      await service.sync();
      expect(service.fileLanguageMismatch, isFalse);
      folder.offline = true;
      await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Lebensmittel', description: 'Spar', amount: 10));
      folder.offline = false;
      // The queue is flushed by the sync inside updateCategory before the rename
      // is read back; a renamed file row and a renamed queued entry both end as 'Essen'.
      final cat = service.file!.category('Lebensmittel')!;
      await service.updateCategory(cat, cat.copyWith(name: 'Essen', icon: 'basket'), year: 2026);
      expect(service.entries.single.category, 'Essen');
      expect(service.file!.category('Essen')!.icon, 'basket');

      await settings.setLocaleCode('en');
      expect(service.fileLanguageMismatch, isTrue);
      final n = await service.translateFile('en', year: 2026);
      expect(n, greaterThan(60));
      expect(service.file!.language, 'en');
      expect(service.fileLanguageMismatch, isFalse);
      expect(service.file!.category('Essen'), isNotNull, reason: 'a renamed category is not a template text and stays');
      expect(service.file!.category('Income'), isNotNull);
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

void _categoryTests() {
  group('categories: edit, rename, translate', () {
    test('icon and colour are stored in column E, hint in D, header written when missing', () {
      final f = BudgetFile.open(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
      final cat = f.category('Lebensmittel')!;
      expect(cat.icon, '');
      expect(cat.row, 6);
      f.updateCategory(cat, cat.copyWith(icon: 'basket', color: '#FF2E7E', hint: 'Spar, Billa'));
      final g = BudgetFile.open(f.save());
      final c = g.category('Lebensmittel')!;
      expect(c.icon, 'basket');
      expect(c.color, '#FF2E7E');
      expect(c.hint, 'Spar, Billa');
      expect(c.legacyGroups, 'food', reason: 'column C is left alone');
      expect(g.workbook.sheet('Einstellungen')!.readRow(6)['E']?.text, 'basket #FF2E7E');
      expect(g.workbook.sheet('Einstellungen')!.readRow(4)['E']?.text, 'Symbol & Farbe');
      expect(BudgetCategory.parseStyle('#ff2e7e, home'), ('home', '#FF2E7E'));
      expect(BudgetCategory.parseStyle(null), ('', ''));
    });

    test('renaming follows into bookings, overview labels, formulas and conditional formats', () {
      final f = BudgetFile.open(template('de'));
      f.appendEntries([
        BudgetEntry(date: DateTime(2026, 3, 4), category: 'Lebensmittel', description: 'Spar', amount: 12.5),
        BudgetEntry(date: DateTime(2026, 3, 5), category: 'Einnahmen', description: 'Gehalt', amount: -2000),
        BudgetEntry(date: DateTime(2026, 3, 6), category: 'Kreditkarte', description: 'Abrechnung', amount: 300),
      ]);
      var g = BudgetFile.open(f.save());
      g.updateCategory(g.category('Lebensmittel')!, g.category('Lebensmittel')!.copyWith(name: 'Essen'));
      g = BudgetFile.open(g.save());
      expect(g.category('Lebensmittel'), isNull);
      expect(g.category('Essen')!.type, CategoryType.expense);
      expect(g.entries.first.category, 'Essen');
      expect(g.overview.plan.keys, contains('Essen'));
      expect(g.overview.plan.keys, isNot(contains('Lebensmittel')));
      final overview = g.workbook.sheet('Übersicht')!;
      expect(overview.readRow(16)['A']?.text, 'Essen'); // Ist block, 2nd category
      expect(overview.readRow(16)['D']?.formula, contains(r'$A16'));

      // Income and transfer names are quoted in the Einnahmen/Ausgaben formulas
      // and in the conditional format of the entries sheet.
      g.updateCategory(g.category('Einnahmen')!, g.category('Einnahmen')!.copyWith(name: 'Gehalt'));
      g.updateCategory(g.category('Kreditkarte')!, g.category('Kreditkarte')!.copyWith(name: 'Karte'));
      g = BudgetFile.open(g.save());
      expect(g.category('Gehalt')!.type, CategoryType.income);
      expect(g.entries[1].category, 'Gehalt');
      expect(g.entries[2].category, 'Karte');
      final inc = g.workbook.sheet('Übersicht')!.readRow(8)['D']?.formula ?? '';
      final exp = g.workbook.sheet('Übersicht')!.readRow(9)['D']?.formula ?? '';
      expect(inc, contains('"Gehalt"'));
      expect(inc, isNot(contains('Einnahmen')));
      expect(exp, contains('"<>Gehalt"'));
      expect(exp, contains('"<>Karte"'));
      expect(exp, isNot(contains('Kreditkarte')));
      final xml = entriesXml(g.workbook.save());
      expect(xml, isNot(contains('Kreditkarte')), reason: 'no "Kreditkarte" left in the entries sheet, including the conditional format');
      expect(xml, contains(r'$C2="Karte"'));

      expect(() => g.updateCategory(g.category('Essen')!, g.category('Essen')!.copyWith(name: 'Wohnen')), throwsA(isA<XlsxException>()));
    });

    test('translating a German file into English matches the English template', () {
      final f = BudgetFile.open(template('de'));
      f.appendEntries([BudgetEntry(date: DateTime(2026, 3, 4), category: 'Lebensmittel', description: 'Spar', amount: 12.5)]);
      f.setSetting('Monatslimit 1', 3500);
      var g = BudgetFile.open(f.save());
      final changed = g.translateTo('en');
      expect(changed, greaterThan(60));
      g = BudgetFile.open(g.save());
      final en = BudgetFile.open(template('en'));
      expect(g.language, 'en');
      expect(g.categories.map((c) => c.name), en.categories.map((c) => c.name));
      expect(g.categories.map((c) => c.hint), en.categories.map((c) => c.hint));
      expect(g.categories.map((c) => c.type), en.categories.map((c) => c.type));
      expect(g.entries.single.category, 'Groceries');
      expect(g.settings.map((s) => s.label), en.settings.map((s) => s.label));
      expect(g.setting('Monatslimit 1'), 3500);
      final settings = g.workbook.sheet('Einstellungen')!;
      expect(settings.readRow(5)['B']?.text, 'Expense');
      expect(settings.readRow(22)['B']?.text, 'Income');
      expect(settings.readRow(1)['A']?.text, 'Settings');
      final overview = g.workbook.sheet('Übersicht')!;
      final enOverview = en.workbook.sheet('Overview')!;
      for (final r in [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 31, 33, 50]) {
        expect(overview.readRow(r)['A']?.text, enOverview.readRow(r)['A']?.text, reason: 'overview row $r');
      }
      expect(overview.readRow(4)['B']?.text, 'Jan');
      expect(overview.readRow(9)['D']?.formula, contains('"<>Income"'));
      expect(g.overview.rows.keys.first, startsWith('Balance'));
      expect(g.workbook.sheet('Verlauf')!.readRow(4)['C']?.text, 'Cumulated');
      expect(g.workbook.sheet('Buchungen')!.readRow(1)['A']?.text, 'Datum', reason: 'table header stays (the table definition names it)');
      // Already English: nothing to do. Back to German: the names return.
      expect(BudgetFile.open(g.save()).translateTo('en'), 0);
      g.translateTo('de');
      g = BudgetFile.open(g.save());
      expect(g.language, 'de');
      expect(g.entries.single.category, 'Lebensmittel');
      expect(g.settings.first.label, 'Monatslimit 1');
    });

    test("a user's own labels survive a translation", () {
      final f = BudgetFile.open(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
      final customHint = f.category('Wohnen')!.hint;
      final changed = f.translateTo('ru');
      expect(changed, greaterThan(10));
      final g = BudgetFile.open(f.save());
      expect(g.category('Жильё')!.hint, customHint, reason: 'hint edited by the user is not a template text');
      expect(g.category('Жильё')!.legacyGroups, 'flat');
      expect(g.entries.every((e) => g.category(e.category) != null), isTrue, reason: 'every booking still has its category');
      expect(g.setting('Monatslimit 1'), 3000);
    });
  });
}

void _typeTests() {
  group('categories: type and adding', () {
    test('an expense category turned into income counts as income in the overview', () {
      var f = BudgetFile.open(template('de'));
      f.appendEntries([
        BudgetEntry(date: DateTime(2026, 3, 1), category: 'Einnahmen', description: 'Gehalt', amount: -2000),
        BudgetEntry(date: DateTime(2026, 3, 2), category: 'Spenden', description: 'Rückzahlung', amount: -50),
      ]);
      f = BudgetFile.open(f.save());
      final spenden = f.category('Spenden')!;
      final istRow = 29; // 15th expense category in the Ist block (rows 15..30)
      final overview = f.workbook.sheet('Übersicht')!;
      expect(overview.readRow(istRow)['A']?.text, 'Spenden');
      f.updateCategory(spenden, spenden.copyWith(type: CategoryType.income));
      f = BudgetFile.open(f.save());
      expect(f.category('Spenden')!.type, CategoryType.income);
      expect(f.workbook.sheet('Einstellungen')!.readRow(spenden.row!)['B']?.text, 'Einnahme');
      final inc = f.workbook.sheet('Übersicht')!.readRow(8)['D']?.formula ?? '';
      final exp = f.workbook.sheet('Übersicht')!.readRow(9)['D']?.formula ?? '';
      expect(inc, '-(SUMIFS(\'Buchungen\'!\$E:\$E,\'Buchungen\'!\$B:\$B,D\$3,\'Buchungen\'!\$C:\$C,"Spenden")+SUMIFS(\'Buchungen\'!\$E:\$E,\'Buchungen\'!\$B:\$B,D\$3,\'Buchungen\'!\$C:\$C,"Einnahmen"))');
      expect(exp, 'SUMIFS(\'Buchungen\'!\$E:\$E,\'Buchungen\'!\$B:\$B,D\$3,\'Buchungen\'!\$C:\$C,"<>Kreditkarte",\'Buchungen\'!\$C:\$C,"<>Spenden",\'Buchungen\'!\$C:\$C,"<>Einnahmen")');
      expect(f.workbook.sheet('Übersicht')!.readRow(istRow)['D']?.formula, isNull, reason: 'the actual row of an income category is blanked');
      expect(f.workbook.sheet('Übersicht')!.readRow(istRow)['A']?.text, 'Spenden');
      expect(f.expenseCategories.length, 15);

      // Back to expense: the SUMIFS row is restored from a sibling row.
      final cat = f.category('Spenden')!;
      f.updateCategory(cat, cat.copyWith(type: CategoryType.expense));
      f = BudgetFile.open(f.save());
      expect(f.category('Spenden')!.type, CategoryType.expense);
      expect(f.workbook.sheet('Übersicht')!.readRow(istRow)['D']?.formula, 'SUMIFS(\'Buchungen\'!\$E:\$E,\'Buchungen\'!\$C:\$C,\$A$istRow,\'Buchungen\'!\$B:\$B,D\$3)');
      expect(f.workbook.sheet('Übersicht')!.readRow(8)['D']?.formula, contains('"Einnahmen")'));
      expect(f.workbook.sheet('Übersicht')!.readRow(8)['D']?.formula, isNot(contains('Spenden')));
    });

    test('added income and transfer categories: settings row, totals, dropdown, transfer format', () {
      var f = BudgetFile.open(template('en'));
      f.addCategory(const BudgetCategory(name: 'Salary Kate', type: CategoryType.income, icon: 'income', color: '#3BA55D', hint: 'Her salary'));
      f.addCategory(const BudgetCategory(name: 'Amex', type: CategoryType.transfer));
      expect(() => f.addCategory(const BudgetCategory(name: 'Amex', type: CategoryType.transfer)), throwsA(isA<XlsxException>()));
      f.appendEntries([
        BudgetEntry(date: DateTime(2026, 3, 1), category: 'Salary Kate', description: 'ACME', amount: -1500),
        BudgetEntry(date: DateTime(2026, 3, 2), category: 'Amex', description: 'bill', amount: 400),
      ]);
      f = BudgetFile.open(f.save());
      expect(f.categories.length, 20);
      final kate = f.category('Salary Kate')!;
      expect(kate.type, CategoryType.income);
      expect(kate.row, 23);
      expect(kate.icon, 'income');
      expect(kate.hint, 'Her salary');
      expect(f.category('Amex')!.type, CategoryType.transfer);
      final settings = f.workbook.sheet('Settings')!;
      expect(settings.readRow(23)['B']?.text, 'Income');
      expect(settings.readRow(24)['B']?.text, 'Transfer');
      final inc = f.workbook.sheet('Overview')!.readRow(8)['D']?.formula ?? '';
      final exp = f.workbook.sheet('Overview')!.readRow(9)['D']?.formula ?? '';
      expect(inc, contains('"Salary Kate"'));
      expect(inc, contains('"Income"'));
      expect(exp, contains('"<>Amex"'));
      expect(exp, contains('"<>Credit card"'));
      expect(exp, contains('"<>Salary Kate"'));
      final xml = entriesXml(f.workbook.save());
      expect(xml, contains(r"$A$5:$A$24"), reason: 'the dropdown covers the new rows');
      expect(xml, contains(r'$C2="Amex"'), reason: 'the transfer format is cloned');
      expect(f.entries.length, 2);

      // Turning the transfer into an expense drops its format.
      final amex = f.category('Amex')!;
      f.updateCategory(amex, amex.copyWith(type: CategoryType.expense));
      final xml2 = entriesXml(f.save());
      expect(xml2, isNot(contains(r'$C2="Amex"')));
      expect(xml2, contains(r'$C2="Credit card"'));
    });

    test("a user's file: the totals rows are recognised", () {
      var f = BudgetFile.open(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
      f.addCategory(const BudgetCategory(name: 'Gehalt Kate', type: CategoryType.income));
      f = BudgetFile.open(f.save());
      expect(f.category('Gehalt Kate')!.type, CategoryType.income);
      expect(f.workbook.sheet('Einstellungen')!.readRow(f.category('Gehalt Kate')!.row!)['B']?.text, 'Einnahme');
      expect(f.workbook.sheet('Übersicht')!.readRow(8)['C']?.formula, '-(SUMIFS(Buchungen!\$E:\$E,Buchungen!\$B:\$B,C\$3,Buchungen!\$C:\$C,"Einnahmen")+SUMIFS(Buchungen!\$E:\$E,Buchungen!\$B:\$B,C\$3,Buchungen!\$C:\$C,"Gehalt Kate"))');
    });
  });
}
