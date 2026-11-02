/// Persistence + queries on top of [AppDatabase]; also the bridge between the
/// pure parser/categoriser and the stored rules.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../categorize/categorizer.dart';
import '../core/money.dart';
import '../parser/parsed_receipt.dart';
import 'database.dart';

class ReceiptWithItems {
  ReceiptWithItems(this.receipt, this.items, this.vat);
  final Receipt receipt;
  final List<ReceiptItem> items;
  final List<ReceiptVatData> vat;
}

class CategoryTotal {
  CategoryTotal(this.categoryKey, this.cents, this.count);
  final String categoryKey;
  final int cents;
  final int count;
}

class MerchantTotal {
  MerchantTotal(this.merchant, this.cents, this.count);
  final String merchant;
  final int cents;
  final int count;
}

class ReceiptRepository {
  ReceiptRepository(this.db);

  final AppDatabase db;

  // --- rules / categoriser ---------------------------------------------------

  Future<Categorizer> loadCategorizer() async {
    final m = await db.select(db.merchantRules).get();
    final k = await db.select(db.keywordRules).get();
    return Categorizer(
      merchantRules: [
        for (final r in m)
          MerchantRule(r.pattern, r.categoryKey,
              source: r.source == 'learned' ? RuleSource.learned : RuleSource.seed),
      ],
      keywordRules: [
        for (final r in k)
          KeywordRule(r.keyword, r.categoryKey,
              source: r.source == 'learned' ? RuleSource.learned : RuleSource.seed),
      ],
    );
  }

  /// The user re-categorised an item: remember the item name as a keyword.
  Future<void> learnItemCategory(String itemName, String categoryKey) async {
    final keyword = Categorizer.learnKeywordFor(itemName);
    if (keyword.length < 3) return;
    await db.into(db.keywordRules).insert(
          KeywordRulesCompanion.insert(keyword: keyword, categoryKey: categoryKey, source: const Value('learned')),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// The user re-categorised a receipt: remember the merchant.
  Future<void> learnMerchantCategory(String merchant, String categoryKey) async {
    final pattern = Categorizer.learnMerchantPatternFor(merchant);
    if (pattern.length < 2) return;
    await db.into(db.merchantRules).insert(
          MerchantRulesCompanion.insert(pattern: pattern, categoryKey: categoryKey, source: const Value('learned')),
          mode: InsertMode.insertOrReplace,
        );
  }

  Stream<List<MerchantRule>> watchMerchantRules() => db.select(db.merchantRules).watch().map((rows) => [
        for (final r in rows)
          MerchantRule(r.pattern, r.categoryKey, source: r.source == 'learned' ? RuleSource.learned : RuleSource.seed),
      ]);

  Stream<List<KeywordRule>> watchKeywordRules() => db.select(db.keywordRules).watch().map((rows) => [
        for (final r in rows)
          KeywordRule(r.keyword, r.categoryKey, source: r.source == 'learned' ? RuleSource.learned : RuleSource.seed),
      ]);

  Future<void> deleteMerchantRule(String pattern) =>
      (db.delete(db.merchantRules)..where((t) => t.pattern.equals(pattern))).go();

  Future<void> deleteKeywordRule(String keyword) =>
      (db.delete(db.keywordRules)..where((t) => t.keyword.equals(keyword))).go();

  // --- categories -----------------------------------------------------------

  Stream<List<Category>> watchCategories() =>
      (db.select(db.categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<Category>> categories() =>
      (db.select(db.categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<void> addCustomCategory(String key, String name) async {
    final count = await db.categories.count().getSingle();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            key: key,
            customName: Value(name),
            sortOrder: Value(count),
            builtin: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // --- receipts -------------------------------------------------------------

  Future<int> saveParsed(ParsedReceipt p, {String? imagePath, String? ocrJson}) async {
    return db.transaction(() async {
      final id = await db.into(db.receipts).insert(ReceiptsCompanion.insert(
            merchant: Value(p.merchant),
            merchantRaw: Value(p.merchantRaw),
            address: Value(p.address),
            purchasedAt: p.purchasedAt ?? DateTime.now(),
            totalCents: p.totalCents ?? p.itemsSumCents,
            currency: Value(p.currency),
            payment: Value(p.payment.name),
            categoryKey: p.categoryKey ?? 'other',
            imagePath: Value(imagePath),
            ocrJson: Value(ocrJson),
            qrText: Value(p.qrText),
            rksvKassenId: Value(p.rksvKassenId),
            rksvBelegNummer: Value(p.rksvBelegNummer),
            confidence: Value(p.confidence),
            warnings: Value(p.warnings.isEmpty ? null : p.warnings.join(',')),
          ));
      await _replaceItems(id, p.items);
      await _replaceVat(id, p.vat);
      return id;
    });
  }

  Future<void> _replaceItems(int receiptId, List<ParsedItem> items) async {
    await (db.delete(db.receiptItems)..where((t) => t.receiptId.equals(receiptId))).go();
    var order = 0;
    for (final it in items) {
      await db.into(db.receiptItems).insert(ReceiptItemsCompanion.insert(
            receiptId: receiptId,
            name: it.name,
            quantity: Value(it.quantity),
            unitCents: Value(it.unitCents),
            totalCents: it.totalCents,
            vatRate: Value(it.vatRate),
            categoryKey: it.categoryKey ?? 'other',
            sortOrder: Value(order++),
          ));
    }
  }

  Future<void> _replaceVat(int receiptId, List<ParsedVat> vat) async {
    await (db.delete(db.receiptVat)..where((t) => t.receiptId.equals(receiptId))).go();
    for (final v in vat) {
      await db.into(db.receiptVat).insert(ReceiptVatCompanion.insert(
            receiptId: receiptId,
            rate: v.rate,
            netCents: Value(v.netCents),
            vatCents: Value(v.vatCents),
            grossCents: Value(v.grossCents),
          ));
    }
  }

  /// Update an existing receipt from an edited [ParsedReceipt].
  Future<void> updateFromParsed(int id, ParsedReceipt p) async {
    await db.transaction(() async {
      await (db.update(db.receipts)..where((t) => t.id.equals(id))).write(ReceiptsCompanion(
        merchant: Value(p.merchant),
        address: Value(p.address),
        purchasedAt: Value(p.purchasedAt ?? DateTime.now()),
        totalCents: Value(p.totalCents ?? p.itemsSumCents),
        currency: Value(p.currency),
        payment: Value(p.payment.name),
        categoryKey: Value(p.categoryKey ?? 'other'),
        confidence: Value(p.confidence),
        warnings: Value(p.warnings.isEmpty ? null : p.warnings.join(',')),
      ));
      await _replaceItems(id, p.items);
      await _replaceVat(id, p.vat);
    });
  }

  Future<void> deleteReceipt(int id) => (db.delete(db.receipts)..where((t) => t.id.equals(id))).go();

  Stream<List<Receipt>> watchReceipts({String? query}) {
    final q = db.select(db.receipts)..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)]);
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      q.where((t) => t.merchant.like(like) | t.address.like(like) | t.notes.like(like));
    }
    return q.watch();
  }

  Future<ReceiptWithItems?> loadReceipt(int id) async {
    final r = await (db.select(db.receipts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    final items = await (db.select(db.receiptItems)
          ..where((t) => t.receiptId.equals(id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final vat = await (db.select(db.receiptVat)..where((t) => t.receiptId.equals(id))).get();
    return ReceiptWithItems(r, items, vat);
  }

  /// Convert a stored receipt back into the editable model.
  static ParsedReceipt toParsed(ReceiptWithItems r) => ParsedReceipt(
        merchant: r.receipt.merchant,
        merchantRaw: r.receipt.merchantRaw,
        address: r.receipt.address,
        purchasedAt: r.receipt.purchasedAt,
        totalCents: r.receipt.totalCents,
        currency: r.receipt.currency,
        payment: PaymentMethod.values.firstWhere((p) => p.name == r.receipt.payment, orElse: () => PaymentMethod.unknown),
        categoryKey: r.receipt.categoryKey,
        qrText: r.receipt.qrText,
        rksvKassenId: r.receipt.rksvKassenId,
        rksvBelegNummer: r.receipt.rksvBelegNummer,
        confidence: r.receipt.confidence,
        warnings: r.receipt.warnings?.split(',') ?? [],
        items: [
          for (final i in r.items)
            ParsedItem(
              name: i.name,
              totalCents: i.totalCents,
              quantity: i.quantity,
              unitCents: i.unitCents,
              vatRate: i.vatRate,
              categoryKey: i.categoryKey,
            ),
        ],
        vat: [
          for (final v in r.vat) ParsedVat(rate: v.rate, netCents: v.netCents, vatCents: v.vatCents, grossCents: v.grossCents),
        ],
      );

  // --- statistics -----------------------------------------------------------

  /// Item-level totals per category for a month (items carry the categories;
  /// receipts without items count under their own category).
  Future<List<CategoryTotal>> categoryTotals(DateTime from, DateTime to) async {
    final rows = await db.customSelect(
      '''
      SELECT category_key AS k, SUM(cents) AS cents, COUNT(*) AS n FROM (
        SELECT i.category_key AS category_key, i.total_cents AS cents
          FROM receipt_items i JOIN receipts r ON r.id = i.receipt_id
         WHERE r.purchased_at >= ?1 AND r.purchased_at < ?2
        UNION ALL
        SELECT r.category_key, r.total_cents
          FROM receipts r
         WHERE r.purchased_at >= ?1 AND r.purchased_at < ?2
           AND NOT EXISTS (SELECT 1 FROM receipt_items i WHERE i.receipt_id = r.id)
      ) GROUP BY category_key ORDER BY cents DESC
      ''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {db.receipts, db.receiptItems},
    ).get();
    return [
      for (final r in rows) CategoryTotal(r.read<String>('k'), r.read<int>('cents'), r.read<int>('n')),
    ];
  }

  Future<List<MerchantTotal>> merchantTotals(DateTime from, DateTime to) async {
    final rows = await db.customSelect(
      '''
      SELECT COALESCE(merchant, '?') AS m, SUM(total_cents) AS cents, COUNT(*) AS n
        FROM receipts WHERE purchased_at >= ?1 AND purchased_at < ?2
       GROUP BY m ORDER BY cents DESC
      ''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {db.receipts},
    ).get();
    return [for (final r in rows) MerchantTotal(r.read<String>('m'), r.read<int>('cents'), r.read<int>('n'))];
  }

  Future<int> monthTotal(DateTime from, DateTime to) async {
    final row = await db.customSelect(
      'SELECT COALESCE(SUM(total_cents),0) AS cents FROM receipts WHERE purchased_at >= ?1 AND purchased_at < ?2',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {db.receipts},
    ).getSingle();
    return row.read<int>('cents');
  }

  /// Months that have receipts, newest first.
  Future<List<DateTime>> monthsWithReceipts() async {
    final rows = await (db.select(db.receipts)..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)])).get();
    final seen = <String>{};
    final out = <DateTime>[];
    for (final r in rows) {
      final m = DateTime(r.purchasedAt.year, r.purchasedAt.month);
      if (seen.add('${m.year}-${m.month}')) out.add(m);
    }
    return out;
  }

  // --- export ---------------------------------------------------------------

  /// CSV with one row per item (receipts without items get one row).
  Future<String> exportCsv() async {
    final receipts = await (db.select(db.receipts)..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)])).get();
    final items = await db.select(db.receiptItems).get();
    final byReceipt = <int, List<ReceiptItem>>{};
    for (final i in items) {
      byReceipt.putIfAbsent(i.receiptId, () => []).add(i);
    }
    final sb = StringBuffer();
    sb.writeln('receipt_id;date;merchant;address;receipt_category;payment;currency;receipt_total;item;quantity;item_total;item_category');
    String esc(Object? v) {
      final s = (v ?? '').toString();
      return '"${s.replaceAll('"', '""')}"';
    }

    for (final r in receipts) {
      final date = r.purchasedAt.toIso8601String();
      final list = byReceipt[r.id] ?? const [];
      if (list.isEmpty) {
        sb.writeln([r.id, date, esc(r.merchant), esc(r.address), r.categoryKey, r.payment, r.currency, formatCents(r.totalCents), '', '', '', ''].join(';'));
      }
      for (final i in list..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
        sb.writeln([
          r.id,
          date,
          esc(r.merchant),
          esc(r.address),
          r.categoryKey,
          r.payment,
          r.currency,
          formatCents(r.totalCents),
          esc(i.name),
          i.quantity,
          formatCents(i.totalCents),
          i.categoryKey,
        ].join(';'));
      }
    }
    return sb.toString();
  }

  Future<String> exportJson() async {
    final receipts = await (db.select(db.receipts)..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)])).get();
    final out = <Map<String, dynamic>>[];
    for (final r in receipts) {
      final full = await loadReceipt(r.id);
      if (full == null) continue;
      out.add({
        'id': r.id,
        'merchant': r.merchant,
        'address': r.address,
        'purchased_at': r.purchasedAt.toIso8601String(),
        'total_cents': r.totalCents,
        'currency': r.currency,
        'payment': r.payment,
        'category': r.categoryKey,
        'rksv_kassen_id': r.rksvKassenId,
        'rksv_beleg_nummer': r.rksvBelegNummer,
        'items': [
          for (final i in full.items)
            {'name': i.name, 'quantity': i.quantity, 'total_cents': i.totalCents, 'category': i.categoryKey},
        ],
        'vat': [
          for (final v in full.vat) {'rate': v.rate, 'net': v.netCents, 'vat': v.vatCents, 'gross': v.grossCents},
        ],
      });
    }
    return const JsonEncoder.withIndent('  ').convert(out);
  }
}
