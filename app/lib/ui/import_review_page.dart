/// Review of the rows the model proposed from a statement or screenshot:
/// tick what to import, fix categories, answer the model's questions.
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../budget/budget_file.dart';
import '../import/statement_import.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';

class ImportReviewPage extends StatefulWidget {
  const ImportReviewPage({super.key, required this.result});
  final StatementImportResult result;

  @override
  State<ImportReviewPage> createState() => _ImportReviewPageState();
}

class _ImportReviewPageState extends State<ImportReviewPage> {
  late final List<bool> _selected = [for (final p in widget.result.proposals) p.defaultSelected];

  int get _count => _selected.where((s) => s).length;

  Future<void> _apply() async {
    final l = AppLocalizations.of(context);
    final budget = AppScope.of(context).budget;
    final entries = <BudgetEntry>[];
    for (var i = 0; i < _selected.length; i++) {
      if (_selected[i]) entries.add(widget.result.proposals[i].entry);
    }
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.importNothingSelected)));
      return;
    }
    await budget.addEntries(entries);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.importDone(entries.length))));
    Navigator.of(context).pop();
  }

  Future<void> _chooseCategory(int i) async {
    final l = AppLocalizations.of(context);
    final budget = AppScope.of(context).budget;
    final p = widget.result.proposals[i];
    final names = budget.categoriesByName.map((c) => c.name).toList();
    final ordered = [p.entry.category, ...p.alternatives, ...names.where((n) => n != p.entry.category && !p.alternatives.contains(n))];
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
            child: Text(p.question ?? l.chooseCategory, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${p.entry.description} · ${euro(p.entry.amount)}', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          for (final n in ordered)
            ListTile(
              leading: CategoryDot(name: n),
              title: Text(n),
              trailing: n == p.entry.category
                  ? const Icon(Icons.check)
                  : p.alternatives.contains(n)
                      ? Icon(Icons.auto_awesome, size: 16, color: Theme.of(ctx).colorScheme.primary)
                      : null,
              onTap: () => Navigator.pop(ctx, n),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final cat = budget.file?.category(picked);
    var amount = p.entry.amount;
    if (cat != null) {
      if (cat.isIncome && amount > 0) amount = -amount;
      if (cat.isExpense && amount < 0) amount = -amount;
    }
    setState(() {
      p.entry = p.entry.copyWith(category: picked, amount: amount);
      _selected[i] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final proposals = widget.result.proposals;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.importTitle),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              final all = _count < proposals.length;
              for (var i = 0; i < _selected.length; i++) {
                _selected[i] = all && proposals[i].skipReason == null;
              }
            }),
            child: Text(l.importSelectAll),
          ),
        ],
      ),
      body: proposals.isEmpty
          ? EmptyHint(icon: Icons.inbox_outlined, text: l.importNoText)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: proposals.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(l.importFromSource(widget.result.sourceDescription), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  );
                }
                final idx = i - 1;
                final p = proposals[idx];
                final e = p.entry;
                final muted = p.isDuplicate || p.skipReason != null;
                final String? flag = p.isDuplicate
                    ? l.importDuplicate
                    : p.skipReason != null
                        ? l.importSkipped(p.skipReason!)
                        : p.needsReview
                            ? (p.question ?? l.importNeedsReview)
                            : null;
                return CheckboxListTile(
                  value: _selected[idx],
                  onChanged: (v) => setState(() => _selected[idx] = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${dateDm(e.date)} ${e.description.isEmpty ? e.category : e.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w500, color: muted ? scheme.onSurfaceVariant : null),
                        ),
                      ),
                      Text(euro(e.amount), style: TextStyle(fontWeight: FontWeight.w600, color: e.amount < 0 ? scheme.tertiary : (muted ? scheme.onSurfaceVariant : scheme.onSurface))),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      InkWell(
                        onTap: () => _chooseCategory(idx),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryDot(name: e.category, size: 8),
                            const SizedBox(width: 6),
                            Text(e.category, style: TextStyle(fontSize: 12, color: p.needsReview && !muted ? scheme.primary : scheme.onSurfaceVariant, fontWeight: p.needsReview ? FontWeight.w600 : null)),
                            Icon(Icons.arrow_drop_down, size: 16, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                      if (flag != null) ...[
                        const SizedBox(width: 6),
                        Expanded(child: Text(flag, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: p.isDuplicate || p.skipReason != null ? scheme.onSurfaceVariant : scheme.primary))),
                      ] else if (e.note.isNotEmpty)
                        Expanded(child: Text(' · ${oneLine(e.note)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: proposals.isEmpty
          ? null
          : FloatingActionButton.extended(onPressed: _apply, icon: const Icon(Icons.download_done), label: Text(l.importApply(_count))),
    );
  }
}
