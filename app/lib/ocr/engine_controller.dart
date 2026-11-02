/// Loads the OCR engine once, in the background, and exposes its state.
library;

import 'package:flutter/foundation.dart';

import 'model_assets.dart';
import 'receipt_ocr_ffi.dart';

enum EngineState { idle, loading, ready, error }

class EngineController extends ChangeNotifier {
  EngineState state = EngineState.idle;
  String? error;
  String? version;
  Future<void>? _loading;

  Future<void> start() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    state = EngineState.loading;
    error = null;
    notifyListeners();
    try {
      await ModelAssets.initEngine();
      version = ReceiptOcr.version();
      state = EngineState.ready;
    } catch (e) {
      error = e.toString();
      state = EngineState.error;
      _loading = null;
    }
    notifyListeners();
  }

  /// Wait for the engine; throws the load error when it failed.
  Future<void> ensureReady() async {
    await start();
    if (state != EngineState.ready) throw OcrException(error ?? 'engine not ready');
  }
}
