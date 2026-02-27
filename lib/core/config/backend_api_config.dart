import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendApiConfig {
  static String get baseUrl =>
      _fromDotEnv('BACKEND_API_LAN_URL') ??
      _fromDotEnv('BACKEND_API_URL') ??
      _fromDefine('BACKEND_API_LAN_URL') ??
      _fromDefine('BACKEND_API_URL') ??
      '';
  static String get apiToken =>
      _fromDotEnv('BACKEND_API_TOKEN') ??
      const String.fromEnvironment('BACKEND_API_TOKEN', defaultValue: '');

  static bool get isEnabled => baseUrl.trim().isNotEmpty;
  static bool get hasToken => apiToken.trim().isNotEmpty;

  static String? _fromDotEnv(String key) {
    try {
      final value = dotenv.maybeGet(key);
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  static String? _fromDefine(String key) {
    final value = String.fromEnvironment(key, defaultValue: '').trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }
}

