/// Golden OCR fixtures produced by `rust/receipt_ocr` on `samples/receipts`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:az_receipts/ocr/ocr_types.dart';
import 'package:path/path.dart' as p;

String goldenDir() {
  // Tests run from app/; the fixtures live in the repo's samples/golden.
  for (final candidate in [
    p.join(Directory.current.path, '..', 'samples', 'golden'),
    p.join(Directory.current.path, 'samples', 'golden'),
  ]) {
    if (Directory(candidate).existsSync()) return candidate;
  }
  throw StateError('samples/golden not found from ${Directory.current.path}');
}

OcrResult loadGolden(String name) {
  final file = File(p.join(goldenDir(), '$name.ocr.json'));
  return OcrResult.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
}

List<String> goldenNames() => Directory(goldenDir())
    .listSync()
    .whereType<File>()
    .map((f) => p.basename(f.path))
    .where((n) => n.endsWith('.ocr.json'))
    .map((n) => n.substring(0, n.length - '.ocr.json'.length))
    .toList()
  ..sort();
