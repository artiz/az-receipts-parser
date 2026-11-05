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
  LimitNotifier({required this.budget, required this.settings, required this.sink, required this.texts, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    budget.addListener(check);
  }

  final BudgetService budget;
  final AppSettings settings;
  final NotificationSink sink;

  /// (level, expenses, limit) → (title, body); localisation lives in the UI layer.
  final (String, String) Function(LimitLevel level, double expenses, double limit) texts;
  final DateTime Function() _clock;
  bool _checking = false;

  void dispose() => budget.removeListener(check);

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
}
