import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Wraps every API call: attaches Bearer token, decodes JSON,
/// and throws descriptive errors instead of crashing.
class ApiService {
  ApiService._();

  // ── Token helpers ──────────────────────────────────────────────────────────

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

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(body['error']?.toString() ?? 'Request failed', res.statusCode);
    }
    return body;
  }

  static Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    return params != null ? uri.replace(queryParameters: params) : uri;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? major,
  }) async {
    final res = await http.post(
      _uri('/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'major': major ?? ''}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _uri('/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  // ── User profile ───────────────────────────────────────────────────────────

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

  // ── Reminders ──────────────────────────────────────────────────────────────

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

  // ── Subjects ───────────────────────────────────────────────────────────────

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

  static Future<Map<String, dynamic>> updateSubject(String id, Map<String, dynamic> data) async {
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

  // ── Schedules ──────────────────────────────────────────────────────────────

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
    final res = await http.patch(_uri('/schedules/$id/complete'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteSchedule(String id) async {
    final res = await http.delete(_uri('/schedules/$id'), headers: await _headers());
    return _decode(res);
  }

  // ── Tasks ──────────────────────────────────────────────────────────────────

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
    final res = await http.patch(_uri('/tasks/$id/complete'), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> deleteTask(String id) async {
    final res = await http.delete(_uri('/tasks/$id'), headers: await _headers());
    return _decode(res);
  }
}

/// Thrown when the server returns a 4xx / 5xx response.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
