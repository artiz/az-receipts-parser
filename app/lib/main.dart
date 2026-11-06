import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app.dart';
import 'budget/limit_notifier.dart';
import 'budget/widget_updater.dart';
import 'budget/limit_texts.dart';
import 'budget/budget_service.dart';
import 'ocr/engine_controller.dart';
import 'storage/app_notifications.dart';
import 'storage/app_widget.dart';
import 'storage/app_settings.dart';
import 'storage/folder_access.dart';
import 'storage/share_receiver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final budget = BudgetService(
    folder: PlatformFolderAccess(),
    settings: settings,
    templateLoader: (lang) async => (await rootBundle.load('assets/templates/budget_$lang.xlsx')).buffer.asUint8List(),
  );
  // The OCR engine loads in the background; the budget syncs right away.
  final engine = EngineController()..start();
  final notifications = PlatformNotifications();
  LimitNotifier(
    budget: budget,
    settings: settings,
    sink: notifications,
    texts: (level, expenses, limit) => limitNotificationTexts(settings.localeCode, level, expenses, limit, symbol: settings.currencySymbol),
  );
  WidgetUpdater(budget: budget, sink: PlatformWidget(), symbol: () => settings.currencySymbol, localeCode: () => settings.localeCode);
  budget.init();
  notifications.requestPermission();
  final shares = ShareReceiver(PlatformShareSource());
  shares.init();
  runApp(BudgetApp(budget: budget, settings: settings, engine: engine, shares: shares));
}
