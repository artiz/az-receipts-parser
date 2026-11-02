/// Money helpers. Amounts are stored as integer cents to avoid float drift.
library;

final RegExp _amountRe = RegExp(r'(-?)\s*(\d{1,6})[.,](\d{2})(?!\d)(?!\s*%)');

/// Parse a receipt amount such as `6,30`, `€ 5,99`, `5.99 €`, `-6,30`.
/// A number followed by `%` (a VAT rate) is never an amount.
/// Returns cents, or null when no amount is present.
int? parseCents(String text) {
  final m = _amountRe.firstMatch(text);
  if (m == null) return null;
  final sign = m.group(1) == '-' ? -1 : 1;
  final whole = int.parse(m.group(2)!);
  final frac = int.parse(m.group(3)!);
  return sign * (whole * 100 + frac);
}

/// Every amount in the string, left to right.
List<int> parseAllCents(String text) => _amountRe
    .allMatches(text)
    .map((m) =>
        (m.group(1) == '-' ? -1 : 1) *
        (int.parse(m.group(2)!) * 100 + int.parse(m.group(3)!)))
    .toList();

/// Format cents as `6,30` (German decimal comma) or `6.30`.
String formatCents(int cents, {bool comma = true, String? currency}) {
  final neg = cents < 0;
  final abs = cents.abs();
  final s = '${abs ~/ 100}${comma ? ',' : '.'}${(abs % 100).toString().padLeft(2, '0')}';
  final body = neg ? '-$s' : s;
  return currency == null ? body : '$body $currency';
}

/// Parse `2 x 1,89` / `2x1,89` / `= 2 x 1,89` / `3 Stk x 0,99`.
({double quantity, int unitCents})? parseQuantityLine(String text) {
  final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:kg|g|l|ml|stk|st|pcs|stueck|stück)?\s*(?:stk|st|x|×|\*)\s*(?:[a-z]*\s*)?(-?\d{1,6}[.,]\d{2})(?!\d)',
          caseSensitive: false)
      .firstMatch(text);
  if (m == null) return null;
  final q = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  final unit = parseCents(m.group(2)!);
  if (q == null || unit == null) return null;
  return (quantity: q, unitCents: unit);
}
