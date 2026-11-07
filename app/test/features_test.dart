import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/budget/entry_suggest.dart';
import 'package:az_budget/budget/receipt_split.dart';
import 'package:az_budget/budget/receipt_to_entry.dart';
import 'package:az_budget/import/statement_rows.dart';
import 'package:az_budget/parser/parsed_receipt.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

Uint8List fixture(String name) => File('test/fixtures/$name').readAsBytesSync();
Uint8List template(String lang) => File('assets/templates/budget_$lang.xlsx').readAsBytesSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rules sheet', () {
    test('templates carry an empty rules sheet; a rule matches by substring and wildcard', () {
      for (final lang in BudgetLabels.languages) {
        final f = BudgetFile.open(template(lang));
        expect(f.workbook.sheet(BudgetLabels.rulesSheet[lang]!), isNotNull, reason: lang);
        expect(f.rules, isEmpty);
      }
      final r = BudgetRule(pattern: 'spar*wien', category: 'Lebensmittel');
      expect(r.matches('POS SPAR 2362 WIEN'), isTrue);
      expect(r.matches('Spar Dankt'), isFalse);
      expect(BudgetRule(pattern: 'Bäckerei', category: 'x').matches('baeckerei felber'), isTrue, reason: 'umlauts folded both ways');
      expect(BudgetRule(pattern: '', category: 'x').matches('anything'), isFalse);
    });

    test('rules are added to the template sheet and created from scratch in an old file', () {
      var f = BudgetFile.open(template('de'));
      f.addRule(BudgetRule(pattern: 'netflix', category: 'Abos & Internet', description: 'Netflix'));
      f.addRule(BudgetRule(pattern: 'spar', category: 'Lebensmittel'));
      f = BudgetFile.open(f.save());
      expect(f.rules.map((r) => '${r.pattern}>${r.category}>${r.description}'), ['netflix>Abos & Internet>Netflix', 'spar>Lebensmittel>']);
      expect(f.rules.first.row, 5);
      expect(f.workbook.sheet('Regeln')!.readRow(4)['A']?.text, 'Muster');

      // The user's file from before the rules sheet existed.
      var g = BudgetFile.open(fixture('budget_small.xlsx'));
      expect(g.workbook.sheet('Regeln'), isNull);
      expect(g.rules, isEmpty);
      g.addRule(BudgetRule(pattern: 'billa', category: 'Lebensmittel'));
      final bytes = g.save();
      g = BudgetFile.open(bytes);
      expect(g.rules.single.category, 'Lebensmittel');
      expect(g.rules.single.row, 5);
      final sheet = g.workbook.sheet('Regeln')!;
      expect(sheet.readRow(1)['A']?.text, 'Regeln');
      expect(sheet.readRow(4)['B']?.text, 'Kategorie');
      final zip = ZipDecoder().decodeBytes(bytes);
      final types = String.fromCharCodes(zip.findFile('[Content_Types].xml')!.content as List<int>);
      expect(types, contains('/${sheet.path}'));
      final wb = String.fromCharCodes(zip.findFile('xl/workbook.xml')!.content as List<int>);
      expect(wb, contains('name="Regeln"'));
      // Everything else still reads, and a second rule lands on the next row.
      expect(g.entries.length, 36);
      g.addRule(BudgetRule(pattern: 'spar', category: 'Lebensmittel'));
      expect(BudgetFile.open(g.save()).rules.map((r) => r.row), [5, 6]);
      // An English file names the sheet in English.
      var e = BudgetFile.open(template('en'));
      e.translateTo('en');
      e.addRule(BudgetRule(pattern: 'tesco', category: 'Groceries'));
      e = BudgetFile.open(e.save());
      expect(e.rules.single.category, 'Groceries');
    });

    test('the statement classifier and the receipt draft ask the rules first', () {
      final categories = [
        const BudgetCategory(name: 'Lebensmittel', type: CategoryType.expense),
        const BudgetCategory(name: 'Haushalt', type: CategoryType.expense),
        const BudgetCategory(name: 'Business', type: CategoryType.expense),
        const BudgetCategory(name: 'Einnahmen', type: CategoryType.income),
      ];
      final existing = [BudgetEntry(date: DateTime(2026, 8, 1), category: 'Haushalt', description: 'Amazon', amount: 20)];
      final rules = [
        BudgetRule(pattern: 'amazon*aws', category: 'Business', description: 'AWS'),
        BudgetRule(pattern: 'amazon', category: 'Lebensmittel'),
        BudgetRule(pattern: 'ghost', category: 'No such category'),
      ];
      final c = StatementRowClassifier(categories: categories, existing: existing, rules: rules);
      final rows = StatementRows.parse('''
Kontoauszug
Buchungstext  Valuta  Betrag
E-COMM  12,00 K1 01.09. 02:03  01.09.2026  12,00-
AMAZON EU SARL
E-COMM  99,65 USD K1 02.09. 00:00  02.09.2026  88,06-
AMAZON WEB SERVICES AWS EMEA
POS  5,00 K1 03.09. 10:00  03.09.2026  5,00-
GHOST SHOP
''');
      final unknown = <int>[];
      final p = c.propose(rows, unknown: unknown);
      expect(p[0].entry.category, 'Lebensmittel', reason: 'the rule beats the learned Haushalt');
      expect(p[1].entry.category, 'Business');
      expect(p[1].entry.description, 'AWS', reason: 'the rule renames');
      expect(p[2].entry.category, isNot('No such category'), reason: 'a rule to a missing category is ignored');
      expect(unknown, [2]);

      final receipt = ParsedReceipt()
        ..merchant = 'Amazon'
        ..totalCents = 1500;
      final draft = receiptToDraft(receipt, categories: categories, suggestions: EntrySuggestions(existing), rules: rules);
      expect(draft.category, 'Lebensmittel');
      expect(receiptToDraft(receipt, categories: categories, suggestions: EntrySuggestions(existing)).category, 'Haushalt', reason: 'without rules the history decides');
    });
  });

  group('receipt split', () {
    test('one booking per category, remainder with the main one, items in the notes', () {
      final items = [
        const ReceiptItemDraft(name: 'Milch', amount: 1.29),
        const ReceiptItemDraft(name: 'Spülmittel', amount: 2.99),
        const ReceiptItemDraft(name: 'Brot', amount: 2.5),
        const ReceiptItemDraft(name: 'Rabatt', amount: -0.5),
      ];
      final entries = splitReceipt(
        date: DateTime(2026, 11, 6),
        description: 'Billa',
        total: 6.38, // items sum to 6.28: 10 cents unparsed
        items: items,
        assignments: ['Lebensmittel', 'Haushalt', 'Lebensmittel', 'Lebensmittel'],
        main: 'Lebensmittel',
        extraNote: 'Beleg: Belege/2026/x.jpg',
      );
      expect(entries.length, 2);
      expect(entries[0].category, 'Lebensmittel');
      expect(entries[0].amount, closeTo(3.39, 0.001));
      expect(entries[0].note, 'Milch 1,29\nBrot 2,50\nRabatt -0,50\n… 0,10\nBeleg: Belege/2026/x.jpg');
      expect(entries[1].category, 'Haushalt');
      expect(entries[1].amount, 2.99);
      expect(entries[1].note, 'Spülmittel 2,99\nBeleg: Belege/2026/x.jpg');
      expect(entries.fold(0.0, (s, e) => s + e.amount), closeTo(6.38, 0.001));
      // Everything in one category: a single entry, no split.
      expect(splitReceipt(date: DateTime(2026, 1, 1), description: 'x', total: 6.28, items: items, assignments: List.filled(4, 'Lebensmittel'), main: 'Lebensmittel').length, 1);
      final draft = receiptToDraft(ParsedReceipt()..merchant = 'Billa'..totalCents = 358..items.add(ParsedItem(name: 'Skyr', totalCents: 358)..quantity = 2), categories: const [], suggestions: EntrySuggestions(const []));
      expect(draft.items.single.name, '2× Skyr');
      expect(draft.items.single.amount, 3.58);
    });
  });

  group('file version and migration', () {
    test('templates carry the current version, the legacy file is version 1 and lists what it lacks', () {
      for (final lang in BudgetLabels.languages) {
        final f = BudgetFile.open(template(lang));
        expect(f.version, BudgetFile.currentVersion, reason: lang);
        expect(f.migrationSteps, isEmpty, reason: lang);
      }
      final g = BudgetFile.open(fixture('budget_small.xlsx'));
      expect(g.version, 1);
      expect(g.migrationSteps, [MigrationStep.rulesSheet, MigrationStep.styleColumn, MigrationStep.version], reason: 'the limits are there already');
    });

    test('migrating the legacy file adds the rules sheet, the style header and the version row, once', () {
      var g = BudgetFile.open(fixture('budget_small.xlsx'));
      final limitsBefore = g.settings.map((s) => '${s.label}=${s.value}').toList();
      g.migrate();
      final bytes = g.save();
      g = BudgetFile.open(bytes);
      expect(g.version, BudgetFile.currentVersion);
      expect(g.migrationSteps, isEmpty);
      expect(g.rules, isEmpty);
      final rules = g.workbook.sheet('Regeln')!;
      expect(rules.readRow(1)['A']?.text, 'Regeln');
      expect(rules.readRow(4)['A']?.text, 'Muster');
      expect(g.workbook.sheet('Einstellungen')!.readRow(4)['E']?.text, 'Symbol & Farbe');
      final version = g.settings.firstWhere((s) => s.label == 'Dateiversion');
      expect(version.row, 10, reason: 'below the five limits, above the legend');
      expect(version.note, isNotEmpty);
      // Everything that was there stays: categories, limits, bookings, legacy groups column.
      expect(g.settings.where((s) => s.label != 'Dateiversion').map((s) => '${s.label}=${s.value}'), limitsBefore);
      expect(g.categories.length, 18);
      expect(g.entries.length, 36);
      expect(g.workbook.sheet('Einstellungen')!.readRow(4)['C']?.text, 'Frühere Gruppen (v1)');
      // A second migration is a no-op; rules still land on the right row.
      g.migrate();
      g.addRule(BudgetRule(pattern: 'billa', category: 'Lebensmittel'));
      g = BudgetFile.open(g.save());
      expect(g.rules.single.row, 5);
      expect(g.settings.where((s) => s.label == 'Dateiversion').length, 1);
    });

    test('a file without any settings gets the template limits, the header and the version in its language', () {
      var e = BudgetFile.open(template('en'));
      final sheet = e.workbook.sheet('Settings')!;
      for (var r = 4; r <= 10; r++) {
        for (final c in ['F', 'G', 'H']) {
          sheet.clear('$c$r');
        }
      }
      e = BudgetFile.open(e.save());
      expect(e.settings, isEmpty);
      expect(e.version, 1);
      expect(e.migrationSteps, [MigrationStep.limits, MigrationStep.version]);
      e.migrate();
      e = BudgetFile.open(e.save());
      expect(e.setting('Monatslimit 1'), 3000);
      expect(e.setting('Monatslimit 2'), 4000);
      expect(e.setting('Ausgabenlimit 3'), 1000);
      expect(e.settings.map((s) => s.label), ['Month limit 1', 'Month limit 2', 'Expense limit 1', 'Expense limit 2', 'Expense limit 3', 'File version']);
      expect(e.settings.first.note, 'Monthly expenses above this: amber');
      expect(e.workbook.sheet('Settings')!.readRow(4)['F']?.text, 'Setting');
      expect(e.version, 2);
      expect(e.migrationSteps, isEmpty);
    });

    test('the service migrates the loaded year file in place', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      await settings.setFolder('tree', 'Budget');
      final tmp = await Directory.systemTemp.createTemp('azmig');
      final folder = FakeFolder(fixture('budget_small.xlsx'));
      final s = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
      await s.sync();
      expect(s.fileOutdated, isTrue);
      await s.migrateFile();
      expect(s.fileOutdated, isFalse);
      expect(s.file!.version, BudgetFile.currentVersion);
      expect(s.file!.rules, isEmpty);
      await tmp.delete(recursive: true);
    });
  });

  group('csv', () {
    late Directory tmp;
    late AppSettings settings;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = await AppSettings.load();
      await settings.setFolder('tree', 'Budget');
      tmp = await Directory.systemTemp.createTemp('azbudget');
    });
    tearDown(() => tmp.delete(recursive: true));

    test('CSV export writes the bookings into the folder, replacing an older export', () async {
      final folder = FakeFolder(fixture('budget_small.xlsx'));
      final s = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
      await s.sync();
      final name = await s.exportCsv();
      expect(name, 'Budget 2026.csv');
      final csvUri = folder.names.entries.firstWhere((e) => e.value == name).key;
      expect(folder.files[csvUri]!.sublist(0, 3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM for Excel');
      final text = utf8.decode(folder.files[csvUri]!); // the decoder drops the BOM
      expect(text, startsWith('Datum;Monat;Kategorie;Beschreibung;Betrag;Notiz\r\n'));
      expect(text.split('\r\n').where((l) => l.isNotEmpty).length, 37);
      expect(text, contains(';"Kinder";'));
      await s.exportCsv();
      expect(folder.names.values.where((n) => n == name).length, 1, reason: 'overwritten, not duplicated');
    });
  });
}
