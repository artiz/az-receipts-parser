/// Bank statement / screenshot import.
///
/// docling.rs extracts the text (PDF text layer, or OCR of a screenshot), the
/// LLM turns it into `Buchungen` rows using the categories and the habits
/// found in the file, and the app marks what is already booked. Nothing is
/// written without the user's review.
library;

import '../budget/budget_file.dart';
import '../budget/entry_suggest.dart';
import 'openai_client.dart';

/// A row proposed by the model, before review.
class ProposedEntry {
  ProposedEntry({
    required this.entry,
    required this.confidence,
    this.alternatives = const [],
    this.question,
    this.skipReason,
    this.duplicateOf,
    this.sourceLine = '',
  });

  BudgetEntry entry;

  /// 0..1 from the model.
  final double confidence;

  /// Other plausible categories when the model is unsure.
  final List<String> alternatives;

  /// A short question for the user when the model could not decide.
  final String? question;

  /// Set when the model thinks the line is not a booking (ATM, own transfer).
  final String? skipReason;

  /// An existing entry with the same amount and a close date.
  BudgetEntry? duplicateOf;
  final String sourceLine;

  bool get isDuplicate => duplicateOf != null;
  bool get needsReview => question != null || confidence < 0.6 || alternatives.isNotEmpty;

  /// Selected for import by default?
  bool get defaultSelected => !isDuplicate && skipReason == null;
}

class StatementImportResult {
  const StatementImportResult({required this.proposals, required this.sourceDescription, this.notes = ''});
  final List<ProposedEntry> proposals;
  final String sourceDescription;
  final String notes;
}

class StatementImporter {
  StatementImporter({required this.client, required this.categories, required this.existing, DateTime? now})
      : _now = now ?? DateTime.now(),
        _suggest = EntrySuggestions(existing, now: now);

  final OpenAiClient client;
  final List<BudgetCategory> categories;

  /// Entries already in the file (plus pending), for examples and dedupe.
  final List<BudgetEntry> existing;
  final DateTime _now;
  final EntrySuggestions _suggest;

  static const int maxChars = 60000;

  /// Build the prompts (exposed for tests).
  String systemPrompt() {
    final buf = StringBuffer();
    buf.writeln('You convert bank statements, credit card statements and banking-app screenshots into rows of a household budget spreadsheet.');
    buf.writeln('Return every booking as a row with: date (YYYY-MM-DD, the booking/value date), category (exactly one of the names below), '
        'description (short, the merchant or purpose as the owner would write it: "Spar", "Miete", "Netflix", a person name for pocket money), '
        'amount (EUR, 2 decimals), note (optional: foreign amount with currency, card, reference), confidence (0..1), '
        'alternatives (other plausible categories when unsure, else empty), question (one short question for the owner when you cannot decide, else empty string), '
        'skip_reason (non-empty when the line is NOT a booking of this budget, see rules).');
    buf.writeln();
    buf.writeln('Sign convention: expenses are POSITIVE numbers, income (salary, refunds, cashback, Kindergeld, AMS, interest) is NEGATIVE and uses the income category.');
    buf.writeln('Rules:');
    buf.writeln('- Credit card statement payments ("Kreditkartenrechnung", "Zuzahlung Kreditkarte") use the transfer category for credit cards if one exists, positive amount.');
    buf.writeln('- Cash withdrawals (ATM, Bankomat, AUTOMAT) are not bookings: skip_reason "cash withdrawal".');
    buf.writeln('- Transfers between the owner\'s own accounts (savings, "transfer between my accounts", the same person name as the account owner, business account "Privateinlage") are not bookings: skip_reason "own transfer".');
    buf.writeln('- Transfers to family members: use the pocket-money/children category if the file has one; if unsure set a question.');
    buf.writeln('- Account fees and bank charges go to the bank-fees category; their refunds ("Bonus Kontoführung") are income.');
    buf.writeln('- Keep every booking, do not merge lines. Ignore running balances, headers, footers and page numbers.');
    buf.writeln('- Dates: if the statement shows day.month.year use that; keep the year from the statement.');
    buf.writeln();
    buf.writeln('Categories (name — type — hint — examples of descriptions already used):');
    for (final c in categories) {
      final examples = _suggest.descriptions(c.name, limit: 8).map((d) => d.description).join(', ');
      final type = switch (c.type) {
        CategoryType.income => 'income',
        CategoryType.transfer => 'transfer (not an expense)',
        CategoryType.expense => 'expense',
      };
      buf.writeln('- ${c.name} — $type${c.hint.isEmpty ? '' : ' — ${c.hint}'}${examples.isEmpty ? '' : ' — e.g. $examples'}');
    }
    return buf.toString();
  }

  static Map<String, dynamic> schema() => {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'rows': {
            'type': 'array',
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'date': {'type': 'string'},
                'category': {'type': 'string'},
                'description': {'type': 'string'},
                'amount': {'type': 'number'},
                'note': {'type': 'string'},
                'confidence': {'type': 'number'},
                'alternatives': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'question': {'type': 'string'},
                'skip_reason': {'type': 'string'},
                'source': {'type': 'string'},
              },
              'required': ['date', 'category', 'description', 'amount', 'note', 'confidence', 'alternatives', 'question', 'skip_reason', 'source'],
            },
          },
          'notes': {'type': 'string'},
        },
        'required': ['rows', 'notes'],
      };

  /// Run the model on extracted text and post-process the rows.
  Future<StatementImportResult> import(String text, {required String sourceDescription}) async {
    var body = text.trim();
    if (body.isEmpty) throw OpenAiException('no text to import');
    if (body.length > maxChars) body = body.substring(0, maxChars);
    final json = await client.completeJson(
      system: systemPrompt(),
      user: 'Today is ${_now.toIso8601String().substring(0, 10)}. Source: $sourceDescription.\n\n$body',
      schema: schema(),
      schemaName: 'budget_rows',
    );
    return parseResponse(json, sourceDescription: sourceDescription);
  }

  /// Turn the model's JSON into proposals, validate categories, find
  /// duplicates (exposed for tests).
  StatementImportResult parseResponse(Map<String, dynamic> json, {required String sourceDescription}) {
    final rows = (json['rows'] as List<dynamic>? ?? const []);
    final names = categories.map((c) => c.name).toList();
    final proposals = <ProposedEntry>[];
    for (final raw in rows) {
      final m = raw as Map<String, dynamic>;
      final date = DateTime.tryParse((m['date'] as String?) ?? '') ?? _now;
      var category = (m['category'] as String?) ?? '';
      var confidence = ((m['confidence'] as num?) ?? 0.5).toDouble().clamp(0, 1).toDouble();
      final alternatives = [
        for (final a in (m['alternatives'] as List<dynamic>? ?? const []))
          if (a is String && names.contains(a) && a != category) a,
      ];
      String? question = (m['question'] as String?)?.trim();
      if (question != null && question.isEmpty) question = null;
      String? skip = (m['skip_reason'] as String?)?.trim();
      if (skip != null && skip.isEmpty) skip = null;
      if (!names.contains(category)) {
        // Unknown category: fall back to what the file knows about this description.
        final learned = _suggest.categoryFor((m['description'] as String?) ?? '');
        category = learned ?? _closestName(category, names) ?? (names.isEmpty ? category : names.last);
        confidence = confidence < 0.5 ? confidence : 0.5;
        question ??= 'Kategorie?';
      }
      var amount = ((m['amount'] as num?) ?? 0).toDouble();
      final cat = categories.where((c) => c.name == category).firstOrNull;
      if (cat != null) {
        // Enforce the sign convention of the file.
        if (cat.isIncome && amount > 0) amount = -amount;
        if (!cat.isIncome && amount < 0 && !cat.isTransfer) amount = -amount;
      }
      final entry = BudgetEntry(
        date: DateTime(date.year, date.month, date.day),
        category: category,
        description: ((m['description'] as String?) ?? '').trim(),
        amount: (amount * 100).round() / 100,
        note: ((m['note'] as String?) ?? '').trim(),
      );
      proposals.add(ProposedEntry(
        entry: entry,
        confidence: confidence,
        alternatives: alternatives,
        question: question,
        skipReason: skip,
        sourceLine: ((m['source'] as String?) ?? '').trim(),
      ));
    }
    markDuplicates(proposals, existing);
    return StatementImportResult(proposals: proposals, sourceDescription: sourceDescription, notes: (json['notes'] as String?) ?? '');
  }

  /// Same amount (±0.01) within [days] of an existing entry → duplicate.
  /// Each existing entry is matched at most once.
  static void markDuplicates(List<ProposedEntry> proposals, List<BudgetEntry> existing, {int days = 5}) {
    final used = <BudgetEntry>{};
    for (final p in proposals) {
      if (p.skipReason != null) continue;
      BudgetEntry? best;
      var bestDays = days + 1;
      for (final e in existing) {
        if (used.contains(e)) continue;
        if ((e.amount - p.entry.amount).abs() > 0.011) continue;
        final d = (e.date.difference(p.entry.date).inDays).abs();
        if (d <= days && d < bestDays) {
          best = e;
          bestDays = d;
        }
      }
      if (best != null) {
        used.add(best);
        p.duplicateOf = best;
      }
    }
  }

  static String? _closestName(String wanted, List<String> names) {
    final w = wanted.toLowerCase();
    for (final n in names) {
      if (n.toLowerCase() == w) return n;
    }
    for (final n in names) {
      if (n.toLowerCase().contains(w) || w.contains(n.toLowerCase())) return n;
    }
    return null;
  }
}
