/// Home: the bookings table over the full height, with the quick tiles
/// learned from the file in a panel that drops down from the status line.
library;

import 'package:flutter/material.dart';

import '../app.dart';
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
  bool _tilesOpen = false;

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
    setState(() => _tilesOpen = false);
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
    final scheme = Theme.of(context).colorScheme;
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
            SyncStatusBar(
              budget: budget,
              onTap: budget.sync,
              leading: tiles.isEmpty
                  ? null
                  : FilledButton.tonalIcon(
                      onPressed: () => setState(() => _tilesOpen = !_tilesOpen),
                      icon: Icon(_tilesOpen ? Icons.expand_less : Icons.bolt_outlined, size: 18),
                      label: Text(l.quickEntries),
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12)),
                    ),
            ),
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
                actions: [TextButton(onPressed: () => createYearFile(context, budget), child: Text(l.createYearFile(budget.currentYear)))],
              ),
            if (budget.freshFileYear != null && budget.file != null)
              MaterialBanner(
                content: Text(l.fileCreatedNotice(budget.freshFileYear!, languageDisplayName(budget.file!.language))),
                leading: const Icon(Icons.auto_awesome_outlined),
                actions: [TextButton(onPressed: budget.dismissFreshFile, child: Text(l.gotIt))],
              ),
            // The quick tiles drop down over the top of the table.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _tilesOpen && tiles.isNotEmpty
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          border: Border(bottom: BorderSide(color: scheme.outline, width: 2)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final t in tiles) _QuickTileChip(tile: t, onTap: () => _addFromTile(t))],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
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
                          final dayStart = i > 0 && !_sameDay(shown[i - 1].date, e.date);
                          return Dismissible(
                            key: ValueKey(e.pendingId ?? 'row-${e.date.year}-${e.row}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => confirmDeleteEntry(context, budget, e),
                            background: Container(
                              color: scheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            child: EntryTile(
                              entry: e,
                              zebra: i.isOdd,
                              dayStart: dayStart,
                              onTap: () => editEntry(context, budget, e),
                              trailing: IconButton(
                                tooltip: l.addToEntryShort,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => addToEntryDialog(context, budget, e),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _QuickTileChip extends StatelessWidget {
  const _QuickTileChip({required this.tile, required this.onTap});
  final QuickTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final budget = AppScope.of(context).budget;
    final cat = budget.file?.category(tile.category);
    final color = categoryColor(tile.category, Theme.of(context).brightness, hex: cat?.color);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: color, width: 3),
              left: BorderSide(color: scheme.outline),
              right: BorderSide(color: scheme.outline),
              bottom: BorderSide(color: scheme.outline),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(message: tile.category, child: Icon(categoryIcon(cat, tile.category), size: 18, color: color)),
              const SizedBox(width: 8),
              Text('${tile.description} · ${euroShort(tile.amount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
