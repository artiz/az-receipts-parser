import 'dart:io';

import 'package:az_budget/app.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/l10n/app_localizations.dart';
import 'package:az_budget/ocr/engine_controller.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/ui/overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

void main() {
  testWidgets('year table: a category expands to its months and descriptions; a month chip opens that month', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Real I/O never completes under the test's fake async clock: run it outside.
    final settings = (await tester.runAsync(AppSettings.load))!;
    await tester.runAsync(() => settings.setFolder('tree', 'Budget'));
    final tmp = Directory.systemTemp.createTempSync('azyear');
    final budget = BudgetService(folder: FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync()), settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    await tester.runAsync(budget.sync);
    expect(budget.file, isNotNull);

    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: AppScope(budget: budget, settings: settings, engine: EngineController(), child: OverviewPage(budget: budget)),
    ));
    await tester.pumpAndSettle();

    // Month menu → "Jahr".
    await tester.tap(find.byType(DropdownButton<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jahr').last);
    await tester.pumpAndSettle();
    expect(find.text('Nach Kategorie: Ist / Plan / Vorjahr'), findsOneWidget);
    expect(find.text('Nach Monat (antippen öffnet den Monat)'), findsNothing, reason: 'rows start closed');

    // Lebensmittel has bookings in Jan, Feb and Mar of the fixture.
    // Tap the name: the middle of an expanded row is its breakdown (chips).
    final row = find.text('Lebensmittel');
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Nach Monat (antippen öffnet den Monat)'), findsOneWidget);
    final chips = find.byType(ActionChip);
    expect(chips, findsNWidgets(3), reason: 'one chip per month with an amount');
    expect(find.descendant(of: chips.first, matching: find.textContaining('Jan')), findsOneWidget);

    // Tap again: closed.
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);

    // Open again and jump to February.
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(ActionChip), matching: find.textContaining('Feb')));
    await tester.pumpAndSettle();
    expect(find.text('Nach Kategorie: Ist / Plan / Vorjahr'), findsNothing, reason: 'the month view is open');
    final month = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>).last);
    expect(month.value, 2);

    await tester.binding.setSurfaceSize(null);
    tmp.deleteSync(recursive: true);
  });
}
