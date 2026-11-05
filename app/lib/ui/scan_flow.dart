/// The three capture paths:
/// * receipt photo → OCR → parser → one entry to confirm;
/// * banking screenshot → OCR → LLM → review list;
/// * statement PDF → text layer → LLM → review list.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app.dart';
import '../budget/receipt_to_entry.dart';
import '../import/openai_client.dart';
import '../import/pdf_text.dart';
import '../import/statement_import.dart';
import '../l10n/app_localizations.dart';
import '../ocr/receipt_ocr_ffi.dart';
import '../parser/receipt_parser.dart';
import 'entry_actions.dart';
import 'entry_sheet.dart';
import 'import_review_page.dart';

Future<void> scanReceipt(BuildContext context) async {
  unawaited(AppScope.of(context).budget.sync());
  final shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
  if (shot == null || !context.mounted) return;
  await _receiptFromPhoto(context, shot.path);
}

Future<void> importScreenshot(BuildContext context) async {
  final shot = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (shot == null || !context.mounted) return;
  final l = AppLocalizations.of(context);
  final text = await _withProgress<String?>(context, l.scanning, l.scanningHint, () async {
    final scope = AppScope.of(context);
    await scope.engine.ensureReady();
    final scan = await ReceiptOcr.scanFile(shot.path);
    // Reading order: top to bottom, left to right, one line per box row.
    final lines = scan.result.lines.toList()..sort((a, b) => a.cy != b.cy ? a.cy.compareTo(b.cy) : a.x0.compareTo(b.x0));
    final buf = StringBuffer();
    double? lastCy;
    for (final ln in lines) {
      if (lastCy != null && (ln.cy - lastCy).abs() > ln.height * 0.6) buf.writeln();
      buf.write('${ln.text}  ');
      lastCy = ln.cy;
    }
    return buf.toString();
  });
  if (text == null || !context.mounted) return;
  await _importText(context, text, sourceDescription: l.sourceScreenshot);
}

Future<void> importStatement(BuildContext context) async {
  final scope = AppScope.of(context);
  final l = AppLocalizations.of(context);
  final doc = await scope.budget.folder.pickDocument(const ['application/pdf']);
  if (doc == null || !context.mounted) return;
  final text = await _withProgress<String?>(context, l.importRunning, l.importReadingPdf, () async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'statement_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(doc.bytes, flush: true);
    try {
      return await PdfText.extract(file.path);
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  });
  if (text == null || !context.mounted) return;
  if (text.trim().length < 40) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.importNoText)));
    return;
  }
  await _importText(context, text, sourceDescription: doc.name);
}

Future<void> _importText(BuildContext context, String text, {required String sourceDescription}) async {
  final scope = AppScope.of(context);
  final l = AppLocalizations.of(context);
  final key = scope.settings.openAiApiKey;
  if (key == null || key.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.openAiKeyMissing)));
    return;
  }
  final budget = scope.budget;
  final importer = StatementImporter(
    client: OpenAiClient(apiKey: key, model: scope.settings.openAiModel),
    categories: budget.categories,
    existing: budget.entries,
  );
  final hint = ValueNotifier<String>(l.importLlmHint(scope.settings.openAiModel));
  final result = await _withProgress<StatementImportResult?>(
    context,
    l.importRunning,
    hint,
    () => importer.import(
      text,
      sourceDescription: sourceDescription,
      onProgress: (done, total) {
        if (total > 1) hint.value = '${l.importLlmHint(scope.settings.openAiModel)} ${l.importPart(done + 1 > total ? total : done + 1, total)}';
      },
    ),
  );
  if (result == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ImportReviewPage(result: result)));
}

Future<void> _receiptFromPhoto(BuildContext context, String sourcePath) async {
  final l = AppLocalizations.of(context);
  final scope = AppScope.of(context);
  final draft = await _withProgress<EntryDraft?>(context, l.scanning, l.scanningHint, () async {
    await scope.engine.ensureReady();
    final scan = await ReceiptOcr.scanFile(sourcePath);
    final parsed = ReceiptParser().parse(scan.result);
    return receiptToDraft(parsed, categories: scope.budget.categories, suggestions: scope.budget.suggestions);
  });
  if (draft == null || !context.mounted) return;
  final entry = await showEntrySheet(context, budget: scope.budget, draft: draft, title: l.receiptConfirm);
  if (entry == null || !context.mounted) return;
  await saveNewEntry(context, scope.budget, entry);
}

/// Runs [work] behind a progress dialog; errors become a snackbar and null.
Future<T?> _withProgress<T>(BuildContext context, String title, Object hint, Future<T> Function() work) async {
  final hintListenable = hint is ValueNotifier<String> ? hint : ValueNotifier<String>(hint.toString());
  final l = AppLocalizations.of(context);
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: ValueListenableBuilder<String>(valueListenable: hintListenable, builder: (_, v, _) => Text(v))),
        ],
      ),
    ),
  );
  T? result;
  String? error;
  try {
    result = await work();
  } on OcrException catch (e) {
    error = e.message;
  } on OpenAiException catch (e) {
    error = e.message;
  } catch (e) {
    error = e.toString();
  }
  navigator.pop();
  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(error))));
    return null;
  }
  return result;
}
