import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/import/openai_client.dart';
import 'package:az_budget/import/statement_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = [
    const BudgetCategory(name: 'Lebensmittel', type: CategoryType.expense, hint: 'Supermarkt'),
    const BudgetCategory(name: 'Kinder', type: CategoryType.expense),
    const BudgetCategory(name: 'Bank & Gebühren', type: CategoryType.expense),
    const BudgetCategory(name: 'Kreditkarte', type: CategoryType.transfer),
    const BudgetCategory(name: 'Einnahmen', type: CategoryType.income),
  ];
  final existing = [
    BudgetEntry(date: DateTime(2026, 2, 3), category: 'Lebensmittel', description: 'Spar', amount: 45.68),
    BudgetEntry(date: DateTime(2026, 2, 5), category: 'Lebensmittel', description: 'Spar', amount: 12.3),
    BudgetEntry(date: DateTime(2026, 2, 6), category: 'Kinder', description: 'Marina', amount: 10),
  ];
  final importer = StatementImporter(
    client: OpenAiClient(apiKey: 'x', model: 'gpt-4.1-mini'),
    categories: categories,
    existing: existing,
    now: DateTime(2026, 3, 1),
  );

  test('system prompt lists the file categories with examples', () {
    final p = importer.systemPrompt();
    expect(p, contains('- Lebensmittel — expense — Supermarkt — e.g. Spar'));
    expect(p, contains('- Kreditkarte — transfer (not an expense)'));
    expect(p, contains('- Einnahmen — income'));
    expect(p, contains('NEGATIVE'));
  });

  test('schema is strict and complete', () {
    final s = StatementImporter.schema();
    expect(s['required'], ['rows', 'notes']);
    final item = (s['properties'] as Map)['rows']['items'] as Map;
    expect(item['additionalProperties'], false);
    expect((item['required'] as List).length, (item['properties'] as Map).length);
  });

  test('parses rows, enforces signs, validates categories, marks duplicates', () {
    final json = {
      'notes': '',
      'rows': [
        {'date': '2026-02-04', 'category': 'Lebensmittel', 'description': 'INTERSPAR', 'amount': 45.68, 'note': '', 'confidence': 0.9, 'alternatives': [], 'question': '', 'skip_reason': '', 'source': ''},
        {'date': '2026-02-10', 'category': 'Einnahmen', 'description': 'Kindergeld', 'amount': 502.6, 'note': '', 'confidence': 0.95, 'alternatives': [], 'question': '', 'skip_reason': '', 'source': ''},
        {'date': '2026-02-11', 'category': 'Geschenke', 'description': 'Marina', 'amount': -20, 'note': '', 'confidence': 0.4, 'alternatives': ['Kinder'], 'question': 'Taschengeld oder Geschenk?', 'skip_reason': '', 'source': ''},
        {'date': '2026-02-12', 'category': 'Bank & Gebühren', 'description': 'ATM', 'amount': 100, 'note': '', 'confidence': 0.9, 'alternatives': [], 'question': '', 'skip_reason': 'cash withdrawal', 'source': ''},
        {'date': '2026-02-20', 'category': 'Kreditkarte', 'description': 'Kreditkartenrechnung Jan. 2026', 'amount': 1825.52, 'note': '', 'confidence': 0.99, 'alternatives': [], 'question': '', 'skip_reason': '', 'source': ''},
      ],
    };
    final r = importer.parseResponse(json, sourceDescription: 'test');
    expect(r.proposals.length, 5);
    final spar = r.proposals[0];
    expect(spar.isDuplicate, isTrue);
    expect(spar.duplicateOf!.row, isNull);
    expect(spar.duplicateOf!.description, 'Spar');
    expect(spar.defaultSelected, isFalse);
    final kg = r.proposals[1];
    expect(kg.entry.amount, -502.6);
    expect(kg.defaultSelected, isTrue);
    final marina = r.proposals[2];
    // Unknown category: learned from the file ("Marina" → Kinder), flagged.
    expect(marina.entry.category, 'Kinder');
    expect(marina.entry.amount, 20);
    expect(marina.needsReview, isTrue);
    expect(marina.question, isNotNull);
    final atm = r.proposals[3];
    expect(atm.skipReason, 'cash withdrawal');
    expect(atm.defaultSelected, isFalse);
    final card = r.proposals[4];
    expect(card.entry.category, 'Kreditkarte');
    expect(card.entry.amount, 1825.52);
    expect(card.needsReview, isFalse);
  });

  test('long texts are split at line ends', () {
    final text = List.generate(300, (i) => 'line $i with some statement text 12,34-').join('\n');
    final chunks = StatementImporter.splitChunks(text, 2000);
    expect(chunks.length, greaterThan(3));
    expect(chunks.every((c) => c.length <= 2000), isTrue);
    expect(chunks.join(''), '$text\n');
    expect(StatementImporter.splitChunks('short', 2000), ['short']);
  });

  test('duplicate matching uses each existing entry once', () {
    final p = [
      ProposedEntry(entry: BudgetEntry(date: DateTime(2026, 2, 4), category: 'Kinder', description: 'a', amount: 10), confidence: 1),
      ProposedEntry(entry: BudgetEntry(date: DateTime(2026, 2, 7), category: 'Kinder', description: 'b', amount: 10), confidence: 1),
      ProposedEntry(entry: BudgetEntry(date: DateTime(2026, 2, 20), category: 'Kinder', description: 'c', amount: 10), confidence: 1),
    ];
    StatementImporter.markDuplicates(p, existing);
    expect(p[0].isDuplicate, isTrue);
    expect(p[1].isDuplicate, isFalse);
    expect(p[2].isDuplicate, isFalse);
  });
}
