import 'dart:io';

import 'package:az_budget/budget/budget_file.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/budget/limit_notifier.dart';
import 'package:az_budget/budget/limit_texts.dart';
import 'package:az_budget/storage/app_notifications.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

class FakeSink implements NotificationSink {
  final List<(int, String, String)> shown = [];
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> show({required int id, required String title, required String body}) async => shown.add((id, title, body));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('limits: level, editing, notification once per crossing', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    final tmp = await Directory.systemTemp.createTemp('azlimit');
    final folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    // April 2026: the fixture has no April bookings yet.
    final service = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    final sink = FakeSink();
    LimitNotifier(
      budget: service,
      settings: settings,
      sink: sink,
      clock: () => DateTime(2026, 4, 10),
      texts: (lv, e, l) => limitNotificationTexts('de', lv, e, l),
      approachTexts: (e, l) => approachNotificationTexts('de', e, l),
    );
    await settings.setFolder('tree', 'Budget');
    await service.sync();
    expect(service.monthLimit1, 3000);
    expect(service.limitLevel(2999), LimitLevel.ok);
    expect(service.limitLevel(3000), LimitLevel.warn);
    expect(service.limitLevel(4000), LimitLevel.over);
    expect(service.currentMonthLevel, LimitLevel.ok);
    expect(sink.shown, isEmpty);

    await service.setMonthLimits(100, 200);
    expect(service.monthLimit1, 100);
    expect(service.monthLimit2, 200);

    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Wohnen', description: 'Miete', amount: 150));
    await service.sync();
    expect(service.monthExpenses(4), 150);
    expect(service.currentMonthLevel, LimitLevel.warn);
    expect(sink.shown.length, 1);
    expect(sink.shown.first.$2, 'Limit 1 erreicht');
    expect(sink.shown.first.$3, contains('150 €'));

    await service.sync(); // no second notification for the same level
    expect(sink.shown.length, 1);

    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Lebensmittel', description: 'Spar', amount: 80));
    await service.sync();
    expect(service.currentMonthLevel, LimitLevel.over);
    expect(sink.shown.length, 2);
    expect(sink.shown.last.$2, 'Limit 2 überschritten');
    // Income does not count.
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Einnahmen', description: 'Gehalt', amount: -1000));
    await service.sync();
    expect(service.monthExpenses(4), 230);

    // Early warning: within 5 % of limit 1 (the default margin), the limit
    // itself not reached, once per month.
    await service.setMonthLimits(1000, 2000); // 230 of 1000: nothing
    final before = sink.shown.length;
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Ikea', amount: 600)); // 830 < 950
    await service.sync();
    expect(sink.shown.length, before, reason: '80 % is not near enough with a 5 % margin');
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Lampe', amount: 130)); // 960 ≥ 950
    await service.sync();
    expect(sink.shown.length, before + 1);
    expect(sink.shown.last.$2, 'Limit 1 fast erreicht');
    expect(sink.shown.last.$3, matches(RegExp(r'^Ausgaben diesen Monat: 960 € von 1[.\s\u00A0\u202F]000 €\.$')));
    await service.sync();
    expect(sink.shown.length, before + 1, reason: 'once');

    // A wider margin as a fixed amount: 300 below the limit, i.e. from 700
    // on; the month is already flagged, so nothing new until it drops below.
    await settings.setApproachMargin(const ApproachMargin(byAmount: true, percent: 5, amount: 300));
    await service.sync();
    expect(sink.shown.length, before + 1);
    // Switched off: no warning even after the flag is forgotten.
    await settings.setApproachNotified(2026, 4, false);
    await settings.setApproachEnabled(false);
    await service.sync();
    expect(sink.shown.length, before + 1, reason: 'switched off');
    await settings.setApproachEnabled(true); // the settings change re-checks by itself
    await Future<void>.delayed(Duration.zero);
    expect(sink.shown.length, before + 2);
    expect(sink.shown.last.$3, startsWith('Ausgaben diesen Monat: 960 €'));

    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Regal', amount: 100)); // 1060: limit 1 itself
    await service.sync();
    expect(sink.shown.last.$2, 'Limit 1 erreicht');
    await tmp.delete(recursive: true);
  });

  test('approach margin: percent or amount below limit 1, nonsense margins disable it', () {
    const pct = ApproachMargin(byAmount: false, percent: 5, amount: 100);
    expect(pct.threshold(1000), 950);
    expect(pct.copyWith(percent: 20).threshold(500), 400);
    expect(pct.copyWith(percent: 100).threshold(1000), isNull, reason: 'would fire at zero expenses');
    const amt = ApproachMargin(byAmount: true, percent: 5, amount: 100);
    expect(amt.threshold(1000), 900);
    expect(amt.threshold(100), isNull, reason: 'margin covers the whole limit');
    expect(amt.copyWith(amount: 0).threshold(1000), isNull, reason: 'no margin means limit 1 itself');
    // Both values are kept across a mode switch.
    final m = const ApproachMargin(byAmount: false, percent: 10, amount: 250).copyWith(byAmount: true);
    expect((m.byAmount, m.percent, m.amount), (true, 10.0, 250.0));
  });
}
