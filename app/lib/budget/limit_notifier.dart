/// Watches the budget and posts a system notification the first time the
/// calendar month's expenses reach Monatslimit 1, and again at Monatslimit 2;
/// before each of them, an optional early warning when they come within the
/// margin set in the app settings (5 % of the limit by default).
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
    settings.addListener(check); // the margin or the switch changed
  }

  final BudgetService budget;
  final AppSettings settings;
  final NotificationSink sink;

  /// (level, expenses, limit) → (title, body); localisation lives in the UI layer.
  final (String, String) Function(LimitLevel level, double expenses, double limit) texts;

  /// (limit number 1 or 2, expenses, limit) → (title, body) for "reaching
  /// limit n"; null disables the early warnings.
  final (String, String) Function(int limitNo, double expenses, double limit)? approachTexts;

  final DateTime Function() _clock;
  bool _checking = false;

  /// A check was asked for while one was running (a settings change during a
  /// sync): run once more afterwards instead of dropping it.
  bool _again = false;

  void dispose() {
    budget.removeListener(check);
    settings.removeListener(check);
  }

  /// Once per month and limit, when the expenses pass the approach threshold
  /// (the limit minus the margin from the settings) but the limit itself is
  /// not reached yet; forgotten when they drop below the threshold again,
  /// and never sent while that warning is switched off.
  ///
  /// Limit 2's warning only comes above limit 1: a margin reaching below
  /// limit 1 would otherwise warn about limit 2 before limit 1 is reached.
  Future<void> _checkApproach(int limitNo, DateTime now, double expenses, LimitLevel level) async {
    final limit = limitNo == 1 ? budget.monthLimit1 : budget.monthLimit2;
    final texts = approachTexts;
    if (texts == null || limit == null || limit <= 0 || !settings.approachEnabled(limitNo)) return;
    final threshold = settings.approachMargin(limitNo).threshold(limit);
    if (threshold == null) return;
    final below = limitNo == 1 ? level == LimitLevel.ok : level != LimitLevel.over;
    final l1 = budget.monthLimit1;
    final aboveLimit1 = limitNo == 1 || l1 == null || l1 <= 0 || expenses > l1;
    final near = below && aboveLimit1 && expenses >= threshold;
    final notified = settings.approachNotified(limitNo, now.year, now.month);
    if (!near) {
      if (notified && expenses < threshold) await settings.setApproachNotified(limitNo, now.year, now.month, false);
      return;
    }
    if (notified) return;
    final (title, body) = texts(limitNo, expenses, limit);
    await sink.show(id: now.year * 100 + now.month + limitNo * 1000000, title: title, body: body);
    await settings.setApproachNotified(limitNo, now.year, now.month, true);
  }

  @visibleForTesting
  Future<void> check() async {
    if (_checking) {
      _again = true;
      return;
    }
    if (budget.file == null || budget.state == SyncState.syncing) return;
    final now = _clock();
    if (budget.year != now.year) return;
    _checking = true;
    try {
      await _check(now);
    } finally {
      _checking = false;
    }
    if (_again) {
      _again = false;
      await check();
    }
  }

  Future<void> _check(DateTime now) async {
    final expenses = budget.monthExpenses(now.month);
    final level = budget.limitLevel(expenses);
    final levelNo = switch (level) {
      LimitLevel.ok => 0,
      LimitLevel.warn => 1,
      LimitLevel.over => 2,
    };
    final notified = settings.notifiedLevel(now.year, now.month);
    if (levelNo > notified) {
      final limit = level == LimitLevel.over ? budget.monthLimit2! : budget.monthLimit1!;
      final (title, body) = texts(level, expenses, limit);
      await sink.show(id: now.year * 100 + now.month, title: title, body: body);
      await settings.setNotifiedLevel(now.year, now.month, levelNo);
    } else if (levelNo < notified) {
      // Dropped below a limit again (entry deleted on the laptop): forget, so a new crossing notifies.
      await settings.setNotifiedLevel(now.year, now.month, levelNo);
    }
    // After the limit itself, so "limit 1 reached" comes before "reaching limit 2".
    await _checkApproach(1, now, expenses, level);
    await _checkApproach(2, now, expenses, level);
  }
}
