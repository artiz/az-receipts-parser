/// Shared widgets and formatting for the budget UI.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// "1.234,56 €" (the file's convention), sign kept.
String euro(double amount, {bool showPlus = false}) {
  final f = NumberFormat('#,##0.00', 'de_AT');
  final s = '${f.format(amount.abs())} €';
  if (amount < 0) return '-$s';
  return showPlus ? '+$s' : s;
}

/// Short form for tiles: "10 €", "35,09 €".
String euroShort(double amount) {
  final abs = amount.abs();
  final s = abs == abs.roundToDouble() ? '${abs.toInt()} €' : '${NumberFormat('#,##0.00', 'de_AT').format(abs)} €';
  return amount < 0 ? '-$s' : s;
}

String dateDm(DateTime d) => DateFormat('dd.MM.').format(d);
String dateDmy(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
String monthName(int year, int month, Locale locale) => DateFormat.yMMMM(locale.toString()).format(DateTime(year, month));

/// Parse "12,5", "12.50", "1.234,56", "-3,2" the way a German user types it.
double? parseAmount(String text) {
  var t = text.trim().replaceAll('€', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',') && t.contains('.')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t);
}

/// A stable accent per category, derived from its name so new categories
/// in the file get a colour without any code change.
Color categoryColor(String name, Brightness brightness) {
  const hues = [335.0, 20.0, 45.0, 90.0, 150.0, 185.0, 210.0, 250.0, 280.0, 310.0];
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final hue = hues[h % hues.length];
  final dark = brightness == Brightness.dark;
  return HSLColor.fromAHSL(1, hue, dark ? 0.55 : 0.5, dark ? 0.62 : 0.42).toColor();
}

IconData categoryIcon(BudgetCategory? c) {
  if (c == null) return Icons.label_outline;
  switch (c.type) {
    case CategoryType.income:
      return Icons.south_west;
    case CategoryType.transfer:
      return Icons.swap_horiz;
    case CategoryType.expense:
      return Icons.north_east;
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.name, this.size = 10});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: categoryColor(name, Theme.of(context).brightness), shape: BoxShape.circle),
    );
  }
}

/// Colour of an amount: income green, expenses over the entry limits pink.
Color amountColor(BuildContext context, BudgetEntry e, BudgetService budget) {
  final scheme = Theme.of(context).colorScheme;
  final cat = budget.file?.category(e.category);
  if (cat?.isTransfer ?? false) return scheme.onSurfaceVariant;
  if (e.amount < 0) return scheme.tertiary;
  final limits = budget.entryLimits;
  if (limits.length >= 3 && e.amount >= limits[2]) return AzColors.pinkInk;
  if (limits.length >= 2 && e.amount >= limits[1]) return scheme.primary;
  if (limits.isNotEmpty && e.amount >= limits[0]) return scheme.primary;
  return scheme.onSurface;
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap, this.trailing});
  final BudgetEntry entry;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final budget = AppScope.of(context).budget;
    final scheme = Theme.of(context).colorScheme;
    final cat = budget.file?.category(entry.category);
    final isTransfer = cat?.isTransfer ?? false;
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dateDm(entry.date), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            CategoryDot(name: entry.category),
          ],
        ),
      ),
      title: Text(
        entry.description.isEmpty ? entry.category : entry.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w500, fontStyle: isTransfer ? FontStyle.italic : null, color: isTransfer ? scheme.onSurfaceVariant : null),
      ),
      subtitle: Text(
        [entry.category, if (entry.note.isNotEmpty) entry.note].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isPending)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.cloud_upload_outlined, size: 16, color: scheme.onSurfaceVariant),
            ),
          Text(
            euro(entry.amount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: amountColor(context, entry, budget), fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key, required this.budget, this.onTap});
  final BudgetService budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: budget,
      builder: (context, _) {
        final (icon, text, color) = switch (budget.state) {
          SyncState.noFolder => (Icons.folder_off_outlined, l.syncNoFolder, scheme.primary),
          SyncState.syncing => (Icons.sync, l.syncSyncing, scheme.onSurfaceVariant),
          SyncState.idle => (Icons.cloud_done_outlined, l.syncIdle(budget.year ?? 0), scheme.onSurfaceVariant),
          SyncState.offline => (Icons.cloud_off_outlined, l.syncOffline(budget.pending.length), scheme.primary),
          SyncState.error => (Icons.error_outline, budget.lastError ?? l.syncError, scheme.error),
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              if (budget.pending.isNotEmpty && budget.state != SyncState.offline)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(l.pendingCount(budget.pending.length), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              if (budget.yearFiles.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: budget.year,
                    isDense: true,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                    items: [for (final f in budget.yearFiles) DropdownMenuItem(value: f.year, child: Text('${f.year}'))],
                    onChanged: (y) => y == null ? null : budget.selectYear(y),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2))),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            if (action case final a?) ...[const SizedBox(height: 16), a],
          ],
        ),
      ),
    );
  }
}
