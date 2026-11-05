/// Home: the upper half holds the quick tiles learned from the file, the
/// lower half the bookings table with a search field, paged as you scroll.
library;

import 'package:flutter/material.dart';

import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../budget/entry_suggest.dart';
import '../core/text_normalize.dart';
import '../l10n/app_localizations.dart';
import 'entry_actions.dart';
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
  static const int _pageSize = 20;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  int _visible = _pageSize;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _visible = _pageSize));
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Next page when the list is near its end; the data is in memory, so the
  /// "load" is just a deferred rebuild that keeps scrolling smooth.
  void _onScroll() {
    if (_loadingMore || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) {
      _loadingMore = true;
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        setState(() {
          _visible += _pageSize;
          _loadingMore = false;
        });
      });
    }
  }

  Future<void> _addFromTile(QuickTile tile) async {
    final l = AppLocalizations.of(context);
    final budget = widget.budget;
    final entry = await showEntrySheet(
      context,
      budget: budget,
      title: l.confirmEntry,
      draft: EntryDraft(category: tile.category, description: tile.description, amount: tile.amount.abs()),
    );
    if (entry == null || !mounted) return;
    await saveNewEntry(context, budget, entry);
  }

  List<BudgetEntry> _filtered(List<BudgetEntry> all) {
    final q = normalize(_search.text.trim());
    if (q.isEmpty) return all;
    final words = q.split(' ');
    return [
      for (final e in all)
        if (words.every((w) => normalize('${e.description} ${e.category} ${e.note} ${e.amount.toStringAsFixed(2)} ${e.amount.toStringAsFixed(2).replaceAll('.', ',')}').contains(w))) e,
    ];
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
        final tiles = budget.suggestions.quickTiles(limit: 12, perCategory: 3);
        final shown = _filtered(all);
        final count = shown.length < _visible ? shown.length : _visible;
        final stranded = budget.strandedPending;
        return Column(
          children: [
            SyncStatusBar(budget: budget, onTap: budget.sync),
            if (stranded.isNotEmpty)
              MaterialBanner(
                content: Text(l.strandedPending(stranded.length, stranded.first.date.year)),
                leading: const Icon(Icons.event_busy_outlined),
                actions: [TextButton(onPressed: () => editEntry(context, budget, stranded.first), child: Text(l.fixDate))],
              ),
            if (budget.currentYearMissing)
              MaterialBanner(
                content: Text(l.yearFileMissing(budget.currentYear)),
                leading: const Icon(Icons.calendar_month_outlined),
                actions: [TextButton(onPressed: () => _createYear(context), child: Text(l.createYearFile(budget.currentYear)))],
              ),
            Expanded(
              flex: 1,
              child: tiles.isEmpty
                  ? EmptyHint(icon: Icons.bolt_outlined, text: l.noEntries)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(l.quickEntries),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [for (final t in tiles) _QuickTileChip(tile: t, onTap: () => _addFromTile(t))],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            // A clear seam between the quick tiles and the table.
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.symmetric(horizontal: BorderSide(color: Theme.of(context).colorScheme.outline)),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: l.searchHint(all.length),
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: _search.clear),
                      ),
                    ),
                  ),
                  Expanded(
                    child: shown.isEmpty
                        ? EmptyHint(icon: Icons.receipt_long_outlined, text: l.noEntries)
                        : RefreshIndicator(
                            onRefresh: budget.sync,
                            child: ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.only(bottom: 88),
                              itemCount: count + (count < shown.length ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= count) {
                                  return const Padding(padding: EdgeInsets.all(12), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
                                }
                                final e = shown[i];
                                return EntryTile(
                                  entry: e,
                                  onTap: () => editEntry(context, budget, e),
                                  trailing: IconButton(
                                    tooltip: l.addToEntryShort,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () => addToEntryDialog(context, budget, e),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createYear(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final y = widget.budget.currentYear;
    try {
      await widget.budget.createYearFile(y);
      messenger.showSnackBar(SnackBar(content: Text(l.yearFileCreated(y))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
    }
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
