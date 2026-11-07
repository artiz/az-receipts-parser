import 'dart:io';

import 'package:az_budget/budget/budget_service.dart';
import 'package:az_budget/l10n/app_localizations.dart';
import 'package:az_budget/storage/app_settings.dart';
import 'package:az_budget/ui/entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_service_test.dart' show FakeFolder;

void main() {
  testWidgets('openEntrySheets counts the form while it is open, so the quick tiles can hide', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Real I/O never completes under the test's fake async clock: run it outside.
    final settings = (await tester.runAsync(AppSettings.load))!;
    final tmp = Directory.systemTemp.createTempSync('azsheet');
    final budget = BudgetService(folder: FakeFolder(File('test/fixtures/budget_small.xlsx').readAsBytesSync()), settings: settings, queueDir: tmp);
    final seen = <int>[];
    openEntrySheets.addListener(() => seen.add(openEntrySheets.value));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(onPressed: () => showEntrySheet(context, budget: budget), child: const Text('open')),
        ),
      ),
    ));
    expect(openEntrySheets.value, 0);
    await tester.tap(find.text('open'));
    // Not pumpAndSettle: the form may show a spinner while the background sync runs.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(openEntrySheets.value, 1);
    expect(find.byType(EntryForm), findsOneWidget);
    // Dismiss by tapping the barrier above the sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(openEntrySheets.value, 0);
    expect(seen, [1, 0]);
    tmp.deleteSync(recursive: true);
  });
}
