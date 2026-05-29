import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _localAvatar;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  String get userName => _user?['name']?.toString() ?? '';
  String get userEmail => _user?['email']?.toString() ?? '';
  String get userMajor => _user?['major']?.toString() ?? '';
  String get userAvatar => _localAvatar ?? _user?['avatar']?.toString() ?? '';
  String get subscription => _user?['subscription']?.toString() ?? 'free';
  Map<String, dynamic> get notifications =>
      (_user?['notifications'] as Map<String, dynamic>?) ??
      {'reminderTime': '15 Mins', 'alertSound': 'Classic Chime'};

  AuthProvider() {
    _loadCached();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);
    final cached = prefs.getString(AppConfig.userKey);
    if (token != null && cached != null) {
      _user = jsonDecode(cached) as Map<String, dynamic>;
      notifyListeners();
      // refresh from server silently
      await _refreshProfile();
    } else if (token == null && cached != null) {
      await prefs.remove(AppConfig.userKey);
    }

    final cachedAvatar = prefs.getString(AppConfig.localAvatarKey);
    if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
      _localAvatar = cachedAvatar;
      notifyListeners();
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final data = await ApiService.getMe();
      await _cacheUser(data['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
  }

  Future<void> _cacheUser(Map<String, dynamic> user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(user));
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? major,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.register(
          name: name, email: email, password: password, major: major);
      await ApiService.saveToken(data['token'] as String);
      await _cacheUser(data['user'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error =
          'Connection error. Could not reach ${AppConfig.baseUrl}. Start the backend server and make sure MongoDB is available.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.login(email: email, password: password);
      await ApiService.saveToken(data['token'] as String);
      await _cacheUser(data['user'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error =
          'Connection error. Could not reach ${AppConfig.baseUrl}. Start the backend server and make sure MongoDB is available.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    _localAvatar = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.localAvatarKey);
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.updateMe(data);
      _cacheUser(result['user'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Connection error';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cacheProfilePatch(Map<String, dynamic> data) async {
    if (_user == null) {
      return;
    }

    _user = {
      ...?_user,
      ...data,
    };

    if (data.containsKey('avatar')) {
      _localAvatar = data['avatar']?.toString();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(_user));
    if (_localAvatar != null && _localAvatar!.isNotEmpty) {
      await prefs.setString(AppConfig.localAvatarKey, _localAvatar!);
    }
    notifyListeners();
  }

  Future<void> cacheLocalAvatar(String avatar) async {
    _localAvatar = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.localAvatarKey, avatar);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
