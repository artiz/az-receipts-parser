/// Watches the budget and posts a system notification the first time the
/// calendar month's expenses reach Monatslimit 1, and again at Monatslimit 2.
/// Remembered per month, so a sync does not re-notify.
library;

import 'package:flutter/foundation.dart';

import '../storage/app_notifications.dart';
import '../storage/app_settings.dart';
import '../theme.dart';
import 'budget_service.dart';

class LimitNotifier {
  LimitNotifier({required this.budget, required this.settings, required this.sink, required this.texts, this.forecastTexts, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    budget.addListener(check);
    budget.addListener(checkForecast);
  }

  final BudgetService budget;
  final AppSettings settings;
  final NotificationSink sink;

  /// (level, expenses, limit) → (title, body); localisation lives in the UI layer.
  final (String, String) Function(LimitLevel level, double expenses, double limit) texts;

  /// (forecast, limit 1) → (title, body) for the pace warning; null disables it.
  final (String, String) Function(MonthForecast forecast, double limit)? forecastTexts;
  final DateTime Function() _clock;
  bool _checking = false;
  bool _checkingForecast = false;

  void dispose() {
    budget.removeListener(check);
    budget.removeListener(checkForecast);
  }

  @visibleForTesting
  Future<void> check() async {
    if (_checking || budget.file == null || budget.state == SyncState.syncing) return;
    final now = _clock();
    if (budget.year != now.year) return;
    _checking = true;
    try {
      final expenses = budget.monthExpenses(now.month);
      final level = budget.limitLevel(expenses);
      final levelNo = switch (level) { LimitLevel.ok => 0, LimitLevel.warn => 1, LimitLevel.over => 2 };
      final notified = settings.notifiedLevel(now.year, now.month);
      if (levelNo <= notified) {
        // Dropped below a limit again (entry deleted on the laptop): forget, so a new crossing notifies.
        if (levelNo < notified) await settings.setNotifiedLevel(now.year, now.month, levelNo);
        return;
      }
      final limit = level == LimitLevel.over ? budget.monthLimit2! : budget.monthLimit1!;
      final (title, body) = texts(level, expenses, limit);
      await sink.show(id: now.year * 100 + now.month, title: title, body: body);
      await settings.setNotifiedLevel(now.year, now.month, levelNo);
    } finally {
      _checking = false;
    }
  }

  /// Once per month, before limit 1 is reached: the pace of spending would
  /// reach it on a certain day. Forgotten again when the pace drops.
  @visibleForTesting
  Future<void> checkForecast() async {
    if (_checkingForecast || budget.file == null || budget.state == SyncState.syncing || forecastTexts == null) return;
    final now = _clock();
    if (budget.year != now.year) return;
    _checkingForecast = true;
    try {
      final f = budget.forecast();
      final crossing = f != null && f.limit1Day != null && budget.limitLevel(budget.monthExpenses(now.month)) == LimitLevel.ok;
      final notified = settings.forecastNotified(now.year, now.month);
      if (!crossing) {
        if (notified) await settings.setForecastNotified(now.year, now.month, false);
        return;
      }
      if (notified || f.day < 5) return;
      final (title, body) = forecastTexts!(f, budget.monthLimit1!);
      await sink.show(id: now.year * 100 + now.month + 1000000, title: title, body: body);
      await settings.setForecastNotified(now.year, now.month, true);
    } finally {
      _checkingForecast = false;
    }
  }
}
