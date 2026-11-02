import 'package:az_receipts/categorize/categorizer.dart';
import 'package:az_receipts/core/money.dart';
import 'package:az_receipts/core/text_normalize.dart';
import 'package:az_receipts/ocr/ocr_rows.dart';
import 'package:az_receipts/ocr/ocr_types.dart';
import 'package:az_receipts/parser/rksv_qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('money', () {
    test('parses comma and dot decimals, signs and currency', () {
      expect(parseCents('6,30'), 630);
      expect(parseCents('€ 5,99'), 599);
      expect(parseCents('5.99 €'), 599);
      expect(parseCents('-6,30'), -630);
      expect(parseCents('Mastercard EUR -6,30'), -630);
      expect(parseCents('abc'), isNull);
      expect(parseCents('12'), isNull);
    });
    test('formats', () {
      expect(formatCents(630), '6,30');
      expect(formatCents(5), '0,05');
      expect(formatCents(-1401), '-14,01');
      expect(formatCents(1531, comma: false, currency: 'EUR'), '15.31 EUR');
    });
    test('quantity lines', () {
      expect(parseQuantityLine('= 2 × 1.89'), (quantity: 2.0, unitCents: 189));
      expect(parseQuantityLine('2 x 1,89'), (quantity: 2.0, unitCents: 189));
      expect(parseQuantityLine('3 Stk x 0,99'), (quantity: 3.0, unitCents: 99));
      expect(parseQuantityLine('0,512 kg x 2,49'), (quantity: 0.512, unitCents: 249));
      expect(parseQuantityLine('Socken'), isNull);
    });
  });

  group('normalize', () {
    test('folds umlauts and case', () {
      expect(normalize('Müller  GmbH'), 'mueller gmbh');
      expect(normalize('Ernsting\'s family'), "ernsting's family");
      expect(tokens('Nivea Deospray 150ml fresh'), ['nivea', 'deospray', 'fresh']);
    });
  });

  group('rows', () {
    OcrLine line(String t, double x0, double y0, double x1, double y1) =>
        OcrLine(text: t, confidence: 1, detScore: 1, x0: x0, y0: y0, x1: x1, y1: y1);

    test('groups same-baseline boxes left to right', () {
      final rows = groupRows([
        line('5,99', 500, 100, 560, 130),
        line('Socken', 10, 102, 120, 130),
        line('Bar', 10, 140, 60, 170),
        line('20,00', 500, 141, 560, 171),
      ]);
      expect(rows.map((r) => r.text), ['Socken  5,99', 'Bar  20,00']);
      expect(rows.first.rightText, '5,99');
      expect(rows.first.leftText, 'Socken');
    });

    test('does not merge horizontally overlapping boxes', () {
      final rows = groupRows([
        line('a', 10, 100, 200, 130),
        line('b', 20, 105, 210, 135),
      ]);
      expect(rows.length, 2);
    });
  });

  group('rksv', () {
    const payload =
        '_R1-AT1_DEMO-KASSE-1_000123_2026-11-02T15:46:06_1,55_0,00_0,00_0,00_0,00_YWJjZGVmZ2hpams=_AT1-1234567_bWFsbGVy_c2lnbmF0dXJlRGVtbw==';
    test('parses the structured fields', () {
      final q = RksvQr.tryParse(payload)!;
      expect(q.kassenId, 'DEMO-KASSE-1');
      expect(q.belegNummer, '000123');
      expect(q.timestamp, DateTime(2026, 11, 2, 15, 46, 6));
      expect(q.grossByRate[20], 155);
      expect(q.grossByRate[10], 0);
      expect(q.totalCents, 155);
      expect(q.certificateSerial, 'AT1-1234567');
    });
    test('sums several rates', () {
      final q = RksvQr.tryParse('_R1-AT1_K_1_2026-01-01T00:00:00_10,73_4,58_0,00_0,00_0,00_a_b_c_d')!;
      expect(q.totalCents, 1531);
    });
    test('rejects other codes', () {
      expect(RksvQr.tryParse('https://example.com'), isNull);
      expect(RksvQr.tryParse('_R1-AT1_too_short'), isNull);
    });
  });

  group('categorizer', () {
    final c = Categorizer();
    test('merchant rules', () {
      expect(c.categorizeMerchant('dm drogerie markt GmbH'), 'drugstore');
      expect(c.categorizeMerchant('TK Maxx'), 'clothing');
      expect(c.categorizeMerchant('Unknown Shop'), isNull);
    });
    test('keyword rules prefer the longest match', () {
      expect(c.categorizeItem('Nivea Deospray 150ml'), 'drugstore');
      expect(c.categorizeItem('Socken 3er Pack'), 'clothing');
      expect(c.categorizeItem('sitzendes kuscheltier 29cm'), 'toys');
      expect(c.categorizeItem('Vollmilch 1l'), 'groceries');
      expect(c.categorizeItem('xyz', fallback: 'household'), 'household');
      expect(c.categorizeItem('xyz'), 'other');
    });
    test('short keywords need word boundaries', () {
      // "tee" must not fire inside "tastatur"; "led" not inside "gefaltet".
      expect(c.categorizeItem('Tastatur USB'), 'electronics');
      expect(c.categorizeItem('Grüner Tee'), 'groceries');
    });
    test('learned rules win ties', () {
      final learned = Categorizer(
        merchantRules: Categorizer.defaultMerchantRules(),
        keywordRules: [
          ...Categorizer.defaultKeywordRules(),
          const KeywordRule('kerze', 'entertainment', source: RuleSource.learned),
        ],
      );
      expect(learned.categorizeItem('Kerze rot'), 'entertainment');
    });
    test('learn keyword strips sizes', () {
      expect(Categorizer.learnKeywordFor('nivea deospray 150ml fresh flower'), 'nivea deospray fresh flower');
      expect(Categorizer.learnKeywordFor('4er Pack Spitzkerzen Winter'), 'pack spitzkerzen winter');
    });
  });
}
