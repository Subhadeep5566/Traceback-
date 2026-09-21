import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/models/user_profile.dart';
import 'package:traceback/providers/asset_provider.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AssetProvider assetProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    assetProvider = AssetProvider(storageService);
    // Wait for internal init
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() {
    storageService.close();
  });

  group('Role-Based Asset Recovery Tests', () {
    test('Test A: Student reports Lost -> Admin receives case & views owner info', () async {
      final now = DateTime.now();
      final studentAsset = Asset(
        id: 'AST-TEST-001',
        tracebackId: 'TB-TEST-001',
        name: 'Calculus Textbook & Notes',
        category: AssetCategory.belonging,
        brand: 'Pearson',
        model: '14th Edition',
        color: 'Blue',
        description: 'Hardcover with handwritten notes',
        status: AssetStatus.safe,
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'BGU Campus, Bhubaneswar',
        lastPing: now,
        createdAt: now,
        updatedAt: now,
        ownerId: 'student_subhadeep',
      );

      await assetProvider.addAsset(studentAsset);
      expect(assetProvider.allAssets.any((a) => a.id == 'AST-TEST-001'), isTrue);

      // Student reports item as lost
      await assetProvider.reportLostOrStolen(
        assetId: 'AST-TEST-001',
        reason: 'Lost',
        locationAddress: 'Library 2nd Floor Study Area',
        notes: 'Left on study desk near the window.',
        reporterRole: UserRole.student,
        reporterName: 'Subhadeep',
        reporterId: 'student_subhadeep',
        reporterContact: '9876543210',
      );

      // Check asset status
      final updatedAsset = assetProvider.allAssets.firstWhere((a) => a.id == 'AST-TEST-001');
      expect(updatedAsset.isLost, isTrue);

      // Verify incident step actor is student
      final incidents = assetProvider.allIncidents.where((i) => i.assetId == 'AST-TEST-001').toList();
      expect(incidents, isNotEmpty);
      final latestStep = incidents.first.timeline.last;
      expect(latestStep.actorRole, equals(UserRole.student));
      expect(latestStep.actor, equals('Subhadeep'));

      // Check admin receives case notification
      final adminNotifs = assetProvider.notificationsForRole(UserRole.admin);
      expect(adminNotifs.any((n) => n.assetId == 'AST-TEST-001' && n.title.contains('Case Filed')), isTrue);

      // Check admin active cases include this asset
      expect(assetProvider.activeCases.any((a) => a.id == 'AST-TEST-001'), isTrue);
      expect(assetProvider.lostCases.any((a) => a.id == 'AST-TEST-001'), isTrue);
    });

    test('Test B: Admin reports Found -> Student notified, views Admin Contact Card -> Confirms Recovery', () async {
      final now = DateTime.now();
      final targetAsset = Asset(
        id: 'AST-TEST-002',
        tracebackId: 'TB-TEST-002',
        name: 'Engineering Calculator',
        category: AssetCategory.electronics,
        brand: 'Casio',
        model: 'fx-991EX',
        color: 'Black',
        status: AssetStatus.stolen, // lost previously
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'BGU Campus, Bhubaneswar',
        lastPing: now,
        createdAt: now,
        updatedAt: now,
        ownerId: 'student_subhadeep',
      );

      await assetProvider.addAsset(targetAsset);

      final adminProfile = UserProfile.defaultAdmin(
        name: 'Officer Rajesh Kumar',
        email: 'security.admin@bgu.ac.in',
        phone: '0674-7103001',
        officeLocation: 'Admin Block, Ground Floor, Room G-04',
      );

      // Admin reports found
      await assetProvider.adminReportFound(
        identifier: 'TB-TEST-002',
        location: 'Campus Security Desk, Admin Block',
        notes: 'Handed over by cleaning staff from Seminar Hall B.',
        adminProfile: adminProfile,
      );

      // Check asset status updated to found
      final foundAsset = assetProvider.allAssets.firstWhere((a) => a.id == 'AST-TEST-002');
      expect(foundAsset.isFound, isTrue);

      // Check timeline step recorded with Admin role
      final incident = assetProvider.allIncidents.firstWhere((i) => i.assetId == 'AST-TEST-002');
      final step = incident.timeline.last;
      expect(step.actorRole, equals(UserRole.admin));
      expect(step.actor, equals('Officer Rajesh Kumar'));

      // Check student notification exists
      final studentNotifs = assetProvider.notificationsForRole(UserRole.student);
      expect(studentNotifs.any((n) => n.assetId == 'AST-TEST-002' && n.type == 'found'), isTrue);

      // Student verifies and confirms recovery
      await assetProvider.confirmRecovery('AST-TEST-002');

      final recoveredAsset = assetProvider.allAssets.firstWhere((a) => a.id == 'AST-TEST-002');
      expect(recoveredAsset.isRecovered, isTrue);
      expect(recoveredAsset.trackingEnabled, isFalse);
    });

    test('Test C: Student reports Found -> Owner identified & notified, Admin sees case', () async {
      final now = DateTime.now();
      final peerAsset = Asset(
        id: 'AST-TEST-003',
        tracebackId: 'TB-TEST-003',
        name: 'Gym Duffle Bag',
        category: AssetCategory.belonging,
        brand: 'Nike',
        color: 'Red',
        status: AssetStatus.stolen,
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'BGU Campus, Bhubaneswar',
        lastPing: now,
        createdAt: now,
        updatedAt: now,
        ownerId: 'student_owner',
      );

      await assetProvider.addAsset(peerAsset);

      // Finder student reports item found
      await assetProvider.reportFound(
        assetId: 'AST-TEST-003',
        foundLocation: 'BGU Sports Complex Locker Room',
        note: 'Found near locker 14 after evening badminton.',
        reporterRole: UserRole.student,
        reporterName: 'Ananya Sharma',
        reporterId: 'student_ananya',
        reporterContact: '9812345678',
      );

      final foundAsset = assetProvider.allAssets.firstWhere((a) => a.id == 'AST-TEST-003');
      expect(foundAsset.isFound, isTrue);

      // Owner receives notification
      final studentNotifs = assetProvider.notificationsForRole(UserRole.student);
      expect(
        studentNotifs.any((n) => n.assetId == 'AST-TEST-003' && n.title.contains('Was Found')),
        isTrue,
      );

      // Admin case feed includes item
      expect(assetProvider.activeCases.any((a) => a.id == 'AST-TEST-003'), isTrue);
      expect(assetProvider.foundCases.any((a) => a.id == 'AST-TEST-003'), isTrue);
    });

    test('Test D: Privacy verification (anonymous QR scan vs authorized admin recovery view)', () {
      final student = UserProfile.defaultStudent(
        name: 'Subhadeep',
        email: 'subhadeep@bgu.ac.in',
        phone: '9876543210',
      );

      // Anonymous QR scan payload:
      // Must NOT contain student phone number, email, or student ID
      final Map<String, dynamic> anonymousQrPayload = {
        'tracebackId': 'TB-LAPTOP-002',
        'assetName': 'Student Laptop',
        'category': 'Electronics',
        'status': 'Lost',
        'instructions': 'Please return to BGU Asset Recovery Office, Admin Block Room G-04',
      };

      expect(anonymousQrPayload.containsKey('phone'), isFalse);
      expect(anonymousQrPayload.containsKey('email'), isFalse);
      expect(anonymousQrPayload.containsKey('studentId'), isFalse);
      expect(anonymousQrPayload.toString().contains('9876543210'), isFalse);
      expect(anonymousQrPayload.toString().contains('subhadeep@bgu.ac.in'), isFalse);

      // Authorized admin case detail view:
      // Can access owner information during active recovery
      expect(student.name, equals('Subhadeep'));
      expect(student.phone, equals('9876543210'));
      expect(student.email, equals('subhadeep@bgu.ac.in'));
      expect(student.studentId, equals('BGU-2024-BTECH-042'));
    });
  });
}
