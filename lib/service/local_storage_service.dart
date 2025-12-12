// lib/service/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;
  static const _keyAccessToken = 'access_token';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save access token
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyAccessToken, token);
  }

  static String? get token => _prefs?.getString(_keyAccessToken);

  // Generic methods - use these everywhere now
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }
}