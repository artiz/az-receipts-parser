import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/receipt_repository.dart';
import 'l10n/app_localizations.dart';
import 'ocr/engine_controller.dart';
import 'ui/home_page.dart';

/// Dependency scope: repository + engine, reachable from any widget.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repository, required this.engine, required super.child});

  final ReceiptRepository repository;
  final EngineController engine;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository || engine != oldWidget.engine;
}

class ReceiptsApp extends StatelessWidget {
  const ReceiptsApp({super.key, required this.repository, required this.engine});

  final ReceiptRepository repository;
  final EngineController engine;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      engine: engine,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF00695C),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF00695C),
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const HomePage(),
      ),
    );
  }
}
