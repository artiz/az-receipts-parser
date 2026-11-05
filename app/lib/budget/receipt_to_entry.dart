/// A scanned receipt becomes one `Buchungen` row: the merchant as
/// description, the total as amount, the line items in the note. The
/// category comes first from the file's own history for that merchant, then
/// from the built-in merchant rules mapped onto the file's categories.
library;

import '../categorize/categorizer.dart';
import '../core/money.dart';
import '../parser/parsed_receipt.dart';
import '../ui/entry_sheet.dart';
import 'budget_file.dart';
import 'entry_suggest.dart';

/// Built-in rule keys → the file category names they usually correspond to
/// (first match that exists in the file wins). Only a fallback for merchants
/// the file has never seen.
const Map<String, List<String>> _ruleToCategoryNames = {
  'groceries': ['Lebensmittel', 'Groceries'],
  'bakery': ['Lebensmittel', 'Groceries'],
  'drugstore': ['Haushalt', 'Household'],
  'pharmacy': ['Gesundheit', 'Health'],
  'household': ['Haushalt', 'Household'],
  'clothing': ['Kleidung', 'Clothing'],
  'toys': ['Kinder', 'Kids'],
  'electronics': ['Haushalt', 'Household'],
  'books': ['Schulung', 'Education'],
  'sports': ['Freizeit & Reisen', 'Freizeit', 'Leisure'],
  'diy': ['Haushalt', 'Wohnen', 'Household'],
  'restaurant': ['Restaurants & Cafés', 'Restaurants', 'Restaurant'],
  'fuel': ['Transport'],
  'transport': ['Transport'],
  'pets': ['Sonstiges', 'Other'],
  'health': ['Gesundheit', 'Health'],
  'entertainment': ['Freizeit & Reisen', 'Freizeit', 'Leisure'],
  'other': ['Sonstiges', 'Other'],
};

String? mapRuleCategory(String? ruleKey, List<BudgetCategory> categories) {
  if (ruleKey == null) return null;
  final names = _ruleToCategoryNames[ruleKey] ?? const [];
  for (final n in names) {
    for (final c in categories) {
      if (c.name.toLowerCase() == n.toLowerCase()) return c.name;
    }
  }
  return null;
}

/// Items as "name 1,29; name 2,49" for the note, capped so the cell stays
/// readable.
String itemsNote(ParsedReceipt r, {int maxChars = 240}) {
  final parts = <String>[];
  for (final i in r.items) {
    final q = i.quantity != 1 ? '${_q(i.quantity)}× ' : '';
    parts.add('$q${i.name} ${formatCents(i.totalCents)}');
  }
  var note = parts.join('; ');
  if (note.length > maxChars) note = '${note.substring(0, maxChars - 1).trimRight()}…';
  return note;
}

String _q(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

EntryDraft receiptToDraft(ParsedReceipt r, {required List<BudgetCategory> categories, required EntrySuggestions suggestions, Categorizer? categorizer}) {
  final merchant = (r.merchant ?? r.merchantRaw ?? '').trim();
  String? category = merchant.isEmpty ? null : suggestions.categoryFor(merchant);
  category ??= mapRuleCategory((categorizer ?? Categorizer()).categorizeMerchant(merchant), categories);
  if (category == null) {
    final byUse = suggestions.categoriesByUse(categories.where((c) => c.isExpense).map((c) => c.name));
    category = byUse.isEmpty ? null : byUse.first;
  }
  final total = r.totalCents ?? r.itemsSumCents;
  return EntryDraft(
    date: r.purchasedAt,
    category: category,
    description: merchant,
    amount: total == 0 ? null : total.abs() / 100,
    note: itemsNote(r),
  );
}
