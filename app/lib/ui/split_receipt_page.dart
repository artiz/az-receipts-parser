/// Assign a category to every item of a scanned receipt; one booking per
/// category comes out.
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/receipt_split.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

class SplitReceiptPage extends StatefulWidget {
  const SplitReceiptPage({super.key, required this.date, required this.description, required this.total, required this.items, required this.main});
  final DateTime date;
  final String description;
  final double total;
  final List<ReceiptItemDraft> items;
  final String main;

  @override
  State<SplitReceiptPage> createState() => _SplitReceiptPageState();
}

class _SplitReceiptPageState extends State<SplitReceiptPage> {
  late final List<String> _assigned = List.filled(widget.items.length, widget.main);

  Future<void> _pick(int i) async {
    final budget = AppScope.of(context).budget;
    final cats = budget.categoriesByName.where((c) => c.isExpense).toList();
    final navBar = MediaQuery.of(context).viewPadding.bottom;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: navBar),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(widget.items[i].name, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final c in cats)
            ListTile(
              leading: Icon(categoryIcon(c), color: categoryColor(c.name, Theme.of(ctx).brightness, hex: c.color)),
              title: Text(c.name),
              trailing: c.name == _assigned[i] ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, c.name),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _assigned[i] = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final budget = AppScope.of(context).budget;
    final entries = splitReceipt(date: widget.date, description: widget.description, total: widget.total, items: widget.items, assignments: _assigned, main: widget.main);
    return Scaffold(
      appBar: AppBar(title: Text(l.splitTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, i) {
                final item = widget.items[i];
                final cat = budget.file?.category(_assigned[i]);
                final color = categoryColor(_assigned[i], brightness, hex: cat?.color);
                return ListTile(
                  dense: true,
                  title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(euro(item.amount)),
                  trailing: ActionChip(
                    avatar: Icon(categoryIcon(cat, _assigned[i]), size: 16, color: color),
                    label: Text(_assigned[i], overflow: TextOverflow.ellipsis),
                    onPressed: () => _pick(i),
                    side: BorderSide(color: _assigned[i] == widget.main ? scheme.outlineVariant : color),
                  ),
                  onTap: () => _pick(i),
                );
              },
            ),
          ),
          Material(
            color: scheme.surfaceContainerLow,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            CategoryDot(name: e.category),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.category)),
                            Text(euro(e.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      onPressed: entries.length < 2 ? null : () => Navigator.of(context).pop(entries),
                      icon: const Icon(Icons.call_split),
                      label: Text(l.splitSave(entries.length)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
