// lib/service/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;
  static const _keyAccessToken = 'access_token';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyAccessToken, token);
  }

  static String? get token => _prefs?.getString(_keyAccessToken);

  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
