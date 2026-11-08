import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/entry_suggest.dart';
import 'package:az_budget/budget/xlsx_workbook.dart';
import 'package:az_budget/core/expression.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List fixture(String name) => File('test/fixtures/$name').readAsBytesSync();

void main() {
  unwrapTests();
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

  group('expressions', () {
    test('evaluates sums with comma decimals', () {
      expect(evalExpression('=500+232,23+100.34'), closeTo(832.57, 1e-9));
      expect(evalExpression('5+6,50'), 11.5);
      expect(evalExpression('(10+5)/2*3'), 22.5);
      expect(evalExpression('1.234,56-4,56'), 1230);
      expect(evalExpression('-12,5'), -12.5);
      expect(evalExpression('abc'), isNull);
      expect(evalExpression('5+'), isNull);
      expect(normalizeFormula('= 500 + 232,23'), '=500+232.23');
      expect(normalizeFormula('12,5'), isNull);
    });
    test('input formulas are stored with their value and read back', () {
      final f = BudgetFile.open(fixture('budget_small.xlsx'));
      f.setOverviewInput('Kontostand', 5, 832.57, formula: '=500+232.23+100.34');
      final g = BudgetFile.open(f.save());
      expect(g.overview.byLabelPrefix('Kontostand')!.$2[4], 832.57);
      expect(g.overview.formulas.entries.firstWhere((e) => e.key.startsWith('Kontostand')).value[4], '=500+232.23+100.34');
      expect(g.overview.formulas.entries.firstWhere((e) => e.key.startsWith('Kontostand')).value[0], isNull);
    });
  });

  group('suggestions', () {
    final entries = BudgetFile.open(fixture('budget_small.xlsx')).entries;
    final s = EntrySuggestions(entries, now: DateTime(2026, 4, 1));
    test('quick tiles follow frequency, capped per category', () {
      final tiles = s.quickTiles(limit: 5, perCategory: 2);
      expect(tiles.first.category, 'Lebensmittel');
      expect(tiles.where((t) => t.category == 'Lebensmittel').length, lessThanOrEqualTo(2));
      expect(tiles.map((t) => '${t.category}/${t.description}'), contains('Kinder/Marina'));
    });
    test('pinned tiles come first, keep their learned amount, and a pin without bookings asks for one', () {
      final pinned = [QuickTile.tileKey('Kinder', 'Marina'), QuickTile.tileKey('Wohnen', 'Strom')];
      final tiles = s.quickTiles(limit: 5, perCategory: 2, pinned: pinned);
      expect(tiles.length, 5);
      expect(tiles[0].description, 'Marina');
      expect(tiles[0].pinned, isTrue);
      expect(tiles[0].amount, isNot(0), reason: 'the last amount from the file');
      expect(tiles[1].description, 'Strom');
      expect(tiles[1].amount, 0);
      expect(tiles[1].category, 'Wohnen');
      expect(tiles.skip(2).any((t) => t.pinned), isFalse);
      expect(tiles.skip(2).any((t) => t.description == 'Marina'), isFalse, reason: 'not listed twice');
      expect(tiles[0].key, pinned[0]);
    });
    test('prefix autocomplete per category', () {
      final d = s.descriptions('Lebensmittel', prefix: 's');
      expect(d.first.description, 'Spar');
      expect(d.map((x) => x.description), isNot(contains('Marina')));
      expect(s.descriptions('Kinder').map((x) => x.description), containsAll(['Marina', 'Platon']));
      expect(s.descriptions('Lebensmittel', prefix: 'bil').first.description, 'Billa');
    });
    test('autocomplete over the whole history, the chosen category first', () {
      final h = EntrySuggestions([
        BudgetEntry(date: DateTime(2026, 10, 1), category: 'Lebensmittel', description: 'Spar', amount: 20),
        BudgetEntry(date: DateTime(2026, 10, 2), category: 'Lebensmittel', description: 'SPAR', amount: 25),
        BudgetEntry(date: DateTime(2026, 10, 3), category: 'Haushalt', description: 'Spar Gourmet', amount: 8),
        BudgetEntry(date: DateTime(2026, 10, 4), category: 'Restaurants & Cafés', description: 'Pizza Spartacus', amount: 30),
        BudgetEntry(date: DateTime(2026, 10, 5), category: 'Restaurants & Cafés', description: 'Café Sperl', amount: 6),
        BudgetEntry(date: DateTime(2026, 10, 6), category: 'Wohnen', description: 'Wien Energie', amount: 90),
      ], now: DateTime(2026, 11, 1));
      String fmt(DescriptionSuggestion d) => '${d.category}:${d.description}';
      // Without a category: a match at the start beats a later word, then use.
      expect(h.autocomplete('spa').map(fmt), ['Lebensmittel:SPAR', 'Haushalt:Spar Gourmet', 'Restaurants & Cafés:Pizza Spartacus']);
      expect(h.autocomplete('spa').first.count, 2, reason: 'Spar and SPAR are one suggestion, shown as last written');
      expect(h.autocomplete('spa').first.lastAmount, 25);
      // The chosen category first even when its match is on a later word.
      expect(h.autocomplete('spa', category: 'Restaurants & Cafés').map(fmt).first, 'Restaurants & Cafés:Pizza Spartacus');
      // Accents and case aside; substring from three letters on.
      expect(h.autocomplete('cafe').map(fmt), ['Restaurants & Cafés:Café Sperl']);
      expect(h.autocomplete('nergi').map(fmt), ['Wohnen:Wien Energie']);
      expect(h.autocomplete('er'), isEmpty, reason: 'two letters: word prefixes only');
      expect(h.autocomplete(''), isEmpty);
      expect(h.autocomplete('s', limit: 2).length, 2);
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

/// wrapText of every cell style in a saved workbook, by xf index.
Map<int, bool> _wrapByStyle(Uint8List bytes) {
  final styles = String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/styles.xml')!.content as List<int>);
  final xfs = RegExp(r'<cellXfs[^>]*>(.*?)</cellXfs>', dotAll: true).firstMatch(styles)!.group(1)!;
  final out = <int, bool>{};
  var i = 0;
  for (final m in RegExp(r'<xf\b[^>]*?(?:/>|>.*?</xf>)', dotAll: true).allMatches(xfs)) {
    out[i++] = RegExp(r'wrapText="(1|true)"').hasMatch(m[0]!);
  }
  return out;
}

void unwrapTests() {
  group('rows hidden by an Excel filter', () {
    // Excel stores an applied autofilter as hidden="1" on the rows it hid
    // and does not re-evaluate it on open: with a filter "Monat 10, 11"
    // applied, every empty row below the data is hidden (blank month).
    BudgetFile filtered() {
      final f = BudgetFile.open(fixture('budget_small.xlsx'));
      final sheet = f.workbook.sheet('Buchungen')!;
      final last = f.entries.last.row!;
      for (var r = last + 1; r <= last + 20; r++) {
        sheet.setRowHidden(r, true);
      }
      // A booking of another month in the middle, filtered out.
      sheet.setRowHidden(f.entries[2].row!, true);
      return BudgetFile.open(f.save());
    }

    test('a new booking lands visible even in a row Excel hid while it was empty', () {
      var f = filtered();
      final sheet = f.workbook.sheet('Buchungen')!;
      final last = f.entries.last.row!;
      expect(sheet.isRowHidden(last + 1), isTrue);
      final rows = f.appendEntries([
        BudgetEntry(date: DateTime(2026, 11, 8), category: 'Haushalt', description: 'Pfeffermühle', amount: 39),
        BudgetEntry(date: DateTime(2026, 11, 8), category: 'Lebensmittel', description: 'Hirschschinken', amount: 21),
      ]);
      f = BudgetFile.open(f.save());
      final s2 = f.workbook.sheet('Buchungen')!;
      expect(rows, [last + 1, last + 2]);
      expect(rows.map(s2.isRowHidden), [false, false], reason: 'the bookings are visible');
      expect(s2.isRowHidden(last + 3), isTrue, reason: 'the empty rows below stay as Excel left them');
      expect(s2.isRowHidden(f.entries[2].row!), isTrue, reason: 'a filtered-out booking stays filtered out');
    });

    test('editing shows the row; deleting moves each booking with its own visibility', () {
      var f = filtered();
      final sheet = f.workbook.sheet('Buchungen')!;
      final hiddenRow = f.entries[2].row!;
      final before = [for (final e in f.entries) (e.description, sheet.isRowHidden(e.row!))];

      // Delete the first booking: everything below moves up one row.
      f.deleteEntryRow(f.entries.first.row!);
      f = BudgetFile.open(f.save());
      final s2 = f.workbook.sheet('Buchungen')!;
      final after = [for (final e in f.entries) (e.description, s2.isRowHidden(e.row!))];
      expect(after, before.skip(1).toList(), reason: 'every booking keeps its visibility, the hidden one moved up with it');
      expect(s2.isRowHidden(hiddenRow - 1), isTrue);
      expect(s2.isRowHidden(hiddenRow), isFalse, reason: 'the visible booking that moved into its old row is shown');

      // Editing the filtered-out booking shows it, like a cell typed in Excel.
      final e = f.entries.firstWhere((x) => s2.isRowHidden(x.row!));
      f.updateEntry(e.row!, BudgetEntry(date: e.date, category: e.category, description: '${e.description} (edited)', amount: e.amount));
      f = BudgetFile.open(f.save());
      expect(f.workbook.sheet('Buchungen')!.isRowHidden(e.row!), isFalse);
    });

    test('rows without the attribute are untouched by a write', () {
      final f = BudgetFile.open(fixture('budget_small.xlsx'));
      final sheet = f.workbook.sheet('Buchungen')!;
      final row = f.entries.first.row!;
      expect(sheet.isRowHidden(row), isFalse);
      sheet.setRowHidden(row, false);
      expect(BudgetFile.open(f.save()).workbook.sheet('Buchungen')!.isRowHidden(row), isFalse);
    });
  });

  group('note column unwrapped on save', () {
    test('wrapped F cells and the column default get an unwrapped style, D keeps wrapping, auto heights dropped', () {
      final f = BudgetFile.open(fixture('budget_small_wrap.xlsx'));
      f.appendEntries([BudgetEntry(date: DateTime(2026, 4, 10), category: 'Lebensmittel', description: 'Spar', amount: 5, note: 'a; b; c')]);
      final bytes = f.save();
      final wrap = _wrapByStyle(bytes);
      final sheet = String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
      int styleOf(String ref) => int.parse(RegExp('<c r="$ref" s="(\\d+)"').firstMatch(sheet)!.group(1)!);
      for (final ref in ['F2', 'F5', 'F37']) {
        expect(wrap[styleOf(ref)], isFalse, reason: '$ref unwrapped');
      }
      expect(wrap[styleOf('D5')], isTrue, reason: 'other columns keep their wrapping');
      final colF = RegExp(r'<col [^>]*min="6"[^>]*/>').firstMatch(sheet)![0]!;
      expect(wrap[int.parse(RegExp(r'style="(\d+)"').firstMatch(colF)!.group(1)!)], isFalse, reason: 'column default unwrapped');
      expect(RegExp(r'<row r="5"[^>]*>').firstMatch(sheet)![0], isNot(contains('ht=')), reason: 'auto height dropped');
      expect(RegExp(r'<row r="6"[^>]*>').firstMatch(sheet)![0], contains('ht="45"'), reason: 'hand-set height kept');
      expect(wrap.length, greaterThan(51), reason: 'unwrapped copies appended, shared styles untouched');
      // The table column's own format (Excel re-applies it on edit) loses its wrapping too; other columns keep theirs.
      final table = String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/tables/table1.xml')!.content as List<int>);
      final styles = String.fromCharCodes(ZipDecoder().decodeBytes(bytes).findFile('xl/styles.xml')!.content as List<int>);
      final dxfs = RegExp(r'<dxf\b[^>]*?(?:/>|>.*?</dxf>)', dotAll: true).allMatches(RegExp(r'<dxfs[^>]*>(.*?)</dxfs>', dotAll: true).firstMatch(styles)!.group(1)!).map((m) => m[0]!).toList();
      final noteDxf = int.parse(RegExp(r'name="Notiz" dataDxfId="(\d+)"').firstMatch(table)!.group(1)!);
      final descDxf = int.parse(RegExp(r'name="Beschreibung" dataDxfId="(\d+)"').firstMatch(table)!.group(1)!);
      expect(noteDxf, 15, reason: 'an unwrapped copy appended after the 15 existing dxfs');
      expect(dxfs[noteDxf], isNot(contains('wrapText')));
      expect(dxfs[noteDxf], contains('vertical="top"'));
      expect(dxfs[13], contains('wrapText="1"'), reason: 'the original dxf stays for whoever else uses it');
      expect(descDxf, 14, reason: 'Beschreibung keeps its italic dxf');
      expect(dxfs[descDxf], contains('<i'));
      // Re-reading the result works and a second save changes nothing more.
      final g = BudgetFile.open(bytes);
      expect(g.entries.last.note, 'a; b; c');
      expect(_wrapByStyle(g.save()).length, wrap.length);
      // A file without wrapping is left alone (no styles.xml rewrite).
      final plain = BudgetFile.open(fixture('budget_small.xlsx'));
      plain.appendEntries([BudgetEntry(date: DateTime(2026, 4, 10), category: 'Lebensmittel', description: 'Spar', amount: 5)]);
      expect(ZipDecoder().decodeBytes(plain.save()).findFile('xl/styles.xml')!.content, fixtureEntry('budget_small.xlsx', 'xl/styles.xml'));
    });
  });
}

List<int> fixtureEntry(String name, String path) => ZipDecoder().decodeBytes(fixture(name)).findFile(path)!.content as List<int>;
