import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class ApiConfig {
  static const _prefsKey = 'api_base_url';

  static String _baseUrl = ApiConstants.defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static bool get isWirelessAccess =>
      _baseUrl.contains('tunnel') || _baseUrl.contains('trycloudflare.com') || _baseUrl.contains('yourdomain.com');

  static String get connectionType => isWirelessAccess ? 'Wireless (Cloudflare Tunnel)' : 'Local Network';

  /// Base URL without the `/api` suffix, used for Socket.IO.
  static String get socketBaseUrl {
    final url = _baseUrl;
    if (url.endsWith('/api')) return url.substring(0, url.length - 4);
    return url;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _baseUrl = _normalize(saved);
    } else {
      _baseUrl = _normalize(ApiConstants.defaultBaseUrl);
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    _baseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
  }

  static Future<void> resetToDefault() async {
    _baseUrl = _normalize(ApiConstants.defaultBaseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static String _normalize(String raw) {
    var url = raw.trim();
    // For convenience allow entering without trailing `/api`.
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.endsWith('/api')) url = '$url/api';
    return url;
  }
}

