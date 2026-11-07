import 'dart:io';

import 'package:az_budget/app.dart';
import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/l10n/app_localizations.dart';
import 'package:az_budget/ocr/engine_controller.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/ui/entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

void main() {
  testWidgets('typing a description suggests from every category; picking one from another switches the category', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Real I/O never completes under the test's fake async clock: run it outside.
    final settings = (await tester.runAsync(AppSettings.load))!;
    await tester.runAsync(() => settings.setFolder('tree', 'Budget'));
    final tmp = Directory.systemTemp.createTempSync('azauto');
    final budget = BudgetService(folder: FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync()), settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    await tester.runAsync(budget.sync);
    expect(budget.file, isNotNull);
    // A description that only exists in one category of the fixture.
    final sample = budget.file!.entries.firstWhere((e) => e.description.length >= 4 && e.category != 'Kinder');
    final typed = sample.description.substring(0, 3);

    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: AppScope(
        budget: budget,
        settings: settings,
        engine: EngineController(),
        child: Scaffold(body: EntryForm(budget: budget, draft: EntryDraft(category: 'Kinder'))),
      ),
    ));
    final description = find.byType(TextField).first;
    await tester.tap(description);
    await tester.enterText(description, typed);
    await tester.pump();

    final tile = find.widgetWithText(ListTile, sample.description);
    expect(tile, findsWidgets, reason: 'found outside the chosen category');
    // The other category is named under the suggestion.
    expect(find.descendant(of: tile.first, matching: find.text(sample.category)), findsOneWidget);

    await tester.tap(tile.first);
    await tester.pump();
    expect(find.widgetWithText(TextField, sample.description), findsOneWidget);
    expect(find.text(sample.category), findsWidgets, reason: 'the category switched');
    expect(find.byType(ListTile), findsNothing, reason: 'the list closes after a pick');
    await tester.binding.setSurfaceSize(null);
    tmp.deleteSync(recursive: true);
  });

  testWidgets('the description keeps focus when the first letter hides the category chips', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = (await tester.runAsync(AppSettings.load))!;
    await tester.runAsync(() => settings.setFolder('tree', 'Budget'));
    final tmp = Directory.systemTemp.createTempSync('azfocus');
    final budget = BudgetService(folder: FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync()), settings: settings, queueDir: tmp, clock: () => DateTime(2026, 4, 10));
    await tester.runAsync(budget.sync);
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: AppScope(
        budget: budget,
        settings: settings,
        engine: EngineController(),
        child: Scaffold(body: EntryForm(budget: budget, draft: EntryDraft(category: 'Lebensmittel'))),
      ),
    ));
    expect(find.byType(ActionChip), findsWidgets, reason: 'the chips show while the description is empty');
    final description = find.byType(TextField).first;
    await tester.tap(description);
    await tester.pump();
    FocusNode node() => tester.widget<EditableText>(find.descendant(of: find.byType(TextField).first, matching: find.byType(EditableText))).focusNode;
    expect(node().hasFocus, isTrue);
    // Type one letter the way the keyboard does (no re-focus by the test).
    tester.testTextInput.enterText('S');
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing, reason: 'the chips are gone after the first letter');
    expect(node().hasFocus, isTrue, reason: 'the field keeps the focus');
    tester.testTextInput.enterText('Sp');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Sp', reason: 'the second letter lands in the same field');
    expect(node().hasFocus, isTrue);
    await tester.binding.setSurfaceSize(null);
    tmp.deleteSync(recursive: true);
  });
}
