import 'package:flutter/material.dart';

import 'app.dart';
import 'budget/budget_service.dart';
import 'ocr/engine_controller.dart';
import 'storage/app_settings.dart';
import 'storage/folder_access.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final budget = BudgetService(folder: PlatformFolderAccess(), settings: settings);
  // The OCR engine loads in the background; the budget syncs right away.
  final engine = EngineController()..start();
  budget.init();
  runApp(BudgetApp(budget: budget, settings: settings, engine: engine));
}
