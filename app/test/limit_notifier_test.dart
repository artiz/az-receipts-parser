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

    // Early warning: 80 % of limit 1 spent, the limit itself not reached, once per month.
    await service.setMonthLimits(1000, 2000); // 230 of 1000: nothing
    final before = sink.shown.length;
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Ikea', amount: 600)); // 830 ≥ 800
    await service.sync();
    expect(sink.shown.length, before + 1);
    expect(sink.shown.last.$2, 'Limit 1 fast erreicht');
    expect(sink.shown.last.$3, matches(RegExp(r'^Ausgaben diesen Monat: 830 € von 1[.\s\u00A0\u202F]000 €\.$')));
    await service.sync();
    expect(sink.shown.length, before + 1, reason: 'once');
    await service.addEntry(BudgetEntry(date: DateTime(2026, 4, 9), category: 'Haushalt', description: 'Lampe', amount: 200)); // 1030: limit 1 itself
    await service.sync();
    expect(sink.shown.last.$2, 'Limit 1 erreicht');
    await tmp.delete(recursive: true);
  });
}
