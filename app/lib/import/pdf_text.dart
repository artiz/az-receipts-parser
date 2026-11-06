/// PDF text layer through the native library (docling.rs `convert_text_layer`).
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../ocr/ocr_types.dart';
import '../ocr/receipt_ocr_ffi.dart';

typedef _PdfTextC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _PdfTextDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _FreeC = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class PdfText {
  PdfText._();

  /// Markdown text of the PDF's text layer; empty when the PDF is scanned.
  static Future<String> extract(String path) async {
    final json = await Isolate.run(() => _extractSync(path));
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['ok'] != true) throw OcrException(map['error']?.toString() ?? 'pdf text failed');
    return (map['text'] as String?) ?? '';
  }

  /// The text layer as OCR lines with their boxes (PDF points), so a digital
  /// receipt goes through the receipt parser like a photo. Empty lines mean
  /// a scanned PDF.
  static Future<OcrResult> extractLines(String path) async {
    final json = await Isolate.run(() => _callSync('receipt_ocr_pdf_lines', path));
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['ok'] != true) throw OcrException(map['error']?.toString() ?? 'pdf lines failed');
    return OcrResult.fromJson(map);
  }

  static String _extractSync(String path) => _callSync('receipt_ocr_pdf_text', path);

  static String _callSync(String symbol, String path) {
    final lib = ReceiptOcr.library();
    final _PdfTextDart fn;
    try {
      fn = lib.lookupFunction<_PdfTextC, _PdfTextDart>(symbol);
    } on ArgumentError {
      // An app built with --no-rust on top of an older native library.
      throw OcrException('native library has no $symbol: rebuild with the Rust step (scripts/build_android.bat without --no-rust)');
    }
    final free = lib.lookupFunction<_FreeC, _FreeDart>('receipt_ocr_free');
    final p = path.toNativeUtf8();
    try {
      final out = fn(p);
      try {
        return out.toDartString();
      } finally {
        free(out);
      }
    } finally {
      malloc.free(p);
    }
  }
}
