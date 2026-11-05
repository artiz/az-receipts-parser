/// App-level settings: the chosen folder, the OpenAI model, and the API key
/// (secure storage). Budget settings (categories, limits, plan) live in the
/// xlsx itself, not here.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultOpenAiModel = 'gpt-4.1-mini';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _kFolderUri = 'folder_uri';
  static const _kFolderName = 'folder_name';
  static const _kModel = 'openai_model';
  static const _kApiKey = 'openai_api_key';
  static const _kLastSync = 'last_sync';

  String? _apiKey;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    final s = AppSettings._(prefs, secure);
    try {
      s._apiKey = await secure.read(key: _kApiKey);
    } catch (_) {
      s._apiKey = null;
    }
    return s;
  }

  String? get folderUri => _prefs.getString(_kFolderUri);
  String? get folderName => _prefs.getString(_kFolderName);
  bool get hasFolder => folderUri != null;

  Future<void> setFolder(String? uri, String? name) async {
    if (uri == null) {
      await _prefs.remove(_kFolderUri);
      await _prefs.remove(_kFolderName);
    } else {
      await _prefs.setString(_kFolderUri, uri);
      await _prefs.setString(_kFolderName, name ?? '');
    }
    notifyListeners();
  }

  String get openAiModel => _prefs.getString(_kModel) ?? defaultOpenAiModel;

  Future<void> setOpenAiModel(String model) async {
    await _prefs.setString(_kModel, model.trim().isEmpty ? defaultOpenAiModel : model.trim());
    notifyListeners();
  }

  String? get openAiApiKey => _apiKey;
  bool get hasOpenAiKey => (_apiKey ?? '').isNotEmpty;

  Future<void> setOpenAiApiKey(String? key) async {
    final k = key?.trim();
    _apiKey = (k == null || k.isEmpty) ? null : k;
    try {
      if (_apiKey == null) {
        await _secure.delete(key: _kApiKey);
      } else {
        await _secure.write(key: _kApiKey, value: _apiKey);
      }
    } catch (_) {
      // Secure storage can be unavailable on exotic devices; keep in memory.
    }
    notifyListeners();
  }

  DateTime? get lastSync {
    final v = _prefs.getString(_kLastSync);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLastSync(DateTime t) async {
    await _prefs.setString(_kLastSync, t.toIso8601String());
    notifyListeners();
  }
}
