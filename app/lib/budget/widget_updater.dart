/// Feeds the home-screen widget after every change of the budget: the
/// calendar month's expenses, the limit and the traffic-light colour.
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../storage/app_widget.dart';
import '../theme.dart';
import 'budget_service.dart';

class WidgetUpdater {
  WidgetUpdater({required this.budget, required this.sink, required this.symbol, required this.localeCode, DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    budget.addListener(update);
  }

  final BudgetService budget;
  final WidgetSink sink;
  final String Function() symbol;
  final String Function() localeCode;
  final DateTime Function() _clock;

  void dispose() => budget.removeListener(update);

  static const _colors = {LimitLevel.ok: 0xFF3BA55D, LimitLevel.warn: 0xFFD9A400, LimitLevel.over: 0xFFFF2E7E};

  Future<void> update() async {
    if (budget.file == null || budget.state == SyncState.syncing) return;
    final now = _clock();
    if (budget.year != now.year) return;
    final expenses = budget.monthExpenses(now.month);
    final limit = budget.monthLimit1;
    final level = budget.limitLevel(expenses);
    final locale = switch (localeCode()) { 'en' => 'en_GB', 'ru' => 'ru', _ => 'de_AT' };
    // Date symbols are loaded per locale on demand (the widget runs outside the widget tree).
    await initializeDateFormatting(locale);
    final f = NumberFormat('#,##0', locale);
    final s = symbol();
    final amount = limit == null || limit <= 0 ? '${f.format(expenses)} $s' : '${f.format(expenses)} / ${f.format(limit)} $s';
    final title = DateFormat.MMMM(locale).format(now);
    await sink.update(title: title, amount: amount, color: _colors[level]!);
  }
}
