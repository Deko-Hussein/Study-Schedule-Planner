import 'package:flutter/foundation.dart';

/// Central configuration for API and local storage.
class AppConfig {
  AppConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local dev defaults:
  /// - Android emulator: http://10.0.2.2:5001
  /// - iOS simulator / desktop / web: http://127.0.0.1:5001
  ///
  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://YOUR_HOST:5001/api
  static String get baseUrl {
    final rawBaseUrl = _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : _defaultBaseUrl;
    return _normalizeBaseUrl(rawBaseUrl);
  }

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5001/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5001/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:5001/api';
    }
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final withoutTrailingSlash = trimmed.replaceFirst(RegExp(r'/+$'), '');
    return withoutTrailingSlash.endsWith('/api')
        ? withoutTrailingSlash
        : '$withoutTrailingSlash/api';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'cached_user';
  static const String localAvatarKey = 'cached_local_avatar';
}
