import 'dart:io';

import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/budget/widget_updater.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/storage/app_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

class FakeWidget implements WidgetSink {
  final List<(String, String, int)> updates = [];
  @override
  Future<void> update({required String title, required String amount, required int color}) async => updates.add((title, amount, color));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the widget gets the month, expenses against limit 1 and the limit colour', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await settings.setFolder('tree', 'Budget');
    final tmp = await Directory.systemTemp.createTemp('azbudget');
    final folder = FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync());
    final now = DateTime(2026, 3, 15);
    final s = BudgetService(folder: folder, settings: settings, queueDir: tmp, clock: () => now);
    final sink = FakeWidget();
    final updater = WidgetUpdater(budget: s, sink: sink, symbol: () => '€', localeCode: () => 'de', clock: () => now);
    await s.sync();
    await updater.update();
    expect(sink.updates, isNotEmpty);
    final (title, amount, color) = sink.updates.last;
    expect(title, 'März');
    expect(amount, matches(RegExp(r'^\d[\d.\s\u00A0\u202F]* / 3[.\s\u00A0\u202F]000 €$'))); // de_AT groups with a narrow space
    expect(color, [0xFF3BA55D, 0xFFD9A400, 0xFFFF2E7E][s.limitLevel(s.monthExpenses(3)).index]);
    // The fake records every call (the platform sink skips unchanged numbers).
    final before = sink.updates.length;
    await updater.update();
    expect(sink.updates.length, before + 1);
    expect(sink.updates.last, sink.updates[before - 1]);
    updater.dispose();
    await tmp.delete(recursive: true);
  });
}
