import 'package:flutter/foundation.dart';

/// Central configuration for API and local storage.
class AppConfig {
  AppConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local dev defaults:
  /// - Android emulator: http://10.0.2.2:5000
  /// - iOS simulator / desktop / web: http://127.0.0.1:5000
  ///
  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://YOUR_HOST:5000/api
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5000/api';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:5000/api';
    }
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'cached_user';
  static const String localAvatarKey = 'cached_local_avatar';
}
