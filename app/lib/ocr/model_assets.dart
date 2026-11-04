/// Copies the bundled ONNX models from the APK assets into the app support
/// directory (the native code needs real file paths) and initialises the
/// OCR engine. The copy is versioned by `assets/models/VERSION`.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'receipt_ocr_ffi.dart';

class ModelAssets {
  static const List<String> files = [
    'ocr_det.onnx',
    'ocr_rec_v6.onnx',
    'ocr_rec_v6_dict.txt',
    'ocr_textline_ori.onnx',
  ];

  /// Files without which the engine cannot start.
  static const List<String> required = ['ocr_det.onnx', 'ocr_rec_v6.onnx', 'ocr_rec_v6_dict.txt'];

  static Future<String> modelsDir() async {
    final support = await getApplicationSupportDirectory();
    return p.join(support.path, 'models');
  }

  /// Ensure the models are on disk; returns the directory. Throws when the
  /// APK was built without the models (see scripts/download_models.sh).
  static Future<String> ensureInstalled() async {
    final dir = await modelsDir();
    await Directory(dir).create(recursive: true);
    String bundledVersion;
    try {
      bundledVersion = (await rootBundle.loadString('assets/models/VERSION')).trim();
    } catch (_) {
      bundledVersion = 'unknown';
    }
    final versionFile = File(p.join(dir, 'VERSION'));
    final installedVersion = versionFile.existsSync() ? versionFile.readAsStringSync().trim() : null;
    final allPresent = required.every((f) => File(p.join(dir, f)).existsSync());
    if (installedVersion == bundledVersion && allPresent) return dir;

    for (final f in files) {
      try {
        final data = await rootBundle.load('assets/models/$f');
        await File(p.join(dir, f)).writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      } catch (e) {
        if (required.contains(f)) {
          throw OcrException('model asset missing from the build: assets/models/$f ($e). '
              'Run scripts/download_models.sh before building.');
        }
      }
    }
    await versionFile.writeAsString(bundledVersion);
    return dir;
  }

  static Future<void> initEngine() async {
    final dir = await ensureInstalled();
    await ReceiptOcr.init(ReceiptOcrConfig(modelsDir: dir));
  }
}
