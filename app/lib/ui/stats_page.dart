import 'package:flutter/material.dart';

import '../app.dart';
import '../categorize/categories.dart';
import '../data/database.dart';
import '../data/receipt_repository.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final repo = AppScope.of(context).repository;
    final from = _month;
    final to = DateTime(_month.year, _month.month + 1);
    return Scaffold(
      appBar: AppBar(title: Text(l.tabStats)),
      body: StreamBuilder<List<Receipt>>(
        // Re-run the aggregates whenever receipts change.
        stream: repo.watchReceipts(),
        builder: (context, receiptsSnap) {
          return FutureBuilder<_StatsData>(
            future: _load(repo, from, to),
            builder: (context, snap) {
              final data = snap.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _monthPicker(context, data?.months ?? [_month], locale),
                  const SizedBox(height: 16),
                  if (data == null)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (data.total == 0)
                    Text(l.noDataForMonth)
                  else ...[
                    Card(
                      child: ListTile(
                        title: Text(l.total),
                        subtitle: Text(l.receiptsCount(data.receiptCount)),
                        trailing: Text(money(data.total, 'EUR', locale), style: Theme.of(context).textTheme.titleLarge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l.byCategory, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final c in data.categories) _bar(context, l, locale, c, data.categoryList, data.itemTotal),
                    const SizedBox(height: 16),
                    Text(l.byMerchant, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final m in data.merchants)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.merchant),
                        subtitle: Text(l.receiptsCount(m.count)),
                        trailing: Text(money(m.cents, 'EUR', locale)),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _monthPicker(BuildContext context, List<DateTime> months, Locale locale) {
    final all = {...months, _month}.toList()..sort((a, b) => b.compareTo(a));
    return DropdownButtonFormField<DateTime>(
      initialValue: _month,
      decoration: InputDecoration(labelText: AppLocalizations.of(context).month, border: const OutlineInputBorder()),
      items: [for (final m in all) DropdownMenuItem(value: m, child: Text(monthLabel(m, locale)))],
      onChanged: (m) {
        if (m != null) setState(() => _month = m);
      },
    );
  }

  Widget _bar(BuildContext context, AppLocalizations l, Locale locale, CategoryTotal c, List<Category> categories, int total) {
    final def = categoryDef(c.categoryKey);
    final share = total == 0 ? 0.0 : (c.cents / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(def.icon, size: 18, color: def.color),
              const SizedBox(width: 8),
              Expanded(child: Text(localizedCategoryName(l, c.categoryKey, categories: categories))),
              Text(money(c.cents, 'EUR', locale)),
              const SizedBox(width: 8),
              SizedBox(width: 44, child: Text('${(share * 100).round()} %', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: share, minHeight: 8, color: def.color, backgroundColor: def.color.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  Future<_StatsData> _load(ReceiptRepository repo, DateTime from, DateTime to) async {
    final months = await repo.monthsWithReceipts();
    final total = await repo.monthTotal(from, to);
    final categories = await repo.categoryTotals(from, to);
    final merchants = await repo.merchantTotals(from, to);
    final categoryList = await repo.categories();
    final receiptCount = merchants.fold(0, (a, m) => a + m.count);
    final itemTotal = categories.fold(0, (a, c) => a + c.cents);
    return _StatsData(months, total, categories, merchants, categoryList, receiptCount, itemTotal);
  }
}

class _StatsData {
  _StatsData(this.months, this.total, this.categories, this.merchants, this.categoryList, this.receiptCount, this.itemTotal);
  final List<DateTime> months;
  final int total;
  final List<CategoryTotal> categories;
  final List<MerchantTotal> merchants;
  final List<Category> categoryList;
  final int receiptCount;
  final int itemTotal;
}
