/// dart:ffi binding for `rust/receipt_ocr` (`libreceipt_ocr.so`).
///
/// The native engine is process-global, so initialisation happens once; scans
/// run in a background isolate (`Isolate.run`) because the FFI call blocks
/// for ~1–3 s per photo on a phone.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'ocr_types.dart';

typedef _InitC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _InitDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _ScanFileC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _ScanFileDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _FreeC = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);
typedef _VersionC = Pointer<Utf8> Function();
typedef _VersionDart = Pointer<Utf8> Function();
typedef _ReadyC = Int32 Function();
typedef _ReadyDart = int Function();

class OcrException implements Exception {
  OcrException(this.message);
  final String message;
  @override
  String toString() => 'OcrException: $message';
}

class _Bindings {
  _Bindings(DynamicLibrary lib)
      : init = lib.lookupFunction<_InitC, _InitDart>('receipt_ocr_init'),
        scanFile = lib.lookupFunction<_ScanFileC, _ScanFileDart>('receipt_ocr_scan_file'),
        free = lib.lookupFunction<_FreeC, _FreeDart>('receipt_ocr_free'),
        version = lib.lookupFunction<_VersionC, _VersionDart>('receipt_ocr_version'),
        isReady = lib.lookupFunction<_ReadyC, _ReadyDart>('receipt_ocr_is_ready');

  final _InitDart init;
  final _ScanFileDart scanFile;
  final _FreeDart free;
  final _VersionDart version;
  final _ReadyDart isReady;

  static _Bindings? _instance;

  static _Bindings get instance => _instance ??= _Bindings(_open());

  static DynamicLibrary _open() {
    if (Platform.isAndroid) {
      // Pre-load the ONNX Runtime packaged by the onnxruntime-android AAR so
      // the Rust side's dlopen("libonnxruntime.so") resolves inside the app's
      // own library directory.
      try {
        DynamicLibrary.open('libonnxruntime.so');
      } catch (_) {
        // Reported by receipt_ocr_init if it is really missing.
      }
      return DynamicLibrary.open('libreceipt_ocr.so');
    }
    final override = Platform.environment['RECEIPT_OCR_LIB'];
    if (override != null && override.isNotEmpty) return DynamicLibrary.open(override);
    if (Platform.isLinux) return DynamicLibrary.open('libreceipt_ocr.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libreceipt_ocr.dylib');
    if (Platform.isWindows) return DynamicLibrary.open('receipt_ocr.dll');
    throw OcrException('unsupported platform ${Platform.operatingSystem}');
  }
}

class ReceiptOcrConfig {
  const ReceiptOcrConfig({
    required this.modelsDir,
    this.ortLib,
    this.maxSide = 2500,
    this.textlineOrientation = true,
    this.detThreads = 2,
    this.recLanes = 2,
  });

  final String modelsDir;
  final String? ortLib;
  final int maxSide;
  final bool textlineOrientation;
  final int detThreads;
  final int recLanes;

  Map<String, dynamic> toJson() => {
        'models_dir': modelsDir,
        if (ortLib != null) 'ort_lib': ortLib,
        'max_side': maxSide,
        'textline_orientation': textlineOrientation,
        'det_threads': detThreads,
        'rec_lanes': recLanes,
      };
}

class ReceiptOcr {
  ReceiptOcr._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// The loaded native library (shared with the PDF text binding).
  static DynamicLibrary library() => _Bindings._open();

  static String version() {
    final b = _Bindings.instance;
    return b.version().toDartString();
  }

  /// Load the models. Runs on a background isolate; the native engine is
  /// shared by every isolate of the process.
  static Future<void> init(ReceiptOcrConfig config) async {
    final json = jsonEncode(config.toJson());
    final error = await Isolate.run(() => _initSync(json));
    if (error != null) throw OcrException(error);
    _initialized = true;
  }

  static String? _initSync(String configJson) {
    final b = _Bindings.instance;
    final cfg = configJson.toNativeUtf8();
    try {
      final err = b.init(cfg);
      if (err == nullptr) return null;
      final msg = err.toDartString();
      b.free(err);
      return msg;
    } finally {
      malloc.free(cfg);
    }
  }

  /// OCR a photo file; returns the parsed result and the raw JSON (stored
  /// with the receipt for later re-parsing).
  static Future<({OcrResult result, String json})> scanFile(String path) async {
    final json = await Isolate.run(() => _scanSync(path));
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw OcrException(map['error']?.toString() ?? 'unknown OCR error');
    }
    return (result: OcrResult.fromJson(map), json: json);
  }

  static String _scanSync(String path) {
    final b = _Bindings.instance;
    final p = path.toNativeUtf8();
    try {
      final out = b.scanFile(p);
      try {
        return out.toDartString();
      } finally {
        b.free(out);
      }
    } finally {
      malloc.free(p);
    }
  }
}
