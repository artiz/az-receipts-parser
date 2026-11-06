/// Splitting a scanned receipt into one booking per category: each item is
/// assigned a category, the amounts are summed per category and the items
/// go into that booking's note. A difference between the receipt total and
/// the items' sum (rounding, an unparsed line) stays with the main category.
library;

import 'budget_file.dart';

class ReceiptItemDraft {
  const ReceiptItemDraft({required this.name, required this.amount});
  final String name;
  final double amount;
}

String _money(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

/// [assignments]: category per item (same length as [items]); [main] is
/// the category of the booking that also takes the remainder. Returns one
/// entry per category, the main one first; categories without items are
/// left out. [extraNote] (a receipt link) is appended to every note.
List<BudgetEntry> splitReceipt({
  required DateTime date,
  required String description,
  required double total,
  required List<ReceiptItemDraft> items,
  required List<String> assignments,
  required String main,
  String extraNote = '',
}) {
  final byCategory = <String, List<ReceiptItemDraft>>{};
  for (var i = 0; i < items.length; i++) {
    byCategory.putIfAbsent(assignments[i], () => []).add(items[i]);
  }
  final order = [main, ...byCategory.keys.where((c) => c != main)];
  final sums = {for (final c in order) c: (byCategory[c] ?? const []).fold(0.0, (s, i) => s + i.amount)};
  final itemsSum = sums.values.fold(0.0, (s, v) => s + v);
  final remainder = ((total - itemsSum) * 100).round() / 100;
  final out = <BudgetEntry>[];
  for (final c in order) {
    final list = byCategory[c] ?? const <ReceiptItemDraft>[];
    var amount = sums[c]!;
    if (c == main) amount += remainder;
    amount = (amount * 100).round() / 100;
    if (list.isEmpty && amount == 0) continue;
    final lines = [for (final i in list) '${i.name} ${_money(i.amount)}', if (c == main && remainder != 0) '… ${_money(remainder)}', if (extraNote.isNotEmpty) extraNote];
    out.add(BudgetEntry(date: date, category: c, description: description, amount: amount, note: lines.join('\n')));
  }
  return out;
}
