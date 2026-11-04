/// Camera → OCR → parse → categorise → detail page.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app.dart';
import '../l10n/app_localizations.dart';
import '../ocr/receipt_ocr_ffi.dart';
import '../parser/parsed_receipt.dart';
import '../parser/receipt_parser.dart';
import 'receipt_detail_page.dart';

Future<void> startScanFlow(BuildContext context) async {
  final picker = ImagePicker();
  final shot = await picker.pickImage(source: ImageSource.camera, imageQuality: 92);
  if (shot == null || !context.mounted) return;
  await processPhoto(context, shot.path);
}

/// Shared by the camera flow and (later) any import path.
Future<void> processPhoto(BuildContext context, String sourcePath) async {
  final l = AppLocalizations.of(context);
  final scope = AppScope.of(context);
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Keep the photo in the app's documents directory.
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'receipts'));
  await dir.create(recursive: true);
  final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
  final target = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
  await File(sourcePath).copy(target);

  if (!context.mounted) return;
  // Progress dialog while the native OCR runs.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(l.scanning),
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(l.scanningHint)),
        ],
      ),
    ),
  );

  ParsedReceipt? parsed;
  String? ocrJson;
  String? error;
  try {
    await scope.engine.ensureReady();
    final scan = await ReceiptOcr.scanFile(target);
    ocrJson = scan.json;
    parsed = ReceiptParser().parse(scan.result);
    final categorizer = await scope.repository.loadCategorizer();
    categorizer.apply(parsed);
  } on OcrException catch (e) {
    error = e.message;
  } catch (e) {
    error = e.toString();
  }
  navigator.pop(); // progress dialog

  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(l.ocrFailed(error))));
    return;
  }
  await navigator.push(MaterialPageRoute<void>(
    builder: (_) => ReceiptDetailPage.create(parsed: parsed!, imagePath: target, ocrJson: ocrJson),
  ));
}
