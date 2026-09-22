import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/models/recovery_report.dart';
import 'package:traceback/models/user_profile.dart';
import 'package:traceback/services/auth_service.dart';
import 'package:traceback/services/firestore_service.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Backend & Privacy Integration Tests', () {
    late StorageService storageService;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
      authService = AuthService(storageService);
    });

    test('BGU Email Domain Validation for Registration and Login', () {
      expect(AuthService.isBguEmail('student@bgu.ac.in'), isTrue);
      expect(AuthService.isBguEmail('admin@bgu.edu.in'), isTrue);
      expect(AuthService.isBguEmail('faculty@cs.bgu.edu.in'), isTrue);
      expect(AuthService.isBguEmail('user@gmail.com'), isFalse);
      expect(AuthService.isBguEmail('hacker@yahoo.com'), isFalse);
    });

    test('10-digit Indian Mobile Phone Normalization & Validation', () {
      expect(AuthService.isValidPhone('9876543210'), isTrue);
      expect(AuthService.isValidPhone('+919876543210'), isTrue);
      expect(AuthService.isValidPhone('09876543210'), isTrue);
      expect(AuthService.isValidPhone('12345'), isFalse);
      expect(AuthService.normalizePhone('+91 98765 43210'), equals('9876543210'));
    });

    test('Registration creates UserProfile with secure fields without plaintext password storage', () async {
      final res = await authService.registerWithEmailPassword(
        name: 'Subhadeep Das',
        email: 'subhadeep@bgu.ac.in',
        phone: '9876543210',
        password: 'securePassword123',
      );

      expect(res.isSuccess, isTrue);
      final profile = authService.currentUserProfile;
      expect(profile.name, equals('Subhadeep Das'));
      expect(profile.email, equals('subhadeep@bgu.ac.in'));
      expect(profile.phone, equals('9876543210'));
      expect(profile.role, equals(UserRole.user));

      // Verify privacy defaults
      expect(profile.sharePhone, isTrue);
      expect(profile.shareEmail, isTrue);
      expect(profile.shareStudentId, isFalse);

      // Verify password is NOT stored anywhere in UserProfile json
      final profileJson = profile.toJson();
      expect(profileJson.containsKey('password'), isFalse);
    });

    test('Owner Privacy Enforcement: Phone and Email hiding', () {
      final privateProfile = UserProfile(
        userId: 'usr_priv_01',
        name: 'Anonymous Student',
        email: 'anon@bgu.ac.in',
        phone: '9123456780',
        role: UserRole.student,
        sharePhone: false,
        shareEmail: false,
      );

      expect(privateProfile.sharePhone, isFalse);
      expect(privateProfile.shareEmail, isFalse);

      final publicProfile = privateProfile.copyWith(sharePhone: true, shareEmail: true);
      expect(publicProfile.sharePhone, isTrue);
      expect(publicProfile.shareEmail, isTrue);
    });

    test('RecoveryReport serialization matches Cloud Firestore schema', () {
      final now = DateTime.now();
      final report = RecoveryReport(
        reportId: 'REP-001',
        reporterId: 'usr_finder_99',
        reporterRole: UserRole.student,
        reporterName: 'Finder Rahul',
        reporterContact: '9876543210',
        assetId: 'AST-001',
        tracebackId: 'TB-BIKE-001',
        reportType: ReportType.found,
        location: 'Campus Canteen Entrance',
        timestamp: now,
        description: 'Found parked near counter',
      );

      final json = report.toJson();
      expect(json['reportId'], equals('REP-001'));
      expect(json['assetId'], equals('AST-001'));
      expect(json['tracebackId'], equals('TB-BIKE-001'));
      expect(json['reportType'], equals('found'));
      expect(json['location'], equals('Campus Canteen Entrance'));

      final restored = RecoveryReport.fromJson(json);
      expect(restored.reportId, equals(report.reportId));
      expect(restored.tracebackId, equals(report.tracebackId));
      expect(restored.reporterName, equals('Finder Rahul'));
    });

    test('Belonging serialization handles full telemetry & tag fields', () {
      final now = DateTime.now();
      final asset = Asset(
        id: 'AST-100',
        tracebackId: 'TB-TEST-100',
        ownerId: 'student_100',
        name: 'Test Device',
        category: AssetCategory.electronics,
        brand: 'Dell',
        model: 'XPS 15',
        color: 'Silver',
        description: 'Work machine',
        status: AssetStatus.safe,
        createdAt: now,
        updatedAt: now,
        latitude: 20.3015,
        longitude: 85.7482,
        address: 'BGU Campus, Bhubaneswar',
        lastPing: now,
      );

      final json = asset.toJson();
      expect(json['id'], equals('AST-100'));
      expect(json['tracebackId'], equals('TB-TEST-100'));
      expect(json['ownerId'], equals('student_100'));
      expect(json['status'], equals(AssetStatus.safe.index));

      final restored = Asset.fromJson(json);
      expect(restored.id, equals(asset.id));
      expect(restored.tracebackId, equals('TB-TEST-100'));
      expect(restored.name, equals('Test Device'));
    });

    test('FirestoreService handles uninitialized Firebase gracefully in test sandbox', () async {
      final firestoreService = FirestoreService();
      
      // Should not throw even when running headless unit test
      final stats = await firestoreService.getAdminStats();
      expect(stats, isNotNull);
      expect(stats.containsKey('total'), isTrue);

      final belongings = await firestoreService.getUserBelongings('test_user');
      expect(belongings, isEmpty);

      final asset = await firestoreService.lookupByTracebackId('TB-NONE');
      expect(asset, isNull);
    });
  });
}
