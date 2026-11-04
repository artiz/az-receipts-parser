/// Parser output, independent of the database.
library;

enum PaymentMethod { cash, card, unknown }

class ParsedItem {
  ParsedItem({
    required this.name,
    required this.totalCents,
    this.quantity = 1,
    this.unitCents,
    this.vatRate,
    this.categoryKey,
    this.confidence = 1,
  });

  String name;
  int totalCents;
  double quantity;
  int? unitCents;
  double? vatRate;
  String? categoryKey;
  double confidence;

  @override
  String toString() => 'ParsedItem($name, $totalCents, q=$quantity, cat=$categoryKey)';
}

class ParsedVat {
  ParsedVat({required this.rate, this.netCents, this.vatCents, this.grossCents});
  final double rate;
  final int? netCents;
  final int? vatCents;
  final int? grossCents;

  @override
  String toString() => 'Vat($rate%: net=$netCents vat=$vatCents gross=$grossCents)';
}

class ParsedReceipt {
  ParsedReceipt({
    this.merchant,
    this.merchantRaw,
    this.address,
    this.purchasedAt,
    this.totalCents,
    this.currency = 'EUR',
    this.payment = PaymentMethod.unknown,
    List<ParsedItem>? items,
    List<ParsedVat>? vat,
    this.qrText,
    this.rksvKassenId,
    this.rksvBelegNummer,
    this.categoryKey,
    this.confidence = 0,
    List<String>? warnings,
  })  : items = items ?? [],
        vat = vat ?? [],
        warnings = warnings ?? [];

  String? merchant;
  String? merchantRaw;
  String? address;
  DateTime? purchasedAt;
  int? totalCents;
  String currency;
  PaymentMethod payment;
  List<ParsedItem> items;
  List<ParsedVat> vat;
  String? qrText;
  String? rksvKassenId;
  String? rksvBelegNummer;
  String? categoryKey;

  /// 0..1 overall trust in the extracted fields.
  double confidence;
  List<String> warnings;

  int get itemsSumCents => items.fold(0, (a, i) => a + i.totalCents);
}
