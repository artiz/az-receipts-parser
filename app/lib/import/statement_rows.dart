/// Deterministic parsing of a bank statement that docling.rs turned into
/// layout rows ("text  value date  amount"). Dates and amounts come straight
/// from the statement, so nothing is invented or dropped; only the category
/// (and a readable merchant name) is guessed, first from the file's own
/// history, then optionally by the model.
library;

import '../budget/budget_file.dart';
import '../budget/entry_suggest.dart';
import '../core/text_normalize.dart';
import 'statement_import.dart';

/// One booking as printed: the header row plus its detail lines.
class RawBooking {
  RawBooking({required this.text, required this.date, required this.amount, List<String>? details})
      : details = details ?? [];

  /// First row, without date and amount ("SPAR  2362 K1 31.08. 19:13").
  final String text;
  final DateTime date;

  /// Signed as the bank shows it: debits negative, credits positive.
  final double amount;
  final List<String> details;

  String get all => [text, ...details].join('\n');
}

class StatementRows {
  StatementRows._();

  /// A booking row: text, two or more spaces, a date, two or more spaces, an
  /// amount at the end. Dates: 31.08.2026, 31/08/2026, 2026-08-31. Amounts:
  /// 1.234,56 / 1,234.56 / 1234.56, sign before or after, optional EUR/€.
  static final _booking = RegExp(
    r'^(.*?)\s{2,}(\d{1,2}[./]\d{1,2}[./]\d{4}|\d{4}-\d{2}-\d{2})\s{2,}(?:EUR|€)?\s*([-+]?)\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?)\s*(?:EUR|€)?\s*([-+]?)\s*$',
  );

  static DateTime? _date(String s) {
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (iso != null) return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    final dmy = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$').firstMatch(s);
    if (dmy == null) return null;
    final d = int.parse(dmy.group(1)!), m = int.parse(dmy.group(2)!), y = int.parse(dmy.group(3)!);
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  /// "1.234,56" → 1234.56, "1,234.56" → 1234.56, "1234.56" → 1234.56.
  static double? _amount(String s) {
    var t = s;
    final lastComma = t.lastIndexOf(',');
    final lastDot = t.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      t = lastComma > lastDot ? t.replaceAll('.', '').replaceAll(',', '.') : t.replaceAll(',', '');
    } else if (lastComma >= 0) {
      // "1,234" is a thousands group only when exactly three digits follow and no decimals exist.
      t = RegExp(r',\d{3}$').hasMatch(t) && t.indexOf(',') == lastComma && t.length - lastComma == 4 && t.length > 5 ? t.replaceAll(',', '') : t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }
  static final _pageNoise = RegExp(
    r'^(Erste Bank|Sparkassen AG|Am Belvedere|1100 Wien|Kontoauszug|Account Statement|Buchungstext|IBAN|Datum/Date|Old Balance|New Balance|Credits|Debits|Alter Kontostand|Neuer Kontostand|Gutschriften|Belastungen|last valid account name|Zuletzt g|AT\d\d\d\d|Seite/Page|\s*$)',
  );

  /// Bookings in statement order. Lines that belong to no booking (page
  /// headers) are dropped; detail lines are attached to the booking above.
  static List<RawBooking> parse(String text) {
    final out = <RawBooking>[];
    RawBooking? current;
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      final m = _booking.firstMatch(line);
      if (m != null) {
        final date = _date(m.group(2)!);
        final value = _amount(m.group(4)!);
        if (date != null && value != null) {
          final negative = m.group(3) == '-' || m.group(5) == '-';
          current = RawBooking(text: m.group(1)!.trim(), date: date, amount: negative ? -value : value);
          out.add(current);
          continue;
        }
      }
      if (current == null) continue;
      final t = line.trim();
      if (t.isEmpty || t.startsWith('\x0c')) {
        // A page break ends the detail block.
        if (t.startsWith('\x0c')) current = null;
        continue;
      }
      if (_pageNoise.hasMatch(t)) {
        current = null;
        continue;
      }
      if (t.startsWith('MDID:') || t.startsWith('CNR/') || t.startsWith('NOTPROVIDED')) continue;
      current.details.add(t);
    }
    return out;
  }

  /// Does this text look like a statement we can read row by row? Three
  /// bookings is enough to trust it.
  static bool looksLikeStatement(String text) => parse(text).length >= 3;
}

/// Kinds a booking row can be recognised as without any model.
enum RowKind { purchase, cash, cardBill, ownTransfer, bankFee, transfer, income, other }

class ClassifiedRow {
  ClassifiedRow({required this.raw, required this.kind, required this.description, this.note = ''});
  final RawBooking raw;
  final RowKind kind;
  final String description;
  final String note;
}

/// Turns raw bookings into proposals using the file's categories and
/// history. Rows whose category stays unknown are flagged for review (or
/// for the model, see [StatementImporter]).
class StatementRowClassifier {
  StatementRowClassifier({required this.categories, required this.existing, this.ownNames = const []})
      : _suggest = EntrySuggestions(existing);

  final List<BudgetCategory> categories;
  final List<BudgetEntry> existing;

  /// Names of the account owners: transfers between them are not bookings.
  final List<String> ownNames;
  final EntrySuggestions _suggest;

  static final _cardHeader = RegExp(r'^(E-COMM|POS|ATM|AUTOMAT)\b', caseSensitive: false);
  static final _terminal = RegExp(r'^(.*?)\s+\d{4,}\s+K\d\s+\d\d\.\d\d\.\s+\d\d:\d\d');
  static final _foreign = RegExp(r'^(?:E-COMM|POS)\s+([\d.,]+)\s+([A-Z]{3})\s+K\d', caseSensitive: false);
  static final _amazon = RegExp(r'\b(AMZN|Amazon)\b', caseSensitive: false);

  ClassifiedRow classify(RawBooking b) {
    final text = b.text;
    final all = b.all;
    final lower = all.toLowerCase();
    if (RegExp(r'^(ATM|AUTOMAT)\b', caseSensitive: false).hasMatch(text)) {
      return ClassifiedRow(raw: b, kind: RowKind.cash, description: 'Bankomat');
    }
    if (lower.contains('kreditkartenrechnung') || lower.contains('zuzahlung s kreditkarte') || lower.contains('zuzahlung kreditkarte')) {
      return ClassifiedRow(raw: b, kind: RowKind.cardBill, description: text.replaceFirst(RegExp(r'^s\s+'), '').trim());
    }
    if (lower.contains('transfer between my') || lower.contains('privateinlage') || lower.contains('sparkonto')) {
      return ClassifiedRow(raw: b, kind: RowKind.ownTransfer, description: text);
    }
    if (RegExp(r'^(Kontoführung|Bonus Kontoführung|Habenzinsen|Sollzinsen|Bereitstellung|Entgelt|Spesen)', caseSensitive: false).hasMatch(text)) {
      return ClassifiedRow(raw: b, kind: b.amount > 0 ? RowKind.income : RowKind.bankFee, description: text);
    }
    if (RegExp(r'^(George-Überweisung|George-Transfer|Überweisung|Gesendet von|Eingang|Gutschrift)', caseSensitive: false).hasMatch(text) ||
        RegExp(r'^[A-ZÄÖÜ][a-zäöüß]+ [A-ZÄÖÜ][a-zäöüß]+', caseSensitive: true).hasMatch(text) && b.details.isNotEmpty && !_cardHeader.hasMatch(text)) {
      // Person-to-person: the counterparty is the detail or the header itself.
      final who = b.details.where((d) => !d.startsWith('George') && !d.startsWith('Gesendet')).map((d) => d.trim()).firstWhere((d) => d.isNotEmpty, orElse: () => text);
      final name = _cardHeader.hasMatch(text) ? text : (RegExp(r'^(George|Überweisung|Gesendet|Eingang|Gutschrift)', caseSensitive: false).hasMatch(text) ? who : text);
      final own = ownNames.any((n) => normalize(all).contains(normalize(n)));
      if (own) return ClassifiedRow(raw: b, kind: RowKind.ownTransfer, description: name);
      final purpose = b.details.where((d) => d != who && !d.startsWith('George') && !d.startsWith('Gesendet')).join(' ');
      return ClassifiedRow(raw: b, kind: b.amount > 0 ? RowKind.income : RowKind.transfer, description: name, note: purpose);
    }
    // Card purchases and direct debits.
    String description;
    var note = '';
    final f = _foreign.firstMatch(text);
    if (f != null) note = '${f.group(1)} ${f.group(2)}';
    final term = _terminal.firstMatch(text);
    if (_cardHeader.hasMatch(text)) {
      description = b.details.isNotEmpty ? _merchant(b.details.first) : text;
    } else if (term != null) {
      description = _merchant(term.group(1)!);
    } else if (_amazon.hasMatch(all)) {
      description = 'Amazon';
    } else {
      final company = b.details.firstWhere((d) => RegExp(r'(GmbH|AG\b|Versicherung|GesmbH|KG\b|e\.V\.|Ltd|Inc)').hasMatch(d), orElse: () => '');
      // A bare reference number as header ("000236183960"): the payee is on the next line.
      final headerIsRef = RegExp(r'^[\d\-/ .]+$').hasMatch(text);
      description = company.isNotEmpty
          ? _merchant(company)
          : (headerIsRef && b.details.isNotEmpty ? _merchant(b.details.first) : _merchant(text));
    }
    return ClassifiedRow(raw: b, kind: b.amount > 0 ? RowKind.income : RowKind.purchase, description: description, note: note);
  }

  /// "NETFLIX.COM LOS GATOS 1072AB 528" → "Netflix.com Los Gatos";
  /// "SPAR" stays "Spar"; tokens with digits end the name.
  static String _merchant(String s) {
    final words = <String>[];
    for (final w in s.trim().split(RegExp(r'\s+'))) {
      if (RegExp(r'\d{2,}').hasMatch(w) || w == '*') break;
      words.add(w);
    }
    var name = words.join(' ').replaceAll(RegExp(r'[*]+'), ' ').trim();
    if (name.isEmpty) name = s.trim();
    if (name == name.toUpperCase() && name.length > 3) {
      name = name.split(' ').map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase()).join(' ');
    }
    return name;
  }

  String? _categoryNamed(bool Function(BudgetCategory) test) {
    for (final c in categories) {
      if (test(c)) return c.name;
    }
    return null;
  }

  /// Proposals for all bookings; [unknown] receives the indexes whose
  /// category could not be learned.
  List<ProposedEntry> propose(List<RawBooking> bookings, {List<int>? unknown}) {
    final income = _categoryNamed((c) => c.isIncome);
    final card = _categoryNamed((c) => c.isTransfer && RegExp('kredit|credit|кредит').hasMatch(c.name.toLowerCase())) ?? _categoryNamed((c) => c.isTransfer);
    final bank = _categoryNamed((c) => c.name.toLowerCase().startsWith('bank'));
    final fallback = _suggest.categoriesByUse(categories.where((c) => c.isExpense).map((c) => c.name)).firstOrNull ?? categories.first.name;
    final out = <ProposedEntry>[];
    for (var i = 0; i < bookings.length; i++) {
      final r = classify(bookings[i]);
      final b = r.raw;
      final abs = (b.amount.abs() * 100).round() / 100;
      String category;
      var confidence = 1.0;
      String? skip;
      String? question;
      switch (r.kind) {
        case RowKind.cash:
          category = bank ?? fallback;
          skip = 'cash withdrawal';
        case RowKind.ownTransfer:
          category = bank ?? fallback;
          skip = 'own transfer';
        case RowKind.cardBill:
          category = card ?? bank ?? fallback;
          if (card == null) skip = 'credit card bill';
        case RowKind.bankFee:
          category = bank ?? fallback;
          if (bank == null) {
            confidence = 0.4;
            question = 'Kategorie?';
          }
        case RowKind.income:
          category = income ?? fallback;
        case RowKind.transfer:
          final learned = _suggest.categoryFor(r.description);
          category = learned ?? fallback;
          confidence = learned != null ? 0.8 : 0.3;
          if (learned == null) question = 'Überweisung an ${r.description}: Kategorie?';
        case RowKind.purchase:
        case RowKind.other:
          final learned = _suggest.categoryFor(r.description) ?? _suggest.categoryFor(b.text);
          category = learned ?? fallback;
          if (learned == null) {
            confidence = 0.3;
            question = 'Kategorie?';
            unknown?.add(i);
          }
      }
      final isIncomeCat = categories.any((c) => c.name == category && c.isIncome);
      final signed = isIncomeCat ? -abs : abs;
      out.add(ProposedEntry(
        entry: BudgetEntry(date: b.date, category: category, description: r.description, amount: signed, note: r.note),
        confidence: confidence,
        question: question,
        skipReason: skip,
        sourceLine: b.text,
      ));
    }
    return out;
  }
}
