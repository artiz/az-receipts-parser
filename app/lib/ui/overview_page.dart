/// Month overview computed from the entries: income, expenses, saldo, per
/// category against the plan, with the month limits from the file.
library;

import 'package:flutter/material.dart';

import '../budget/budget_file.dart';
import '../app.dart';
import '../budget/budget_service.dart';
import '../core/text_normalize.dart';
import '../core/expression.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'entry_actions.dart';
import 'package:intl/intl.dart';

import '../storage/share_receiver.dart';
import 'category_chart.dart';
import 'year_chart.dart';
import 'widgets.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.budget});
  final BudgetService budget;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int? _year;
  int? _month;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final budget = widget.budget;
    return ListenableBuilder(
      listenable: budget,
      builder: (context, _) {
        if (budget.file == null) {
          return Scaffold(appBar: AppBar(title: Text(l.tabOverview)), body: EmptyHint(icon: Icons.insights_outlined, text: l.noFileLoaded));
        }
        final year = _year ?? budget.year ?? DateTime.now().year;
        if (year == budget.year) return _build(context, year, budget.file!);
        // Another year: read its file on demand (cached until the next sync).
        return FutureBuilder<BudgetFile?>(
          future: budget.fileForYear(year),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Scaffold(appBar: AppBar(title: Text(l.tabOverview)), body: const Center(child: CircularProgressIndicator()));
            }
            final f = snap.data;
            if (f == null) {
              return Scaffold(appBar: AppBar(title: Text(l.tabOverview)), body: EmptyHint(icon: Icons.insights_outlined, text: snap.error?.toString() ?? l.noFileLoaded));
            }
            return _build(context, year, f);
          },
        );
      },
    );
  }

  Widget _build(BuildContext context, int year, BudgetFile file) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final budget = widget.budget;
    final now = DateTime.now();
    final all = budget.entriesForYear(year, file);
    // Every month up to today's for the calendar year, all twelve for a past one.
    final lastMonth = now.year == year ? now.month : 12;
    final months = [for (var m = 1; m <= lastMonth; m++) m];
    final yearMode = _month == 0;
    final month = !yearMode && _month != null && months.contains(_month) ? _month! : (now.year == year ? now.month : months.last);
    final entries = all.where((e) => e.month == month).toList();
    final stats = _MonthStats.from(entries, file);
    final limit1 = file.setting('Monatslimit 1');
    final limit2 = file.setting('Monatslimit 2');
    final scheme = Theme.of(context).colorScheme;
    final level = BudgetService.limitLevelOf(file, stats.expenses);
    final years = budget.yearFiles.map((f) => f.year).toList();
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ?? Theme.of(context).textTheme.titleLarge;
    // Swipes walk one step through "… Nov 2025, Dec 2025, Year 2025, Jan 2026 …":
    // the months of a year, its year view, then the next year's file.
    void go(int y, int m) => setState(() {
          _year = y;
          _month = m;
          _expanded.clear();
        });
    void step(int delta) {
      final ys = [...years]..sort();
      if (delta > 0) {
        if (yearMode) {
          final next = ys.firstWhere((y) => y > year, orElse: () => year);
          if (next != year) go(next, 1);
        } else {
          go(year, month < lastMonth ? month + 1 : 0);
        }
      } else {
        if (yearMode) {
          go(year, lastMonth);
        } else if (month > 1) {
          go(year, month - 1);
        } else {
          final prev = ys.lastWhere((y) => y < year, orElse: () => year);
          if (prev != year) go(prev, 0);
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabOverview),
        actions: [
          // The menus in the title's own font: year and month read like part of the heading.
          if (years.length > 1)
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: years.contains(year) ? year : null,
                style: titleStyle,
                items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                onChanged: (y) => setState(() {
                  _year = y;
                  _month = null;
                  _expanded.clear();
                }),
              ),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: yearMode ? 0 : month,
              style: titleStyle,
              items: [
                // Short month without the year (the year has its own menu), so the title stays visible.
                for (final m in months) DropdownMenuItem(value: m, child: Text(DateFormat.MMM(locale.toString()).format(DateTime(year, m)))),
                DropdownMenuItem(value: 0, child: Text(l.yearLabel)),
              ],
              onChanged: (m) => setState(() => _month = m),
            ),
          ),
          // Back to the calendar month, shown only while another month or year is open.
          if (yearMode || year != now.year || month != now.month)
            IconButton(
              tooltip: l.currentMonth,
              icon: const Icon(Icons.today_outlined),
              onPressed: () => setState(() {
                _year = null;
                _month = null;
                _expanded.clear();
              }),
            ),
          if (!yearMode)
            IconButton(
              tooltip: l.shareMonth,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => PlatformShare.text(title: l.summaryTitle(monthName(year, month, locale)), text: _summaryText(l, file, stats, year, month, locale)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 250) return;
          step(v < 0 ? 1 : -1); // swipe left: next month
        },
        child: yearMode ? _yearBody(context, year, file, all) : ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l.income,
                  value: euro(stats.income),
                  color: scheme.tertiary,
                  icon: _expanded.contains('\u0000income') ? Icons.expand_less : Icons.expand_more,
                  showEdit: false,
                  onTap: () => setState(() => _expanded.contains('\u0000income') ? _expanded.remove('\u0000income') : _expanded.add('\u0000income')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: l.expenses,
                  value: euro(stats.expenses),
                  color: limitColor(context, level),
                  icon: limitIcon(level),
                  hint: limit1 == null ? l.limitsTap : l.limitHint(euroShort(limit1), euroShort(limit2 ?? limit1)),
                  onTap: () => _editLimits(context, budget, year, limit1, limit2),
                ),
              ),
            ],
          ),
          if (_expanded.contains('\u0000income'))
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: _CategoryBreakdown(entries: entries.where((e) => file.category(e.category)?.isIncome ?? false).toList()),
              ),
            ),
          const SizedBox(height: 8),
          _StatCard(
            label: l.saldo,
            value: euro(stats.saldo, showPlus: true),
            color: stats.saldo >= 0 ? scheme.tertiary : scheme.primary,
            big: true,
          ),
          const SizedBox(height: 8),
          CategoryChart(bars: CategoryChart.barsFor(file, stats.byCategory, month)),
          SectionTitle(l.byCategory),
          Card(
            child: Column(
              children: [
                for (final c in file.expenseCategoriesByName)
                  if ((stats.byCategory[c.name] ?? 0) != 0 || (file.overview.plan[c.name]?.$2[month - 1] ?? 0) != 0)
                    _CategoryRow(
                      name: c.name,
                      actual: stats.byCategory[c.name] ?? 0,
                      plan: file.overview.plan[c.name]?.$2[month - 1],
                      expanded: _expanded.contains(c.name),
                      onTap: () => setState(() => _expanded.contains(c.name) ? _expanded.remove(c.name) : _expanded.add(c.name)),
                      onEditPlan: file.overview.plan.containsKey(c.name)
                          ? () => _editPlan(context, budget, year, c.name, month, file.overview.plan[c.name]!.$2[month - 1], monthName(year, month, locale))
                          : null,
                      breakdown: _expanded.contains(c.name) ? _CategoryBreakdown(entries: entries.where((e) => e.category == c.name).toList()) : null,
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
                    onChanged: (v, f) => budget.setOverviewInput(e.key, month, v, formula: f, year: year),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

extension _YearView on _OverviewPageState {
  /// Twelve months at a glance: chart, totals, categories against plan and
  /// the previous year's file.
  Widget _yearBody(BuildContext context, int year, BudgetFile file, List<BudgetEntry> all) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final budget = widget.budget;
    final months = <YearMonth>[];
    final byCategory = <String, double>{};
    var income = 0.0;
    var expenses = 0.0;
    var planYear = 0.0;
    final planByCategory = <String, double>{};
    for (var m = 1; m <= 12; m++) {
      final stats = _MonthStats.from(all.where((e) => e.month == m).toList(), file);
      final plan = stats.planTotal(file, m);
      months.add(YearMonth(month: m, income: stats.income, expenses: stats.expenses, plan: plan, level: BudgetService.limitLevelOf(file, stats.expenses)));
      income += stats.income;
      expenses += stats.expenses;
      planYear += plan;
      for (final e in stats.byCategory.entries) {
        byCategory[e.key] = (byCategory[e.key] ?? 0) + e.value;
      }
    }
    for (final p in file.overview.plan.entries) {
      planByCategory[p.key] = p.value.$2.fold(0.0, (s, v) => s + (v ?? 0));
    }
    final saldo = income - expenses;
    String label(int m) => DateFormat.MMM(locale.toString()).format(DateTime(year, m));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: l.income, value: euro(income), color: scheme.tertiary, showEdit: false)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: l.expenses, value: euro(expenses), color: scheme.primary, showEdit: false, hint: planYear > 0 ? '${l.planLabel} ${euroShort(planYear)}' : null)),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(label: l.saldo, value: euro(saldo, showPlus: true), color: saldo >= 0 ? scheme.tertiary : scheme.primary, big: true),
        const SizedBox(height: 8),
        YearChart(months: months, monthLabel: label),
        SectionTitle(l.yearByCategory),
        FutureBuilder<YearSummary?>(
          // The previous year is parsed once, off the UI thread (see BudgetService.yearSummary).
          future: budget.yearSummary(year - 1),
          builder: (context, snap) {
            final prev = snap.data;
            final prevBy = prev?.byCategory ?? const <String, double>{};
            final prevTotal = prev?.expenses ?? 0.0;
            final rows = [
              for (final c in file.expenseCategoriesByName)
                if ((byCategory[c.name] ?? 0) != 0 || (planByCategory[c.name] ?? 0) != 0 || (prevBy[c.name] ?? 0) != 0) c.name,
            ];
            return Card(
              child: Column(
                children: [
                  _YearRow(name: '', actual: l.actual, plan: l.planLabel, previous: prev == null ? null : l.previousYear, header: true),
                  for (final name in rows)
                    _YearRow(
                      name: name,
                      actual: euroShort(byCategory[name] ?? 0),
                      plan: (planByCategory[name] ?? 0) > 0 ? euroShort(planByCategory[name]!) : '–',
                      previous: prev == null ? null : euroShort(prevBy[name] ?? 0),
                      over: (planByCategory[name] ?? 0) > 0 && (byCategory[name] ?? 0) > planByCategory[name]!,
                    ),
                  const Divider(),
                  _YearRow(name: l.total, actual: euroShort(expenses), plan: planYear > 0 ? euroShort(planYear) : '–', previous: prev == null ? null : euroShort(prevTotal), bold: true),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.name, required this.actual, required this.plan, this.previous, this.bold = false, this.header = false, this.over = false});
  final String name;
  final String actual;
  final String plan;
  final String? previous;
  final bool bold;
  final bool header;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontWeight: bold || header ? FontWeight.w700 : FontWeight.w400, fontSize: header ? 11 : 14, color: header ? scheme.onSurfaceVariant : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          if (!header && !bold) ...[CategoryDot(name: name), const SizedBox(width: 10)],
          Expanded(child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 78, child: Text(actual, textAlign: TextAlign.right, style: style.copyWith(color: over ? scheme.primary : style.color))),
          SizedBox(width: 72, child: Text(plan, textAlign: TextAlign.right, style: style.copyWith(color: header ? style.color : scheme.onSurfaceVariant))),
          if (previous != null) SizedBox(width: 78, child: Text(previous!, textAlign: TextAlign.right, style: style.copyWith(color: header ? style.color : scheme.onSurfaceVariant))),
        ],
      ),
    );
  }
}

/// Plain text of the month for the share sheet.
String _summaryText(AppLocalizations l, BudgetFile file, _MonthStats stats, int year, int month, Locale locale) {
  final top = stats.byCategory.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
  final b = StringBuffer()
    ..writeln(l.summaryTitle(monthName(year, month, locale)))
    ..writeln('${l.summaryIncome}: ${euro(stats.income)}')
    ..writeln('${l.summaryExpenses}: ${euro(stats.expenses)}')
    ..writeln('${l.saldo}: ${euro(stats.saldo, showPlus: true)}');
  if (top.isNotEmpty) {
    b
      ..writeln()
      ..writeln('${l.summaryTop}:');
    for (final e in top.take(6)) {
      final plan = file.overview.plan[e.key]?.$2[month - 1];
      b.writeln('• ${e.key}: ${euro(e.value)}${plan != null && plan > 0 ? ' / ${euroShort(plan)}' : ''}');
    }
  }
  return b.toString().trimRight();
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
  const _StatCard({required this.label, required this.value, required this.color, this.hint, this.big = false, this.icon, this.onTap, this.showEdit = true});
  final bool showEdit;
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
                if (onTap != null && showEdit) ...[
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

Future<void> _editPlan(BuildContext context, BudgetService budget, int year, String category, int month, double? current, String monthLabel) async {
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
    await budget.setPlan(category, month, v, year: year);
    messenger.showSnackBar(SnackBar(content: Text(l.planSaved)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
  }
}

Future<void> _editLimits(BuildContext context, BudgetService budget, int year, double? limit1, double? limit2) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final c1 = TextEditingController(text: limit1 == null ? '' : euroShortPlain(limit1));
  final c2 = TextEditingController(text: limit2 == null ? '' : euroShortPlain(limit2));
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
    await budget.setMonthLimits(v1, v2, year: year);
    messenger.showSnackBar(SnackBar(content: Text(l.limitsSaved)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(e.toString()))));
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.name, required this.actual, required this.plan, this.bold = false, this.onEditPlan, this.onTap, this.expanded = false, this.breakdown});
  final String name;
  final double actual;
  final double? plan;
  final bool bold;
  final VoidCallback? onEditPlan;
  final VoidCallback? onTap;
  final bool expanded;
  final Widget? breakdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = plan != null && plan! > 0 && actual > plan!;
    final ratio = plan == null || plan == 0 ? null : (actual / plan!).clamp(0.0, 1.0);
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()]);
    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              if (!bold) ...[CategoryDot(name: name), const SizedBox(width: 10)],
              Expanded(child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
              if (onTap != null) Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: scheme.onSurfaceVariant),
              if (onTap != null) const SizedBox(width: 4),
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
          ?breakdown,
        ],
      ),
      ),
    );
  }
}

/// What the category's month consists of: the descriptions with their
/// count and sum, largest first, then the single bookings.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.entries});
  final List<BudgetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final budget = AppScope.of(context).budget;
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(alignment: Alignment.centerLeft, child: Text(l.noEntries, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
      );
    }
    final groups = <String, (String, int, double)>{};
    for (final e in entries) {
      final key = normalize(e.description.isEmpty ? e.category : e.description);
      final g = groups[key];
      groups[key] = (e.description.isEmpty ? e.category : e.description, (g?.$2 ?? 0) + 1, (g?.$3 ?? 0) + e.amount);
    }
    final sorted = groups.values.toList()..sort((a, b) => b.$3.abs().compareTo(a.$3.abs()));
    final byDate = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
    final small = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(g.$2 > 1 ? '${g.$1} ×${g.$2}' : g.$1, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  Text(euro(g.$3), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          if (sorted.length < byDate.length) ...[
            const SizedBox(height: 6),
            Text(l.allBookings(byDate.length), style: small),
            for (final e in byDate)
              InkWell(
                onTap: () => editEntry(context, budget, e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(dateDm(e.date), style: small),
                      const SizedBox(width: 8),
                      Expanded(child: Text([e.description, if (e.note.isNotEmpty) oneLine(e.note)].join(' · '), style: small, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(euro(e.amount), style: small.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
              ),
          ],
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
