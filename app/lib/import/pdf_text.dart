/// PDF text layer through the native library (docling.rs `convert_text_layer`).
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

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

  static String _extractSync(String path) {
    final lib = ReceiptOcr.library();
    final fn = lib.lookupFunction<_PdfTextC, _PdfTextDart>('receipt_ocr_pdf_text');
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
