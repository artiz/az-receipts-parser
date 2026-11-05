import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/entry_suggest.dart';
import 'package:az_budget/budget/xlsx_workbook.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List fixture(String name) => File('test/fixtures/$name').readAsBytesSync();

void main() {
  group('xlsx dates', () {
    test('serial round trip', () {
      expect(XlsxDate.toSerial(DateTime(2026, 1, 1)), 46023);
      expect(XlsxDate.fromSerial(46023), DateTime(2026, 1, 1));
      expect(XlsxDate.toSerial(DateTime(1900, 3, 1)), 61);
      expect(XlsxDate.fromSerial(46327.0), DateTime(2026, 11, 1));
    });
    test('column letters', () {
      expect(XlsxRef.columnLetters(1), 'A');
      expect(XlsxRef.columnLetters(26), 'Z');
      expect(XlsxRef.columnLetters(27), 'AA');
      expect(XlsxRef.columnIndex('AA'), 27);
      expect(XlsxRef.split('F2000'), ('F', 2000));
    });
  });

  for (final name in ['budget_small.xlsx', 'budget_small_lo.xlsx']) {
    group('BudgetFile $name', () {
      test('reads categories, settings, entries, overview inputs', () {
        final f = BudgetFile.open(fixture(name));
        expect(f.year, 2026);
        expect(f.categories.map((c) => c.name), contains('Lebensmittel'));
        expect(f.category('Einnahmen')!.type, CategoryType.income);
        expect(f.category('Kreditkarte')!.type, CategoryType.transfer);
        expect(f.category('Wohnen')!.type, CategoryType.expense);
        expect(f.setting('Monatslimit 1'), 3000);
        expect(f.setting('Monatslimit 2'), 4000);
        expect(f.setting('Ausgabenlimit 3'), 1000);
        expect(f.entries.length, 36);
        final first = f.entries.first;
        expect(first.date, DateTime(2026, 1, 1));
        expect(first.category, 'Lebensmittel');
        expect(first.description, 'Spar');
        expect(first.amount, 23.5);
        expect(first.row, 2);
        final income = f.entries.firstWhere((e) => e.category == 'Einnahmen');
        expect(income.amount, -3200);
        final start = f.overview.byLabelPrefix('Kontostand');
        expect(start, isNotNull);
        expect(start!.$2[0], 1001);
        expect(start.$2[2], 1003);
        expect(start.$2[3], isNull);
        expect(f.overview.byLabelPrefix('Sparkonto')!.$2[0], 500);
        expect(f.overview.byLabelPrefix('Kreditkarte')!.$2.every((v) => v == null), isTrue);
        expect(f.overview.plan['Wohnen']!.$2[0], 1300);
        expect(f.overview.plan.length, f.expenseCategories.length);
      });

      test('appends entries into the pre-formatted rows and keeps everything else', () {
        final bytes = fixture(name);
        final f = BudgetFile.open(bytes);
        final rows = f.appendEntries([
          BudgetEntry(date: DateTime(2026, 4, 2), category: 'Lebensmittel', description: 'SPAR', amount: 35.09),
          BudgetEntry(date: DateTime(2026, 4, 3), category: 'Einnahmen', description: 'Gehalt', amount: -3200, note: 'April; 2 Zeilen "x"'),
        ]);
        expect(rows, [38, 39]);
        final out = f.save();
        final g = BudgetFile.open(out);
        expect(g.entries.length, 38);
        final a = g.entries[36];
        expect(a.date, DateTime(2026, 4, 2));
        expect(a.category, 'Lebensmittel');
        expect(a.description, 'SPAR');
        expect(a.amount, 35.09);
        expect(a.row, 38);
        expect(a.note, '');
        final b = g.entries[37];
        expect(b.note, 'April; 2 Zeilen "x"');
        expect(b.amount, -3200);
        // The month formula of the pre-filled row is still there.
        final cells = g.workbook.requireSheet(sheetEntries).readRow(38);
        expect(cells['B']!.formula, contains('MONTH(A38)'));
        // The style of the date cell is inherited (number format for dates).
        expect(g.categories.length, f.categories.length);
        expect(g.setting('Monatslimit 2'), 4000);

        // Untouched zip entries are byte-identical; only the entries sheet and
        // workbook.xml (fullCalcOnLoad) change.
        final before = ZipDecoder().decodeBytes(bytes);
        final after = ZipDecoder().decodeBytes(out);
        final changed = <String>[];
        for (final file in before.files) {
          if (!file.isFile) continue;
          final other = after.findFile(file.name);
          expect(other, isNotNull, reason: file.name);
          if (!_sameBytes(file.content as List<int>, other!.content as List<int>)) changed.add(file.name);
        }
        expect(changed, contains(g.workbook.requireSheet(sheetEntries).path));
        expect(changed.toSet().difference({g.workbook.requireSheet(sheetEntries).path, 'xl/workbook.xml'}), isEmpty);
        expect(after.files.length, before.files.length);
      });

      test('appends beyond the pre-formatted range', () {
        final f = BudgetFile.open(fixture(name));
        final many = [
          for (var i = 0; i < 2010; i++)
            BudgetEntry(date: DateTime(2026, 5, 1 + i % 28), category: 'Kinder', description: 'Marina', amount: 5),
        ];
        final rows = f.appendEntries(many);
        expect(rows.last, 37 + 2010);
        final g = BudgetFile.open(f.save());
        expect(g.entries.length, 36 + 2010);
        expect(g.entries.last.row, 2047);
        final cells = g.workbook.requireSheet(sheetEntries).readRow(2047);
        expect(cells['B']!.formula, contains('MONTH(A2047)'));
      });

      test('updates overview inputs, plan and settings', () {
        final f = BudgetFile.open(fixture(name));
        f.setOverviewInput('Kreditkarte', 4, 1234.5);
        f.setOverviewInput('Kontostand', 4, 10162);
        f.setPlan('Wohnen', 1, 1250);
        f.setSetting('Monatslimit 1', 3100);
        f.setSetting('OpenAI Modell Hinweis', 1, note: 'Test');
        final g = BudgetFile.open(f.save());
        expect(g.overview.byLabelPrefix('Kreditkarte')!.$2[3], 1234.5);
        expect(g.overview.byLabelPrefix('Kontostand')!.$2[3], 10162);
        expect(g.overview.plan['Wohnen']!.$2[0], 1250);
        expect(g.setting('Monatslimit 1'), 3100);
        expect(g.setting('OpenAI Modell'), 1);
        // The old value is still untouched elsewhere.
        expect(g.setting('Monatslimit 2'), 4000);
      });
    });
  }

  group('suggestions', () {
    final entries = BudgetFile.open(fixture('budget_small.xlsx')).entries;
    final s = EntrySuggestions(entries, now: DateTime(2026, 4, 1));
    test('quick tiles follow frequency, capped per category', () {
      final tiles = s.quickTiles(limit: 5, perCategory: 2);
      expect(tiles.first.category, 'Lebensmittel');
      expect(tiles.where((t) => t.category == 'Lebensmittel').length, lessThanOrEqualTo(2));
      expect(tiles.map((t) => '${t.category}/${t.description}'), contains('Kinder/Marina'));
    });
    test('prefix autocomplete per category', () {
      final d = s.descriptions('Lebensmittel', prefix: 's');
      expect(d.first.description, 'Spar');
      expect(d.map((x) => x.description), isNot(contains('Marina')));
      expect(s.descriptions('Kinder').map((x) => x.description), containsAll(['Marina', 'Platon']));
      expect(s.descriptions('Lebensmittel', prefix: 'bil').first.description, 'Billa');
    });
    test('learned category and usual amount', () {
      expect(s.categoryFor('SPAR Wien 1220'), 'Lebensmittel');
      expect(s.categoryFor('Marina'), 'Kinder');
      expect(s.categoryFor('xy'), isNull);
      expect(s.usualAmount('Kinder', 'marina'), 10);
      expect(s.usualAmount('Kinder', 'unknown'), isNull);
    });
  });
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
