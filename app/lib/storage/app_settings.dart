/// App-level settings: the chosen folder, the OpenAI model, and the API key
/// (secure storage). Budget settings (categories, limits, plan) live in the
/// xlsx itself, not here.
library;

import 'package:flutter/foundation.dart';

import '../budget/entry_suggest.dart' show QuickTile;
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
  static const _kLocale = 'locale';
  static const _kNotified = 'limit_notified_';
  static const _kOnboarding = 'onboarding_seen';
  static const _kBackups = 'backups';
  static const _kBackupsKept = 'backups_kept';
  static const _kInAppCamera = 'in_app_camera';
  static const _kAutoCapture = 'auto_capture';
  static const _kSavePhotos = 'save_photos';
  static const _kCurrency = 'currency';
  // Early warnings before Monatslimit 1 and 2; limit 1 keeps the keys it
  // had before limit 2 got its own warning.
  static String _approachKey(int limit, String name) => limit == 1 ? 'approach_$name' : 'approach${limit}_$name';

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

  /// '' = follow the system, else 'en' | 'de' | 'ru'.
  String get localeCode => _prefs.getString(_kLocale) ?? '';

  Future<void> setLocaleCode(String code) async {
    if (code.isEmpty) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, code);
    }
    notifyListeners();
  }

  /// Keep a copy of the year file in `.backup/` before each write.
  bool get backups => _prefs.getBool(_kBackups) ?? true;
  Future<void> setBackups(bool on) async {
    await _prefs.setBool(_kBackups, on);
    notifyListeners();
  }

  /// How many backups of a year file stay in `.backup/` (newest first).
  static const List<int> backupsKeptChoices = [1, 2, 3, 5, 10, 20];
  static const int defaultBackupsKept = 3;
  int get backupsKept => (_prefs.getInt(_kBackupsKept) ?? defaultBackupsKept).clamp(1, 100);
  Future<void> setBackupsKept(int n) async {
    await _prefs.setInt(_kBackupsKept, n.clamp(1, 100));
    notifyListeners();
  }

  /// Receipt photos with the app's own camera (guides, auto-capture);
  /// off: the phone's camera app, as before.
  bool get inAppCamera => _prefs.getBool(_kInAppCamera) ?? true;
  Future<void> setInAppCamera(bool on) async {
    await _prefs.setBool(_kInAppCamera, on);
    notifyListeners();
  }

  /// The app's camera shoots by itself once the receipt sits between the
  /// guide lines and the phone holds still.
  bool get autoCapture => _prefs.getBool(_kAutoCapture) ?? true;
  Future<void> setAutoCapture(bool on) async {
    await _prefs.setBool(_kAutoCapture, on);
    notifyListeners();
  }

  /// Store scanned receipt photos in `Belege/<year>/` next to the file.
  bool get savePhotos => _prefs.getBool(_kSavePhotos) ?? true;
  Future<void> setSavePhotos(bool on) async {
    await _prefs.setBool(_kSavePhotos, on);
    notifyListeners();
  }

  /// Symbol shown after amounts ('€' by default; the file does not care).
  String get currencySymbol => _prefs.getString(_kCurrency) ?? '€';
  Future<void> setCurrencySymbol(String symbol) async {
    final s = symbol.trim();
    if (s.isEmpty) {
      await _prefs.remove(_kCurrency);
    } else {
      await _prefs.setString(_kCurrency, s);
    }
    notifyListeners();
  }

  /// Quick tiles pinned by the user, in order (keys of QuickTile.tileKey).
  List<String> get pinnedTiles => _prefs.getStringList('pinned_tiles') ?? const [];

  /// Pin [key], or unpin it when a key with the same category and
  /// description (case and accents aside) is pinned already.
  Future<void> togglePinnedTile(String key) async {
    final list = List<String>.of(pinnedTiles);
    final lk = QuickTile.lookupKey(key);
    final before = list.length;
    list.removeWhere((k) => QuickTile.lookupKey(k) == lk);
    if (list.length == before) list.add(key);
    await _prefs.setStringList('pinned_tiles', list);
    notifyListeners();
  }

  bool isPinnedTile(String key) {
    final lk = QuickTile.lookupKey(key);
    return pinnedTiles.any((k) => QuickTile.lookupKey(k) == lk);
  }

  /// The "reaching limit [limit]" notification (1 or 2) was shown for the month.
  bool approachNotified(int limit, int year, int month) => _prefs.getBool(_approachKey(limit, 'notified_$year-$month')) ?? false;
  Future<void> setApproachNotified(int limit, int year, int month, bool on) => _prefs.setBool(_approachKey(limit, 'notified_$year-$month'), on);

  /// Send the "reaching limit [limit]" notification at all (on by default).
  bool approachEnabled(int limit) => _prefs.getBool(_approachKey(limit, 'enabled')) ?? true;
  Future<void> setApproachEnabled(int limit, bool on) async {
    await _prefs.setBool(_approachKey(limit, 'enabled'), on);
    notifyListeners();
  }

  /// How far below limit [limit] the warning comes: a share of the limit
  /// (5 % by default) or a fixed amount below it. Both values are kept so
  /// switching the mode back restores the other one.
  ApproachMargin approachMargin(int limit) => ApproachMargin(
        byAmount: _prefs.getBool(_approachKey(limit, 'by_amount')) ?? false,
        percent: _prefs.getDouble(_approachKey(limit, 'percent')) ?? ApproachMargin.defaultPercent,
        amount: _prefs.getDouble(_approachKey(limit, 'amount')) ?? ApproachMargin.defaultAmount,
      );
  Future<void> setApproachMargin(int limit, ApproachMargin m) async {
    await _prefs.setBool(_approachKey(limit, 'by_amount'), m.byAmount);
    await _prefs.setDouble(_approachKey(limit, 'percent'), m.percent);
    await _prefs.setDouble(_approachKey(limit, 'amount'), m.amount);
    notifyListeners();
  }

  /// The start screen was shown (or skipped) once.
  bool get onboardingSeen => _prefs.getBool(_kOnboarding) ?? false;

  Future<void> setOnboardingSeen(bool seen) async {
    await _prefs.setBool(_kOnboarding, seen);
    notifyListeners();
  }

  /// Highest limit level already notified for a month (0 none, 1 warn, 2 over).
  int notifiedLevel(int year, int month) => _prefs.getInt('$_kNotified$year-$month') ?? 0;

  Future<void> setNotifiedLevel(int year, int month, int level) => _prefs.setInt('$_kNotified$year-$month', level);

  DateTime? get lastSync {
    final v = _prefs.getString(_kLastSync);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLastSync(DateTime t) async {
    await _prefs.setString(_kLastSync, t.toIso8601String());
    notifyListeners();
  }
}

/// Distance below a month limit at which the early warning is sent.
class ApproachMargin {
  const ApproachMargin({required this.byAmount, required this.percent, required this.amount});

  static const double defaultPercent = 5;
  static const double defaultAmount = 100;

  /// False: [percent] of the limit; true: [amount] in money below it.
  final bool byAmount;
  final double percent;
  final double amount;

  /// The expenses from which on the warning is due, or null when the margin
  /// makes no sense for this limit (margin covers the whole limit or more).
  double? threshold(double limit) {
    final t = byAmount ? limit - amount : limit * (1 - percent / 100);
    return t > 0 && t < limit ? t : null;
  }

  ApproachMargin copyWith({bool? byAmount, double? percent, double? amount}) =>
      ApproachMargin(byAmount: byAmount ?? this.byAmount, percent: percent ?? this.percent, amount: amount ?? this.amount);
}
