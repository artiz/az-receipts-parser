import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'budget/budget_service.dart';
import 'l10n/app_localizations.dart';
import 'ocr/engine_controller.dart';
import 'storage/app_settings.dart';
import 'storage/share_receiver.dart';
import 'theme.dart';
import 'ui/home_page.dart';
import 'ui/onboarding_page.dart';
import 'ui/scan_flow.dart';

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
  const BudgetApp({super.key, required this.budget, required this.settings, required this.engine, this.shares});

  final BudgetService budget;
  final AppSettings settings;
  final EngineController engine;

  /// Files shared into the app (null when the platform has no share sheet).
  final ShareReceiver? shares;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  bool _handlingShare = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.shares?.addListener(_onShare);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShare());
  }

  @override
  void dispose() {
    widget.shares?.removeListener(_onShare);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Route shared files one after another: images to the receipt scanner,
  /// PDFs to the PDF import, text to the model. Needs a folder with a file.
  Future<void> _onShare() async {
    final shares = widget.shares;
    if (shares == null || !shares.hasItems || _handlingShare) return;
    _handlingShare = true;
    try {
      final items = shares.take();
      final context = _navigator.currentContext;
      if (context == null) return;
      final l = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (!widget.settings.hasFolder) {
        messenger?.showSnackBar(SnackBar(content: Text(l.shareNoFolder)));
        return;
      }
      await widget.budget.sync();
      if (widget.budget.file == null) {
        messenger?.showSnackBar(SnackBar(content: Text(l.shareNoFolder)));
        return;
      }
      for (final item in items) {
        final ctx = _navigator.currentContext;
        if (ctx == null || !ctx.mounted) return;
        try {
          if (item.error != null || (item.path == null && item.text == null)) {
            ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(content: Text(l.importFailed(item.error ?? item.name))));
          } else if (item.isText) {
            await importSharedText(ctx, item.text!);
          } else if (item.isPdf) {
            await importPdfFile(ctx, item.path!, name: item.name);
          } else if (item.isImage) {
            await receiptFromImageFile(ctx, item.path!);
          } else {
            ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(content: Text(l.shareUnsupported(item.name))));
          }
        } finally {
          await shares.source.discard(item);
        }
      }
    } finally {
      _handlingShare = false;
    }
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
        navigatorKey: _navigator,
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
