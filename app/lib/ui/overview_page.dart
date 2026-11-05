/// Month overview computed from the entries: income, expenses, saldo, per
/// category against the plan, with the month limits from the file.
library;

import 'package:flutter/material.dart';

import '../budget/budget_file.dart';
import '../budget/budget_service.dart';
import '../core/expression.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'widgets.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.budget});
  final BudgetService budget;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int? _month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final budget = widget.budget;
    return ListenableBuilder(
      listenable: budget,
      builder: (context, _) {
        final file = budget.file;
        if (file == null) {
          return Scaffold(appBar: AppBar(title: Text(l.tabOverview)), body: EmptyHint(icon: Icons.insights_outlined, text: l.noFileLoaded));
        }
        final year = budget.year ?? DateTime.now().year;
        final now = DateTime.now();
        final months = budget.entries.map((e) => e.month).toSet().toList();
        // The calendar month is always offered (a new month starts empty).
        if (now.year == year && !months.contains(now.month)) months.add(now.month);
        if (months.isEmpty) months.add(1);
        months.sort();
        final month = _month ?? (now.year == year ? now.month : months.last);
        final entries = budget.entries.where((e) => e.month == month).toList();
        final stats = _MonthStats.from(entries, file);
        final limit1 = budget.monthLimit1;
        final limit2 = budget.monthLimit2;
        final scheme = Theme.of(context).colorScheme;
        final level = budget.limitLevel(stats.expenses);
        return Scaffold(
          appBar: AppBar(
            title: Text(l.tabOverview),
            actions: [
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: month,
                  items: [for (final m in months) DropdownMenuItem(value: m, child: Text(monthName(year, m, locale)))],
                  onChanged: (m) => setState(() => _month = m),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Row(
                children: [
                  Expanded(child: _StatCard(label: l.income, value: euro(stats.income), color: scheme.tertiary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: l.expenses,
                      value: euro(stats.expenses),
                      color: limitColor(context, level),
                      icon: limitIcon(level),
                      hint: limit1 == null ? l.limitsTap : l.limitHint(euroShort(limit1), euroShort(limit2 ?? limit1)),
                      onTap: () => _editLimits(context, budget),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StatCard(
                label: l.saldo,
                value: euro(stats.saldo, showPlus: true),
                color: stats.saldo >= 0 ? scheme.tertiary : scheme.primary,
                big: true,
              ),
              SectionTitle(l.byCategory),
              Card(
                child: Column(
                  children: [
                    for (final c in file.expenseCategories)
                      if ((stats.byCategory[c.name] ?? 0) != 0 || (file.overview.plan[c.name]?.$2[month - 1] ?? 0) != 0)
                        _CategoryRow(
                          name: c.name,
                          actual: stats.byCategory[c.name] ?? 0,
                          plan: file.overview.plan[c.name]?.$2[month - 1],
                          onEditPlan: file.overview.plan.containsKey(c.name)
                              ? () => _editPlan(context, budget, c.name, month, file.overview.plan[c.name]!.$2[month - 1], monthName(year, month, locale))
                              : null,
                        ),
                    const Divider(),
                    _CategoryRow(name: l.total, actual: stats.expenses, plan: stats.planTotal(file, month), bold: true),
                  ],
                ),
              ),
              SectionTitle(l.accountInputs),
              Card(
                child: Column(
                  children: [
                    for (final e in file.overview.rows.entries)
                      _InputRow(
                        label: e.key,
                        value: e.value.$2[month - 1],
                        formula: file.overview.formulas[e.key]?[month - 1],
                        onChanged: (v, f) => budget.setOverviewInput(e.key, month, v, formula: f),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthStats {
  _MonthStats({required this.income, required this.expenses, required this.byCategory});
  final double income;
  final double expenses;
  final Map<String, double> byCategory;

  double get saldo => income - expenses;

  double planTotal(BudgetFile file, int month) {
    var sum = 0.0;
    for (final p in file.overview.plan.values) {
      sum += p.$2[month - 1] ?? 0;
    }
    return sum;
  }

  static _MonthStats from(List<BudgetEntry> entries, BudgetFile file) {
    var income = 0.0;
    var expenses = 0.0;
    final by = <String, double>{};
    for (final e in entries) {
      final cat = file.category(e.category);
      if (cat == null) continue;
      if (cat.isIncome) {
        income += -e.amount;
      } else if (cat.isExpense) {
        expenses += e.amount;
        by[e.category] = (by[e.category] ?? 0) + e.amount;
      }
    }
    return _MonthStats(income: income, expenses: expenses, byCategory: by);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, this.hint, this.big = false, this.icon, this.onTap});
  final String label;
  final String value;
  final Color color;
  final String? hint;
  final bool big;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
                if (icon != null) Icon(icon, size: 18, color: color),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: big ? 28 : 20, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
            if (hint != null) Text(hint!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
        ),
      ),
    );
  }
}

Future<void> _editPlan(BuildContext context, BudgetService budget, String category, int month, double? current, String monthLabel) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final c = TextEditingController(text: current == null ? '' : euroShortPlain(current));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.planTitle(category, monthLabel)),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(suffixText: '€', helperText: l.formulaHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
      ],
    ),
  );
  if (ok != true) return;
  final v = parseAmount(c.text);
  if (v == null || v < 0) return;
  try {
    await budget.setPlan(category, month, v);
    messenger.showSnackBar(SnackBar(content: Text(l.planSaved)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
  }
}

Future<void> _editLimits(BuildContext context, BudgetService budget) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final c1 = TextEditingController(text: budget.monthLimit1 == null ? '' : euroShortPlain(budget.monthLimit1!));
  final c2 = TextEditingController(text: budget.monthLimit2 == null ? '' : euroShortPlain(budget.monthLimit2!));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.limitsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: c1, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l.monthLimit1, suffixText: '€', helperText: l.monthLimit1Hint)),
          const SizedBox(height: 10),
          TextField(controller: c2, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l.monthLimit2, suffixText: '€', helperText: l.monthLimit2Hint)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
      ],
    ),
  );
  if (ok != true) return;
  final v1 = parseAmount(c1.text);
  final v2 = parseAmount(c2.text);
  if (v1 == null || v2 == null || v1 <= 0 || v2 < v1) {
    messenger.showSnackBar(SnackBar(content: Text(l.limitsInvalid)));
    return;
  }
  try {
    await budget.setMonthLimits(v1, v2);
    messenger.showSnackBar(SnackBar(content: Text(l.limitsSaved)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.name, required this.actual, required this.plan, this.bold = false, this.onEditPlan});
  final String name;
  final double actual;
  final double? plan;
  final bool bold;
  final VoidCallback? onEditPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = plan != null && plan! > 0 && actual > plan!;
    final ratio = plan == null || plan == 0 ? null : (actual / plan!).clamp(0.0, 1.0);
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              if (!bold) ...[CategoryDot(name: name), const SizedBox(width: 10)],
              Expanded(child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
              Text(euro(actual), style: style.copyWith(color: over ? scheme.primary : null)),
              if (plan != null) ...[
                const SizedBox(width: 6),
                Text('/ ${euroShort(plan!)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
              if (onEditPlan != null)
                InkWell(
                  onTap: onEditPlan,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                    child: Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          if (ratio != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: over ? scheme.primary : scheme.tertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({required this.label, required this.value, required this.formula, required this.onChanged});
  final String label;
  final double? value;
  final String? formula;
  final Future<void> Function(double?, String?) onChanged;

  Future<void> _edit(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: formula ?? (value == null ? '' : value!.toStringAsFixed(2).replaceAll('.', ',')));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(suffixText: '€', helperText: l.formulaHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(l.save)),
        ],
      ),
    );
    if (result == null) return;
    final v = result.trim().isEmpty ? null : parseAmount(result);
    if (result.trim().isNotEmpty && v == null) return;
    try {
      await onChanged(v, normalizeFormula(result));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: formula == null ? null : Text(formula!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      trailing: Text(value == null ? '–' : euro(value!), style: TextStyle(fontWeight: FontWeight.w600, color: value == null ? scheme.onSurfaceVariant : scheme.onSurface)),
      onTap: () => _edit(context),
    );
  }
}
