/// Central configuration – change baseUrl to match your backend.
class AppConfig {
  AppConfig._();

  /// Local dev: http://localhost:5000
  /// Production: replace with your deployed URL
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Token key for SharedPreferences
  static const String tokenKey = 'auth_token';
  static const String userKey  = 'cached_user';
  static const String localAvatarKey = 'cached_local_avatar';
}
