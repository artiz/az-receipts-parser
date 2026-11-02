import 'package:flutter/material.dart';

import '../app.dart';
import '../data/database.dart';
import '../data/receipt_repository.dart';
import '../l10n/app_localizations.dart';
import 'receipt_detail_page.dart';
import 'widgets.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final repo = AppScope.of(context).repository;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: l.searchHint,
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Category>>(
        stream: repo.watchCategories(),
        builder: (context, catSnap) {
          final categories = catSnap.data ?? const <Category>[];
          return StreamBuilder<List<Receipt>>(
            stream: repo.watchReceipts(query: _query),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final receipts = snap.data!;
              if (receipts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.noReceipts, textAlign: TextAlign.center),
                  ),
                );
              }
              final entries = _groupByMonth(receipts);
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  if (e is _MonthHeader) {
                    return ListTile(
                      dense: true,
                      title: Text(monthLabel(e.month, locale), style: Theme.of(context).textTheme.titleSmall),
                      trailing: Text(money(e.cents, 'EUR', locale), style: Theme.of(context).textTheme.titleSmall),
                    );
                  }
                  final r = (e as _ReceiptEntry).receipt;
                  return ListTile(
                    leading: CategoryAvatar(categoryKey: r.categoryKey),
                    title: Text(r.merchant ?? l.unknownMerchant),
                    subtitle: Text(
                      '${dateShort(r.purchasedAt, locale)} · ${localizedCategoryName(l, r.categoryKey, categories: categories)}',
                    ),
                    trailing: Text(money(r.totalCents, r.currency, locale), style: Theme.of(context).textTheme.titleMedium),
                    onTap: () => _open(context, repo, r.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, ReceiptRepository repo, int id) async {
    final full = await repo.loadReceipt(id);
    if (full == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReceiptDetailPage.edit(stored: full),
    ));
  }

  List<Object> _groupByMonth(List<Receipt> receipts) {
    final out = <Object>[];
    DateTime? month;
    var cents = 0;
    int? headerIndex;
    for (final r in receipts) {
      final m = DateTime(r.purchasedAt.year, r.purchasedAt.month);
      if (month != m) {
        if (headerIndex != null) out[headerIndex] = _MonthHeader(month!, cents);
        month = m;
        cents = 0;
        headerIndex = out.length;
        out.add(_MonthHeader(m, 0));
      }
      cents += r.totalCents;
      out.add(_ReceiptEntry(r));
    }
    if (headerIndex != null) out[headerIndex] = _MonthHeader(month!, cents);
    return out;
  }
}

class _MonthHeader {
  _MonthHeader(this.month, this.cents);
  final DateTime month;
  final int cents;
}

class _ReceiptEntry {
  _ReceiptEntry(this.receipt);
  final Receipt receipt;
}
