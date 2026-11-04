import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/receipt_repository.dart';
import 'ocr/engine_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final repo = ReceiptRepository(db);
  final engine = EngineController()..start();
  runApp(ReceiptsApp(repository: repo, engine: engine));
}
