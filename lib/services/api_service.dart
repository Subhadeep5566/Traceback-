import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int statusCode = 200}) {
    return ApiResponse(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(String message, {int statusCode = 400}) {
    return ApiResponse(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'traceback_jwt_token';
  static const String _userKey = 'traceback_auth_user';

  // Base URL selection: Android emulator uses 10.0.2.2 to reach host localhost:5000
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> _headers([bool withAuth = true]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userKey);
    if (str != null) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAuth() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ==========================================
  // AUTH ENDPOINTS
  // ==========================================

  // POST /api/auth/register
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: _headers(false),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['token'] as String?;
        if (token != null) await setToken(token);
        if (data['user'] != null) await saveUser(data['user']);
        return ApiResponse.success(data, message: data['message'], statusCode: response.statusCode);
      } else {
        return ApiResponse.failure(data['message'] ?? 'Registration failed', statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[ApiService.register error] $e');
      return ApiResponse.failure('Network connection error: $e');
    }
  }

  // POST /api/auth/login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: _headers(false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'] as String?;
        if (token != null) await setToken(token);
        if (data['user'] != null) await saveUser(data['user']);
        return ApiResponse.success(data, message: data['message'], statusCode: response.statusCode);
      } else {
        return ApiResponse.failure(data['message'] ?? 'Invalid credentials', statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[ApiService.login error] $e');
      return ApiResponse.failure('Network connection error: $e');
    }
  }

  // ==========================================
  // USERS ENDPOINTS
  // ==========================================

  // GET /api/users/profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final url = Uri.parse('$baseUrl/users/profile');
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['user'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to load profile', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // PUT /api/users/profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({String? name, String? phone}) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (phone != null) payload['phone'] = phone;

      final url = Uri.parse('$baseUrl/users/profile');
      final response = await http.put(
        url,
        headers: _headers(true),
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['user'], message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to update profile', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // ==========================================
  // ITEMS ENDPOINTS
  // ==========================================

  // GET /api/items
  Future<ApiResponse<List<dynamic>>> getItems({String? status, String? search, String? tagId}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (tagId != null && tagId.isNotEmpty) queryParams['tag_id'] = tagId;

      final url = Uri.parse('$baseUrl/items').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['items'] as List<dynamic>, statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to fetch items', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // POST /api/items
  Future<ApiResponse<Map<String, dynamic>>> createItem({
    required String name,
    String? category,
    String? description,
    String? tagId,
    String? lastDetectedLocation,
    String? status,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/items');
      final response = await http.post(
        url,
        headers: _headers(true),
        body: jsonEncode({
          'name': name,
          'category': category ?? 'belonging',
          'description': description,
          'tag_id': tagId,
          'last_detected_location': lastDetectedLocation,
          'status': status ?? 'safe',
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data['item'], message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to create item', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // GET /api/items/:id
  Future<ApiResponse<Map<String, dynamic>>> getItemById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/items/$id');
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['item'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Item not found', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // PUT /api/items/:id
  Future<ApiResponse<Map<String, dynamic>>> updateItem(String id, Map<String, dynamic> updates) async {
    try {
      final url = Uri.parse('$baseUrl/items/$id');
      final response = await http.put(
        url,
        headers: _headers(true),
        body: jsonEncode(updates),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['item'], message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to update item', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // DELETE /api/items/:id
  Future<ApiResponse<void>> deleteItem(String id) async {
    try {
      final url = Uri.parse('$baseUrl/items/$id');
      final response = await http.delete(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null, message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to delete item', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // PUT /api/items/:id/lost
  Future<ApiResponse<Map<String, dynamic>>> markItemLost(String id, {String? location, String? description}) async {
    try {
      final payload = <String, dynamic>{};
      if (location != null) payload['location'] = location;
      if (description != null) payload['description'] = description;

      final url = Uri.parse('$baseUrl/items/$id/lost');
      final response = await http.put(
        url,
        headers: _headers(true),
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['item'], message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to mark item lost', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // PUT /api/items/:id/found
  Future<ApiResponse<Map<String, dynamic>>> markItemFound(String id, {String? location}) async {
    try {
      final payload = <String, dynamic>{};
      if (location != null) payload['location'] = location;

      final url = Uri.parse('$baseUrl/items/$id/found');
      final response = await http.put(
        url,
        headers: _headers(true),
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['item'], message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to mark item safe', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // ==========================================
  // FOUND REPORTS ENDPOINTS
  // ==========================================

  // POST /api/reports/found
  Future<ApiResponse<Map<String, dynamic>>> reportFound({
    String? itemId,
    String? tagId,
    String? location,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (itemId != null) payload['item_id'] = itemId;
      if (tagId != null) payload['tag_id'] = tagId;
      if (location != null) payload['location'] = location;
      if (note != null) payload['note'] = note;

      final url = Uri.parse('$baseUrl/reports/found');
      final response = await http.post(
        url,
        headers: _headers(true),
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data, message: data['message'], statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to submit found report', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // GET /api/reports/found
  Future<ApiResponse<List<dynamic>>> getFoundReports() async {
    try {
      final url = Uri.parse('$baseUrl/reports/found');
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['reports'] as List<dynamic>, statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to fetch found reports', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // ==========================================
  // NOTIFICATIONS ENDPOINTS
  // ==========================================

  // GET /api/notifications
  Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final url = Uri.parse('$baseUrl/notifications');
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['notifications'] as List<dynamic>, statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to fetch notifications', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // PUT /api/notifications/:id/read
  Future<ApiResponse<void>> markNotificationRead(dynamic id) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$id/read');
      final response = await http.put(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to update notification', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  // ==========================================
  // ACTIVITY ENDPOINTS
  // ==========================================

  // GET /api/activity
  Future<ApiResponse<List<dynamic>>> getActivity() async {
    try {
      final url = Uri.parse('$baseUrl/activity');
      final response = await http.get(url, headers: _headers(true));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['activity'] as List<dynamic>, statusCode: response.statusCode);
      }
      return ApiResponse.failure(data['message'] ?? 'Failed to fetch activity', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }
}
