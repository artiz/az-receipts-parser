import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/import/statement_import.dart';
import 'package:az_budget/import/statement_rows.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic statement in the row layout the Rust side produces (names and
/// numbers invented, the shapes are the real ones).
const statement = '''
Erste Bank der oesterreichischen
Sparkassen AG
Kontoauszug  Nr. 004/2026
Buchungstext/Booking Text  Valuta/Value Beträge/Amounts in EUR
POS  55,25 LT K1 30.08. 13:14  31.08.2026  55,25-
RESTORANAS ETNO DVARAS VILNIUS 000 440
SPAR  2362 K1 31.08. 19:13  31.08.2026  73,58-
Gesendet von Revolut  31.08.2026  2,95
Max Muster
NOTPROVIDED
Gesendet von Revolut
KREDITRATE1310799143  01.09.2026  197,71-
Santander Consumer Bank GmbH
MDID:1310799143
E-COMM  13,99 NL K1 01.09. 02:03  01.09.2026  13,99-
NETFLIX.COM LOS GATOS 1072AB 528
E-COMM  99,65 USD K1 02.09. 00:00  02.09.2026  88,06-
AWS EMEA LUXEMBOURG L2338 442
SPESEN: 1,74 KURS: 1,154372 VOM:01.09.2026
AUTOMAT   00031193 K1    03.09. 12:28  03.09.2026  80,00-
s Kreditkartenrechnung Aug. 2026  04.09.2026  648,78-
Smartcard (Mastercard)
Kartenendnummer 5823
George-Transfer  05.09.2026  2.300,00
Erika Muster
George-Transfer
20260302SWI00943     20260302PAY00065  06.09.2026  693,07
MAX MUSTER / 23488861900 TRANSFER BETWEEN MY A
Kontoführung  30.09.2026  20,50-
Bonus Kontoführung  30.09.2026  2,05
AT872011184650294800   05.11.2026 15:26  0  004  1
IBAN  Datum/Date Uhrzeit/Time Belege(*)/Vouchers Auszug/Statement Seite/Page
''';

void main() {
  final categories = [
    const BudgetCategory(name: 'Lebensmittel', type: CategoryType.expense),
    const BudgetCategory(name: 'Restaurants & Cafés', type: CategoryType.expense),
    const BudgetCategory(name: 'Abos & Internet', type: CategoryType.expense),
    const BudgetCategory(name: 'Wohnen', type: CategoryType.expense),
    const BudgetCategory(name: 'Kinder', type: CategoryType.expense),
    const BudgetCategory(name: 'Bank & Gebühren', type: CategoryType.expense),
    const BudgetCategory(name: 'Kreditkarte', type: CategoryType.transfer),
    const BudgetCategory(name: 'Einnahmen', type: CategoryType.income),
  ];
  final existing = [
    BudgetEntry(date: DateTime(2026, 8, 1), category: 'Lebensmittel', description: 'Spar', amount: 20),
    BudgetEntry(date: DateTime(2026, 8, 2), category: 'Abos & Internet', description: 'Netflix', amount: 13.99),
    BudgetEntry(date: DateTime(2026, 8, 3), category: 'Wohnen', description: 'Küche Santander', amount: 197.71),
  ];

  test('rows are parsed with exact dates and amounts', () {
    final rows = StatementRows.parse(statement);
    expect(rows.length, 12);
    expect(rows.first.text, 'POS  55,25 LT K1 30.08. 13:14');
    expect(rows.first.date, DateTime(2026, 8, 31));
    expect(rows.first.amount, -55.25);
    expect(rows.first.details, ['RESTORANAS ETNO DVARAS VILNIUS 000 440']);
    expect(rows[2].amount, 2.95);
    expect(rows[2].details, ['Max Muster', 'Gesendet von Revolut']);
    expect(rows[8].amount, 2300);
    expect(rows.last.text, 'Bonus Kontoführung');
    expect(rows.last.details, isEmpty); // page footer dropped
    expect(StatementRows.looksLikeStatement(statement), isTrue);
    expect(StatementRows.looksLikeStatement('Just some OCR text 12,30'), isFalse);
  });

  test('other banks: slash dates, english amounts, sign in front, ISO dates', () {
    const other = '''
Statement
Description  Date  Amount
POS SPAR WIEN  31/08/2026  -1,234.56
Salary ACME Ltd  01/09/2026  +3,200.00
Card payment TESCO  2026-09-02  EUR 12.30-
Refund  03/09/2026  5,00
''';
    final rows = StatementRows.parse(other);
    expect(rows.length, 4);
    expect(rows[0].date, DateTime(2026, 8, 31));
    expect(rows[0].amount, -1234.56);
    expect(rows[1].amount, 3200);
    expect(rows[2].date, DateTime(2026, 9, 2));
    expect(rows[2].amount, -12.3);
    expect(rows[3].amount, 5);
  });

  test('rows become proposals: learned categories, skips, card bill, transfers', () async {
    final importer = StatementImporter(client: null, categories: categories, existing: existing, ownNames: const ['Max Muster']);
    final r = await importer.import(statement, sourceDescription: 'test');
    final p = r.proposals;
    expect(p.length, 12);
    final spar = p[1];
    expect(spar.entry.description, 'Spar');
    expect(spar.entry.category, 'Lebensmittel');
    expect(spar.entry.amount, 73.58);
    expect(spar.needsReview, isFalse);
    final restaurant = p[0];
    expect(restaurant.entry.description, 'Restoranas Etno Dvaras Vilnius');
    expect(restaurant.needsReview, isTrue); // never seen → review
    final revolut = p[2];
    expect(revolut.skipReason, 'own transfer'); // from the owner himself
    final santander = p[3];
    expect(santander.entry.description, 'Santander Consumer Bank GmbH');
    expect(santander.entry.category, 'Wohnen');
    final netflix = p[4];
    expect(netflix.entry.description, 'Netflix.com Los Gatos');
    expect(netflix.entry.category, 'Abos & Internet');
    final aws = p[5];
    expect(aws.entry.note, '99,65 USD');
    expect(p[6].skipReason, 'cash withdrawal');
    final bill = p[7];
    expect(bill.entry.category, 'Kreditkarte');
    expect(bill.entry.amount, 648.78);
    expect(bill.skipReason, isNull);
    final erika = p[8];
    expect(erika.entry.category, 'Einnahmen');
    expect(erika.entry.amount, -2300);
    expect(erika.entry.description, 'Erika Muster');
    expect(p[9].skipReason, 'own transfer');
    final fee = p[10];
    expect(fee.entry.category, 'Bank & Gebühren');
    expect(fee.entry.amount, 20.5);
    final bonus = p[11];
    expect(bonus.entry.category, 'Einnahmen');
    expect(bonus.entry.amount, -2.05);
    expect(r.notes, contains('12 rows'));
  });
}
