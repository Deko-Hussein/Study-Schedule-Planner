import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Wraps API calls between Flutter and the backend.
///
/// Auth flow:
/// 1. Take email and password from the UI.
/// 2. Send them to `/auth/login`.
/// 3. Let the backend validate the account.
/// 4. Return the `token` and `user` payload to the caller.
class ApiService {
  ApiService._();

  // --- Token helpers ---

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  // --- HTTP helpers ---

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.trim().isEmpty) {
      throw ApiException('Empty response from server', res.statusCode);
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from server', res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        decoded['error']?.toString() ?? 'Request failed',
        res.statusCode,
      );
    }

    return decoded;
  }

  static Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    return params != null ? uri.replace(queryParameters: params) : uri;
  }

  static Map<String, dynamic> _requireAuthPayload(Map<String, dynamic> body) {
    final token = body['token'];
    final user = body['user'];

    if (token is! String || token.isEmpty) {
      throw const ApiException('Server did not return a valid token', 500);
    }

    if (user is! Map<String, dynamic>) {
      throw const ApiException('Server did not return valid user data', 500);
    }

    return {
      'token': token,
      'user': user,
    };
  }

  // --- Auth ---

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? major,
  }) async {
    final res = await http.post(
      _uri('/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'major': major ?? '',
      }),
    );
    return _requireAuthPayload(_decode(res));
  }

  /// Sends email and password to `/auth/login`.
  /// The backend verifies the account and returns `token` plus `user`.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _uri('/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _requireAuthPayload(_decode(res));
  }

  // --- User profile ---

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(_uri('/users/me'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final res = await http.put(
      _uri('/users/me'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  // --- Reminders ---

  static Future<Map<String, dynamic>> getReminders() async {
    final res = await http.get(_uri('/reminders'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> updateReminders(Map<String, dynamic> data) async {
    final res = await http.put(
      _uri('/reminders'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  // --- Subjects ---

  static Future<Map<String, dynamic>> getSubjects() async {
    final res = await http.get(_uri('/subjects'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    final res = await http.post(
      _uri('/subjects'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> updateSubject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      _uri('/subjects/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteSubject(String id) async {
    final res = await http.delete(_uri('/subjects/$id'), headers: await _headers());
    return _decode(res);
  }

  // --- Schedules ---

  static Future<Map<String, dynamic>> getSchedules({String? date}) async {
    final res = await http.get(
      _uri('/schedules', date != null ? {'date': date} : null),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    final res = await http.post(
      _uri('/schedules'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> toggleScheduleComplete(String id) async {
    final res = await http.patch(
      _uri('/schedules/$id/complete'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteSchedule(String id) async {
    final res = await http.delete(_uri('/schedules/$id'), headers: await _headers());
    return _decode(res);
  }

  // --- Tasks ---

  static Future<Map<String, dynamic>> getTasks({bool? completed}) async {
    final params = completed != null ? {'completed': completed.toString()} : null;
    final res = await http.get(_uri('/tasks', params), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getTaskHistory() async {
    final res = await http.get(_uri('/tasks/history'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final res = await http.post(
      _uri('/tasks'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> toggleTaskComplete(String id) async {
    final res = await http.patch(
      _uri('/tasks/$id/complete'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteTask(String id) async {
    final res = await http.delete(_uri('/tasks/$id'), headers: await _headers());
    return _decode(res);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
