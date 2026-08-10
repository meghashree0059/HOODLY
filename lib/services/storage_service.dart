import 'package:shared_preferences/shared_preferences.dart';

/// Local key-value storage service backed by SharedPreferences.
///
/// Usage:
/// ```dart
/// final storage = await StorageService.instance;
/// await storage.setBool(StorageKeys.hasSeenOnboarding, true);
/// ```
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static StorageService? _instance;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._(await SharedPreferences.getInstance());
    return _instance!;
  }

  // ── Getters ──────────────────────────────────────────────────
  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // ── Setters ──────────────────────────────────────────────────
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ── Removal ──────────────────────────────────────────────────
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
  bool containsKey(String key) => _prefs.containsKey(key);
}

/// Centralised storage key constants.
abstract final class StorageKeys {
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String isLoggedIn = 'is_logged_in';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userFullName = 'user_full_name';
  static const String authToken = 'auth_token';
  static const String themeMode = 'theme_mode';
  static const String selectedLanguage = 'selected_language';
}
