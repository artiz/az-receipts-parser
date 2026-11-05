/// Home: quick tiles learned from the file, the last entries, and the
/// shortcuts to scan/import.
library;

import 'package:flutter/material.dart';

import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../budget/entry_suggest.dart';
import '../l10n/app_localizations.dart';
import 'entry_sheet.dart';
import 'widgets.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key, required this.budget, required this.onOpenSettings});
  final BudgetService budget;
  final VoidCallback onOpenSettings;

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  bool _showAll = false;
  static const int _recentCount = 5;

  Future<void> _addFromTile(QuickTile tile) async {
    final l = AppLocalizations.of(context);
    final budget = widget.budget;
    final entry = await showEntrySheet(
      context,
      budget: budget,
      title: l.confirmEntry,
      draft: EntryDraft(category: tile.category, description: tile.description, amount: tile.amount.abs()),
    );
    if (entry == null) return;
    await budget.addEntry(entry);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.entrySaved(euro(entry.amount)))));
  }

  Future<void> _edit(BudgetEntry e) async {
    final l = AppLocalizations.of(context);
    final budget = widget.budget;
    if (!e.isPending) {
      // Entries already in the file are edited on the laptop; keep the app simple.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.editInFile)));
      return;
    }
    final entry = await showEntrySheet(
      context,
      budget: budget,
      title: l.editEntry,
      draft: EntryDraft(date: e.date, category: e.category, description: e.description, amount: e.amount.abs(), note: e.note),
    );
    if (entry == null) return;
    await budget.removePending(e.pendingId!);
    await budget.addEntry(entry);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final budget = widget.budget;
    return ListenableBuilder(
      listenable: budget,
      builder: (context, _) {
        if (budget.state == SyncState.noFolder) {
          return EmptyHint(
            icon: Icons.folder_open_outlined,
            text: l.chooseFolderHint,
            action: FilledButton.icon(onPressed: widget.onOpenSettings, icon: const Icon(Icons.folder_outlined), label: Text(l.chooseFolder)),
          );
        }
        final all = budget.entries.reversed.toList();
        final tiles = budget.suggestions.quickTiles(limit: 9, perCategory: 3);
        final shown = _showAll ? all : all.take(_recentCount).toList();
        return RefreshIndicator(
          onRefresh: budget.sync,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SyncStatusBar(budget: budget, onTap: budget.sync)),
              if (tiles.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionTitle(l.quickEntries)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final t in tiles) _QuickTileChip(tile: t, onTap: () => _addFromTile(t))],
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionTitle(
                  l.recentEntries,
                  trailing: all.length > _recentCount
                      ? TextButton(onPressed: () => setState(() => _showAll = !_showAll), child: Text(_showAll ? l.showLess : l.showAll(all.length)))
                      : null,
                ),
              ),
              if (all.isEmpty)
                SliverToBoxAdapter(child: EmptyHint(icon: Icons.receipt_long_outlined, text: l.noEntries))
              else
                SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) => EntryTile(entry: shown[i], onTap: () => _edit(shown[i])),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}

class _QuickTileChip extends StatelessWidget {
  const _QuickTileChip({required this.tile, required this.onTap});
  final QuickTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.outline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryDot(name: tile.category, size: 8),
                  const SizedBox(width: 6),
                  Text(tile.category, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 2),
              Text('${tile.description} · ${euroShort(tile.amount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
