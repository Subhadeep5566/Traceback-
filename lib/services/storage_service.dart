import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/incident.dart';
import '../models/recovery_report.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _assetsJsonBoxName = 'assets_json_store';
  static const String _incidentsJsonBoxName = 'incidents_json_store';

  static const String _prefKeyAssetsJson = 'stored_assets_json';
  static const String _prefKeyIncidentsJson = 'stored_incidents_json';
  static const String _prefKeyReportsJson = 'stored_reports_json';
  static const String _prefKeyUserProfileJson = 'stored_user_profile_json';
  static const String _prefKeyAdminConfigJson = 'stored_admin_config_json';

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastLogin = 'last_login';

  Box<String>? _assetsJsonBox;
  Box<String>? _incidentsJsonBox;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    if (!WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      try {
        await Hive.initFlutter();
        if (_assetsJsonBox == null || !_assetsJsonBox!.isOpen) {
          _assetsJsonBox = await Hive.openBox<String>(_assetsJsonBoxName);
        }
        if (_incidentsJsonBox == null || !_incidentsJsonBox!.isOpen) {
          _incidentsJsonBox = await Hive.openBox<String>(_incidentsJsonBoxName);
        }
      } catch (e) {
        debugPrint('StorageService Hive init fallback to SharedPreferences: $e');
      }
    }
  }

  Future<void> saveAssets(List<Asset> assets) async {
    try {
      final jsonList = assets.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Save to SharedPreferences for bulletproof persistence
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefKeyAssetsJson, jsonString);

      // Also save to Hive if available
      if (_assetsJsonBox != null && _assetsJsonBox!.isOpen) {
        await _assetsJsonBox!.put('all_assets', jsonString);
      }
    } catch (e) {
      debugPrint('StorageService saveAssets error: $e');
    }
  }

  List<Asset> loadAssets() {
    try {
      String? jsonString;

      if (_assetsJsonBox != null && _assetsJsonBox!.isOpen) {
        jsonString = _assetsJsonBox!.get('all_assets');
      }

      jsonString ??= _prefs?.getString(_prefKeyAssetsJson);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => Asset.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('StorageService loadAssets error: $e');
    }
    return [];
  }

  Future<void> saveIncidents(List<Incident> incidents) async {
    try {
      final jsonList = incidents.map((i) => i.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefKeyIncidentsJson, jsonString);

      if (_incidentsJsonBox != null && _incidentsJsonBox!.isOpen) {
        await _incidentsJsonBox!.put('all_incidents', jsonString);
      }
    } catch (e) {
      debugPrint('StorageService saveIncidents error: $e');
    }
  }

  List<Incident> loadIncidents() {
    try {
      String? jsonString;

      if (_incidentsJsonBox != null && _incidentsJsonBox!.isOpen) {
        jsonString = _incidentsJsonBox!.get('all_incidents');
      }

      jsonString ??= _prefs?.getString(_prefKeyIncidentsJson);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => Incident.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('StorageService loadIncidents error: $e');
    }
    return [];
  }

  Future<void> saveReports(List<RecoveryReport> reports) async {
    try {
      final jsonList = reports.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefKeyReportsJson, jsonString);
    } catch (e) {
      debugPrint('StorageService saveReports error: $e');
    }
  }

  List<RecoveryReport> loadReports() {
    try {
      final jsonString = _prefs?.getString(_prefKeyReportsJson);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => RecoveryReport.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('StorageService loadReports error: $e');
    }
    return [];
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefKeyUserProfileJson, jsonString);
      await prefs.setString(_keyUserRole, profile.role.name);
    } catch (e) {
      debugPrint('StorageService saveUserProfile error: $e');
    }
  }

  UserProfile? loadUserProfile() {
    try {
      final jsonString = _prefs?.getString(_prefKeyUserProfileJson);
      if (jsonString != null && jsonString.isNotEmpty) {
        return UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('StorageService loadUserProfile error: $e');
    }
    return null;
  }

  Future<void> saveAdminConfig(UserProfile adminProfile) async {
    try {
      final jsonString = jsonEncode(adminProfile.toJson());
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefKeyAdminConfigJson, jsonString);
    } catch (e) {
      debugPrint('StorageService saveAdminConfig error: $e');
    }
  }

  UserProfile loadAdminConfig() {
    try {
      final jsonString = _prefs?.getString(_prefKeyAdminConfigJson);
      if (jsonString != null && jsonString.isNotEmpty) {
        return UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('StorageService loadAdminConfig error: $e');
    }
    return UserProfile.defaultAdmin();
  }

  Future<void> saveUserSession({
    required bool isLoggedIn,
    String? phone,
    String? name,
    String? email,
    UserRole? role,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (phone != null) await prefs.setString(_keyUserPhone, phone);
    if (name != null) await prefs.setString(_keyUserName, name);
    if (email != null) await prefs.setString(_keyUserEmail, email);
    if (role != null) await prefs.setString(_keyUserRole, role.name);
    if (isLoggedIn) await prefs.setString(_keyLastLogin, DateTime.now().toIso8601String());
  }

  bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  String? get userPhone => _prefs?.getString(_keyUserPhone);
  String? get userName => _prefs?.getString(_keyUserName);
  String? get userEmail => _prefs?.getString(_keyUserEmail);
  String? get lastLogin => _prefs?.getString(_keyLastLogin);
  UserRole get userRole => (_prefs?.getString(_keyUserRole) == 'admin') ? UserRole.admin : UserRole.student;

  Future<void> clearSession() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (_) {}
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.get(key) ?? defaultValue;
  }

  Future<void> close() async {
    try {
      await _assetsJsonBox?.close();
      await _incidentsJsonBox?.close();
    } catch (_) {}
  }
}