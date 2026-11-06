import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'budget/budget_service.dart';
import 'l10n/app_localizations.dart';
import 'ocr/engine_controller.dart';
import 'storage/app_settings.dart';
import 'theme.dart';
import 'ui/home_page.dart';
import 'ui/onboarding_page.dart';

/// Dependency scope: budget service, settings and the OCR engine, reachable
/// from any widget.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.budget, required this.settings, required this.engine, required super.child});

  final BudgetService budget;
  final AppSettings settings;
  final EngineController engine;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      budget != oldWidget.budget || settings != oldWidget.settings || engine != oldWidget.engine;
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key, required this.budget, required this.settings, required this.engine});

  final BudgetService budget;
  final AppSettings settings;
  final EngineController engine;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Like a Drive client: re-read the folder when the app comes back.
    if (state == AppLifecycleState.resumed && widget.settings.hasFolder) {
      widget.budget.sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      budget: widget.budget,
      settings: widget.settings,
      engine: widget.engine,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
        locale: widget.settings.localeCode.isEmpty ? null : Locale(widget.settings.localeCode),
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: azTheme(Brightness.light),
        darkTheme: azTheme(Brightness.dark),
        // A new user sees the start screen until a folder is chosen (or it is skipped).
        home: widget.settings.hasFolder || widget.settings.onboardingSeen ? const HomePage() : const OnboardingPage(),
        ),
      ),
    );
  }
}
