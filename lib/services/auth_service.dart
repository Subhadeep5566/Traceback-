import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/demo_data_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

enum AuthMode {
  production,
  demo,
}

class AuthService extends ChangeNotifier {
  static const String _bguEmailDomain = 'bgu.edu.in';
  static const List<String> allowedEmailDomains = ['bgu.edu.in', 'bgu.ac.in'];

  final StorageService _storageService;
  final FirestoreService _firestoreService;
  AuthMode _authMode = AuthMode.production;
  UserProfile? _userProfile;

  AuthService(this._storageService, [FirestoreService? firestoreService])
      : _firestoreService = firestoreService ?? FirestoreService() {
    _initProfile();
  }

  void _initProfile() {
    _userProfile = _storageService.loadUserProfile();
    if (_userProfile == null && _storageService.isLoggedIn) {
      final role = _storageService.userRole;
      if (role == UserRole.admin) {
        _userProfile = UserProfile.defaultAdmin(
          name: _storageService.userName,
          email: _storageService.userEmail,
          phone: _storageService.userPhone,
        );
      } else {
        _userProfile = UserProfile.defaultStudent(
          name: _storageService.userName,
          email: _storageService.userEmail,
          phone: _storageService.userPhone,
        );
      }
    }
  }

  StorageService get storageService => _storageService;

  AuthMode get authMode => _authMode;
  bool get isDemoMode => _authMode == AuthMode.demo;

  bool get isLoggedIn => _authMode == AuthMode.demo ? true : _storageService.isLoggedIn;
  String? get userPhone => _authMode == AuthMode.demo
      ? (_userProfile?.phone ?? DemoDataService.demoUserPhone)
      : (_userProfile?.phone ?? _storageService.userPhone);
  String? get userName => _authMode == AuthMode.demo
      ? (_userProfile?.name ?? DemoDataService.demoUserName)
      : (_userProfile?.name ?? _storageService.userName);
  String? get userEmail => _authMode == AuthMode.demo
      ? (_userProfile?.email ?? DemoDataService.demoUserEmail)
      : (_userProfile?.email ?? _storageService.userEmail);

  UserProfile get currentUserProfile {
    if (_userProfile != null) return _userProfile!;
    if (isDemoMode) return UserProfile.defaultStudent();
    return UserProfile.defaultStudent(name: userName, email: userEmail, phone: userPhone);
  }

  UserRole get currentRole => currentUserProfile.role;
  bool get isStudent => currentRole == UserRole.student;
  bool get isAdmin => currentRole == UserRole.admin;

  Future<void> switchRole(UserRole targetRole) async {
    if (targetRole == UserRole.admin) {
      final adminConfig = _storageService.loadAdminConfig();
      _userProfile = adminConfig.copyWith(role: UserRole.admin);
    } else {
      _userProfile = UserProfile.defaultStudent(
        name: _storageService.userName ?? 'Subhadeep',
        email: _storageService.userEmail ?? 'student@bgu.ac.in',
        phone: _storageService.userPhone ?? '9876543210',
      );
    }
    if (!isDemoMode) {
      await _storageService.saveUserProfile(_userProfile!);
      await _storageService.saveUserSession(
        isLoggedIn: true,
        name: _userProfile!.name,
        email: _userProfile!.email,
        phone: _userProfile!.phone,
        role: targetRole,
      );
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    _userProfile = updated;
    if (updated.isAdmin) {
      await _storageService.saveAdminConfig(updated);
    }
    if (!isDemoMode) {
      await _storageService.saveUserProfile(updated);
      await _storageService.saveUserSession(
        isLoggedIn: true,
        name: updated.name,
        email: updated.email,
        phone: updated.phone,
        role: updated.role,
      );
    }
    notifyListeners();
  }

  Future<void> enterDemoMode({UserRole role = UserRole.student}) async {
    _authMode = AuthMode.demo;
    if (role == UserRole.admin) {
      _userProfile = UserProfile.defaultAdmin();
    } else {
      _userProfile = UserProfile.defaultStudent(
        name: DemoDataService.demoUserName,
        email: DemoDataService.demoUserEmail,
        phone: DemoDataService.demoUserPhone,
      );
    }
    notifyListeners();
  }

  static String get bguEmailDomain => _bguEmailDomain;

  static String normalizePhone(String rawPhone) {
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static bool isValidPhone(String phone) {
    final normalized = normalizePhone(phone);
    return normalized.length == 10;
  }

  static bool isBguEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@')) return false;
    final domain = normalized.split('@').last;
    return domain == 'bgu.edu.in' ||
        domain == 'bgu.ac.in' ||
        domain.endsWith('.bgu.edu.in') ||
        domain.endsWith('.bgu.ac.in');
  }

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    return RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$")
        .hasMatch(trimmed);
  }

  Future<AuthResult> registerWithEmailPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.user,
    String? city,
    String? studentId,
    String? department,
  }) async {
    try {
      final trimmedName = name.trim();
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPhone = normalizePhone(phone);

      if (trimmedName.isEmpty) {
        return AuthResult.failure('Please enter your full name');
      }
      if (normalizedEmail.isEmpty) {
        return AuthResult.failure('Please enter your email address');
      }
      if (!isValidEmail(normalizedEmail)) {
        return AuthResult.failure('Please enter a valid email address');
      }
      if (normalizedPhone.isEmpty) {
        return AuthResult.failure('Please enter your phone number');
      }
      if (!isValidPhone(normalizedPhone)) {
        return AuthResult.failure('Please enter a valid 10-digit phone number');
      }
      if (password.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters');
      }

      String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Register with Node.js + Express + MySQL Backend
      final api = ApiService();
      final apiRes = await api.register(
        name: trimmedName,
        email: normalizedEmail,
        password: password,
        phone: normalizedPhone,
      );

      if (!apiRes.isSuccess) {
        return AuthResult.failure(apiRes.message ?? 'Registration failed');
      } else if (apiRes.data?['user'] != null) {
        final userData = apiRes.data!['user'] as Map<String, dynamic>;
        uid = userData['id']?.toString() ?? uid;
      }

      if (Firebase.apps.isNotEmpty) {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
          await credential.user?.updateDisplayName(trimmedName);
          uid = credential.user?.uid ?? uid;
        } on FirebaseAuthException catch (_) {
          // Firebase fallback is non-fatal when MySQL succeeded
        }
      }

      _authMode = AuthMode.production;
      if (role == UserRole.admin) {
        _userProfile = UserProfile(
          userId: uid,
          name: trimmedName,
          email: normalizedEmail,
          phone: normalizedPhone,
          role: UserRole.admin,
          city: city ?? 'Bhubaneswar',
          designation: 'Property & Recovery Officer',
          office: 'Traceback Asset Recovery Office',
          officeLocation: 'Room G-04',
          contactMethod: 'Phone & Message',
        );
      } else {
        _userProfile = UserProfile(
          userId: uid,
          name: trimmedName,
          email: normalizedEmail,
          phone: normalizedPhone,
          role: UserRole.user,
          city: city ?? 'Bhubaneswar',
          studentId: studentId ?? '',
          department: department ?? '',
          sharePhone: true,
          shareEmail: true,
          shareStudentId: false,
        );
      }

      await _firestoreService.saveUserProfile(_userProfile!);
      await _storageService.saveUserProfile(_userProfile!);
      await _storageService.saveUserSession(
        isLoggedIn: true,
        phone: normalizedPhone,
        name: trimmedName,
        email: normalizedEmail,
        role: role,
      );

      notifyListeners();
      return AuthResult.success(name: trimmedName, phone: normalizedPhone);
    } catch (e, stackTrace) {
      debugPrint('AuthService register error: $e\n$stackTrace');
      return AuthResult.failure('Registration error: ${e.toString()}');
    }
  }

  Future<AuthResult> login({
    required String email,
    String? phone,
    String? password,
    UserRole role = UserRole.user,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPhone = phone != null ? normalizePhone(phone) : '';

      if (normalizedEmail.isEmpty) {
        return AuthResult.failure('Please enter your email address');
      }
      if (password == null || password.isEmpty) {
        return AuthResult.failure('Please enter your password');
      }

      String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      String name = _extractNameFromEmail(normalizedEmail);
      String userPhoneNum = normalizedPhone;

      // 1. Authenticate with Node.js + Express + MySQL Backend
      final api = ApiService();
      final apiRes = await api.login(email: normalizedEmail, password: password);
      if (apiRes.isSuccess && apiRes.data?['user'] != null) {
        final userData = apiRes.data!['user'] as Map<String, dynamic>;
        uid = userData['id']?.toString() ?? uid;
        name = userData['name']?.toString() ?? name;
        userPhoneNum = userData['phone']?.toString() ?? userPhoneNum;
      } else if (!apiRes.isSuccess) {
        return AuthResult.failure(apiRes.message ?? 'Invalid email or password');
      }

      if (Firebase.apps.isNotEmpty) {
        try {
          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
          uid = credential.user?.uid ?? uid;
          name = credential.user?.displayName ?? name;

          final remoteProfile = await _firestoreService.getUserProfile(uid);
          if (remoteProfile != null) {
            _userProfile = remoteProfile;
            name = remoteProfile.name;
            userPhoneNum = remoteProfile.phone;
          }
        } on FirebaseAuthException catch (_) {
          // Firebase fallback non-fatal
        }
      }

      _authMode = AuthMode.production;
      if (_userProfile == null) {
        if (role == UserRole.admin) {
          _userProfile = UserProfile.defaultAdmin(name: name, email: normalizedEmail, phone: userPhoneNum);
        } else {
          _userProfile = UserProfile.defaultStudent(name: name, email: normalizedEmail, phone: userPhoneNum);
        }
        await _firestoreService.saveUserProfile(_userProfile!);
      }

      await _storageService.saveUserProfile(_userProfile!);
      await _storageService.saveUserSession(
        isLoggedIn: true,
        phone: userPhoneNum,
        name: name,
        email: normalizedEmail,
        role: _userProfile!.role,
      );

      notifyListeners();
      return AuthResult.success(name: name, phone: userPhoneNum);
    } catch (e, stackTrace) {
      debugPrint('AuthService login error: $e\n$stackTrace');
      return AuthResult.failure('Authentication error. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      _authMode = AuthMode.production;
      _userProfile = null;
      await ApiService().clearAuth();
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      await _storageService.clearSession();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService logout error: $e');
    }
  }

  String _extractNameFromEmail(String email) {
    try {
      final localPart = email.split('@').first;
      final cleaned = localPart
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\d+'), '')
          .trim();

      if (cleaned.isEmpty) {
        return 'User';
      }

      return cleaned
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
    } catch (_) {
      return 'User';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? name;
  final String? phone;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.name,
    this.phone,
  });

  factory AuthResult.success({required String name, required String phone}) {
    return AuthResult._(isSuccess: true, name: name, phone: phone);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(isSuccess: false, errorMessage: errorMessage);
  }
}