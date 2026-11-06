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
  LimitNotifier({required this.budget, required this.settings, required this.sink, required this.texts, this.approachTexts, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    budget.addListener(check);
  }

  final BudgetService budget;
  final AppSettings settings;
  final NotificationSink sink;

  /// (level, expenses, limit) → (title, body); localisation lives in the UI layer.
  final (String, String) Function(LimitLevel level, double expenses, double limit) texts;

  /// (expenses, limit 1) → (title, body) for "reaching limit 1"; null disables it.
  final (String, String) Function(double expenses, double limit)? approachTexts;

  /// Share of limit 1 at which "reaching limit 1" is sent.
  static const double approachShare = 0.8;
  final DateTime Function() _clock;
  bool _checking = false;

  void dispose() => budget.removeListener(check);

  /// Once per month, when the expenses pass [approachShare] of limit 1 but
  /// the limit itself is not reached yet; forgotten when they drop below.
  Future<void> _checkApproach(DateTime now, double expenses, LimitLevel level) async {
    final limit = budget.monthLimit1;
    final texts = approachTexts;
    if (texts == null || limit == null || limit <= 0) return;
    final near = level == LimitLevel.ok && expenses >= limit * approachShare;
    final notified = settings.approachNotified(now.year, now.month);
    if (!near) {
      if (notified && expenses < limit * approachShare) await settings.setApproachNotified(now.year, now.month, false);
      return;
    }
    if (notified) return;
    final (title, body) = texts(expenses, limit);
    await sink.show(id: now.year * 100 + now.month + 1000000, title: title, body: body);
    await settings.setApproachNotified(now.year, now.month, true);
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
      await _checkApproach(now, expenses, level);
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
