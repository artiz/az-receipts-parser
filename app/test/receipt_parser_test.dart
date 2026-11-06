import 'package:az_budget/categorize/categorizer.dart';
import 'package:az_budget/parser/parsed_receipt.dart';
import 'package:az_budget/parser/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Expected values read off the sample photos. Items are `(name fragment,
/// cents)`; the fragment must appear in the parsed item name (case-insensitive).
class Expected {
  const Expected({
    required this.merchant,
    required this.date,
    required this.totalCents,
    required this.payment,
    required this.items,
    required this.category,
    this.addressContains,
    this.vatRates = const [],
  });
  final String merchant;
  final DateTime date;
  final int totalCents;
  final PaymentMethod payment;
  final List<(String, int)> items;
  final String category;
  final String? addressContains;
  final List<double> vatRates;
}

final expected = <String, Expected>{
  // A shop's digital receipt (PDF text layer, see samples/receipts/billa_ebon.pdf):
  // "2 x 1.79" is printed above the item it belongs to.
  'billa_ebon': Expected(
    merchant: 'BILLA',
    date: DateTime(2026, 11, 3, 17, 54),
    totalCents: 2633,
    payment: PaymentMethod.card,
    category: 'groceries',
    addressContains: '1220 WIEN',
    items: [
      ('Mango', 179), ('EXTREM AKTION', -80), ('Mango', 179), ('EXTREM AKTION', -80), ('Mango', 179), ('EXTREM AKTION', -80),
      ('Trauben', 199), ('Erdäpfel', 249), ('Zucchini', 199), ('Kirschpap', 299), ('Mohnstrudel', 429), ('Kokos', 358), ('SKYR', 238), ('Sauerrahm', 99), ('Eier', 266),
    ],
    vatRates: [10, 4.9],
  ),
  'dm_wien': Expected(
    merchant: 'dm',
    date: DateTime(2026, 11, 2, 14, 50),
    totalCents: 630,
    payment: PaymentMethod.card,
    category: 'drugstore',
    addressContains: '1020 Wien',
    items: [('Balea Med', 375), ('alverde', 95), ('alverde Seife', 95), ('Cr', 65)],
    vatRates: [20],
  ),
  'tedi_wien': Expected(
    merchant: 'TEDi',
    date: DateTime(2026, 11, 2, 15, 46, 6),
    totalCents: 155,
    payment: PaymentMethod.cash,
    category: 'household',
    addressContains: '1020 Wien',
    items: [('Spitzkerzen', 155)],
    vatRates: [20],
  ),
  'ernstings_wien': Expected(
    merchant: "Ernsting's family",
    date: DateTime(2026, 11, 2, 15, 9, 6),
    totalCents: 599,
    payment: PaymentMethod.card,
    category: 'clothing',
    items: [('Socken', 599)],
    vatRates: [20],
  ),
  'action_wien': Expected(
    merchant: 'Action',
    date: DateTime(2026, 11, 2, 15, 27, 20),
    totalCents: 1531,
    payment: PaymentMethod.card,
    category: 'household',
    addressContains: 'Wien',
    items: [('schokoladenerdn', 259), ('lotus speculoos', 199), ('kuscheltier', 695), ('nivea deospray', 378)],
    vatRates: [20, 10],
  ),
  'tkmaxx_wien': Expected(
    merchant: 'TK Maxx',
    date: DateTime(2026, 11, 2, 13, 59, 53),
    totalCents: 599,
    payment: PaymentMethod.cash,
    category: 'clothing',
    items: [('Partydekoration', 599)],
  ),
  'synthetic_rksv_qr': Expected(
    merchant: 'TEST KASSE',
    date: DateTime(2026, 11, 2, 15, 46, 6),
    totalCents: 155,
    payment: PaymentMethod.unknown,
    // No merchant rule: the receipt takes the majority item category.
    category: 'household',
    items: [('Kerze', 155)],
    vatRates: [20],
  ),
};

void main() {
  final parser = ReceiptParser();
  final categorizer = Categorizer();

  test('every golden fixture has expectations', () {
    expect(goldenNames().toSet(), expected.keys.toSet());
  });

  for (final entry in expected.entries) {
    group(entry.key, () {
      final ocr = loadGolden(entry.key);
      final r = parser.parse(ocr);
      categorizer.apply(r);
      final e = entry.value;

      test('merchant', () => expect(r.merchant, e.merchant));
      test('date/time', () => expect(r.purchasedAt, e.date));
      test('total', () => expect(r.totalCents, e.totalCents));
      test('payment', () => expect(r.payment, e.payment));
      test('receipt category', () => expect(r.categoryKey, e.category));
      if (e.addressContains != null) {
        test('address', () => expect(r.address, contains(e.addressContains)));
      }
      test('items', () {
        expect(r.items.length, e.items.length, reason: 'items: ${r.items}');
        for (var i = 0; i < e.items.length; i++) {
          expect(r.items[i].name.toLowerCase(), contains(e.items[i].$1.toLowerCase()), reason: 'item $i: ${r.items[i]}');
          expect(r.items[i].totalCents, e.items[i].$2, reason: 'item $i: ${r.items[i]}');
        }
      });
      test('items add up to the total', () => expect(r.itemsSumCents, e.totalCents));
      if (e.vatRates.isNotEmpty) {
        test('vat rates', () => expect(r.vat.map((v) => v.rate).toSet(), e.vatRates.toSet(), reason: '${r.vat}'));
      }
      test('confidence is meaningful', () => expect(r.confidence, greaterThanOrEqualTo(0.7), reason: r.warnings.toString()));
    });
  }

  group('item categories', () {
    test('action items are categorised per item', () {
      final r = parser.parse(loadGolden('action_wien'));
      categorizer.apply(r);
      final byName = {for (final i in r.items) i.name.toLowerCase(): i.categoryKey};
      expect(byName.entries.firstWhere((e) => e.key.contains('speculoos')).value, 'groceries');
      expect(byName.entries.firstWhere((e) => e.key.contains('erdn')).value, 'groceries');
      expect(byName.entries.firstWhere((e) => e.key.contains('kuscheltier')).value, 'toys');
      expect(byName.entries.firstWhere((e) => e.key.contains('deospray')).value, 'drugstore');
    });

    test('nivea deospray quantity line is attached', () {
      final r = parser.parse(loadGolden('action_wien'));
      final deo = r.items.firstWhere((i) => i.name.toLowerCase().contains('deospray'));
      expect(deo.quantity, 2);
      expect(deo.unitCents, 189);
    });

    test('dm items inherit drugstore', () {
      final r = parser.parse(loadGolden('dm_wien'));
      categorizer.apply(r);
      expect(r.items.map((i) => i.categoryKey).toSet(), {'drugstore'});
    });

    test('socks are clothing', () {
      final r = parser.parse(loadGolden('ernstings_wien'));
      categorizer.apply(r);
      expect(r.items.single.categoryKey, 'clothing');
    });
  });

  group('rksv qr', () {
    test('synthetic qr drives date, total and vat', () {
      final r = parser.parse(loadGolden('synthetic_rksv_qr'));
      expect(r.rksvKassenId, 'DEMO-KASSE-1');
      expect(r.rksvBelegNummer, '000123');
      expect(r.vat.single.rate, 20);
      expect(r.vat.single.grossCents, 155);
      expect(r.warnings, isNot(contains('total_missing')));
    });
  });
}
