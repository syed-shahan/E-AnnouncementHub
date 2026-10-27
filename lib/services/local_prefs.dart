// local_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static SharedPreferences? _prefs;
  static const _keyEmailSubmitted = 'email_submitted';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get hasSubmittedEmail => _prefs?.getBool(_keyEmailSubmitted) ?? false;
  static Future<void> setSubmittedEmail(bool v) async {
    await _prefs?.setBool(_keyEmailSubmitted, v);
  }
}
