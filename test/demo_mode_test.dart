import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/providers/asset_provider.dart';
import 'package:traceback/services/auth_service.dart';
import 'package:traceback/services/demo_data_service.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AuthService authService;
  late AssetProvider assetProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    authService = AuthService(storageService);
    assetProvider = AssetProvider(storageService);
  });

  group('Demo Mode & Session Isolation Tests', () {
    test('Entering Demo Mode sets DemoSession and Demo credentials', () async {
      expect(authService.isDemoMode, isFalse);
      expect(authService.authMode, equals(AuthMode.production));

      await authService.enterDemoMode();

      expect(authService.isDemoMode, isTrue);
      expect(authService.authMode, equals(AuthMode.demo));
      expect(authService.isLoggedIn, isTrue);
      expect(authService.userEmail, equals(DemoDataService.demoUserEmail));
      expect(authService.userName, equals(DemoDataService.demoUserName));
      expect(authService.userPhone, equals(DemoDataService.demoUserPhone));
    });

    test('Production credentials validation is NOT bypassed or relaxed', () async {
      // Malformed email must fail
      final failEmail = await authService.login(
        email: 'invalid-email-format',
        phone: '9876543210',
      );
      expect(failEmail.isSuccess, isFalse);
      expect(failEmail.errorMessage, contains('valid email'));

      // Invalid phone must fail
      final failPhone = await authService.login(
        email: 'user@example.com',
        phone: '12345',
      );
      expect(failPhone.isSuccess, isFalse);
      expect(failPhone.errorMessage, contains('10-digit'));
    });

    test('AssetProvider loads deterministic demo items and dashboard counts', () {
      assetProvider.loadDemoData();

      expect(assetProvider.isDemoMode, isTrue);
      expect(assetProvider.totalAssetCount, equals(3));
      expect(assetProvider.allAssets.length, equals(3));

      // Stats check: My Items: 3, Secure: 1, Lost: 1, Found: 1
      expect(assetProvider.safeCount, equals(1));
      expect(assetProvider.stolenCount, equals(1));
      expect(assetProvider.foundCount, equals(1));

      // Items check
      final bike = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-BIKE-001');
      expect(bike.name, equals('Campus Bike'));
      expect(bike.category, equals(AssetCategory.vehicle));
      expect(bike.status, equals(AssetStatus.stolen));
      expect(bike.isLost, isTrue);

      final laptop = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-LAPTOP-002');
      expect(laptop.name, equals('Student Laptop'));
      expect(laptop.category, equals(AssetCategory.electronics));
      expect(laptop.status, equals(AssetStatus.safe));
      expect(laptop.isSafe, isTrue);

      final phone = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-PHONE-003');
      expect(phone.name, equals('Smartphone'));
      expect(phone.category, equals(AssetCategory.phone));
      expect(phone.status, equals(AssetStatus.found));
      expect(phone.isFound, isTrue);
    });

    test('Interactive flow: Campus Bike (LOST) can be marked as RECOVERED', () {
      assetProvider.loadDemoData();
      final bike = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-BIKE-001');

      expect(bike.status, equals(AssetStatus.stolen));
      expect(assetProvider.stolenCount, equals(1));
      expect(assetProvider.lostAssets.length, equals(1));

      assetProvider.markAsRecovered(bike.id);

      final updatedBike = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-BIKE-001');
      expect(updatedBike.status, equals(AssetStatus.recovered));
      expect(assetProvider.stolenCount, equals(0));
      expect(assetProvider.lostAssets.length, equals(0));
    });

    test('Interactive flow: Smartphone (FOUND) can be marked as RECOVERED', () {
      assetProvider.loadDemoData();
      final phone = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-PHONE-003');

      expect(phone.status, equals(AssetStatus.found));
      expect(assetProvider.foundCount, equals(1));
      expect(assetProvider.foundAssets.length, equals(1));

      assetProvider.markAsRecovered(phone.id);

      final updatedPhone = assetProvider.allAssets.firstWhere((a) => a.identifier == 'TB-PHONE-003');
      expect(updatedPhone.status, equals(AssetStatus.recovered));
      expect(assetProvider.foundCount, equals(0));
      expect(assetProvider.foundAssets.length, equals(0));
    });

    test('Demo search query matches by name, category, and identifier', () {
      assetProvider.loadDemoData();

      // Search "Bike"
      assetProvider.setSearchQuery('Bike');
      expect(assetProvider.filteredAssets.length, equals(1));
      expect(assetProvider.filteredAssets.first.name, equals('Campus Bike'));

      // Search "Laptop"
      assetProvider.setSearchQuery('Laptop');
      expect(assetProvider.filteredAssets.length, equals(1));
      expect(assetProvider.filteredAssets.first.name, equals('Student Laptop'));

      // Search identifier "TB-PHONE-003"
      assetProvider.setSearchQuery('TB-PHONE-003');
      expect(assetProvider.filteredAssets.length, equals(1));
      expect(assetProvider.filteredAssets.first.name, equals('Smartphone'));

      // Clear search
      assetProvider.setSearchQuery('');
      expect(assetProvider.filteredAssets.length, equals(3));
    });

    test('Logout clears Demo Mode and returns to production state', () async {
      await authService.enterDemoMode();
      assetProvider.loadDemoData();

      expect(authService.isDemoMode, isTrue);
      expect(assetProvider.isDemoMode, isTrue);

      await assetProvider.resetToProduction();
      await authService.logout();

      expect(authService.isDemoMode, isFalse);
      expect(authService.authMode, equals(AuthMode.production));
      expect(authService.isLoggedIn, isFalse);
      expect(authService.userEmail, isNull);
      expect(assetProvider.isDemoMode, isFalse);
    });

    test('Demo relative time formatting works deterministically', () {
      final now = DateTime.now();
      expect(DemoDataService.getRelativeTime(now.subtract(const Duration(minutes: 5))), equals('5 minutes ago'));
      expect(DemoDataService.getRelativeTime(now.subtract(const Duration(hours: 2))), equals('2 hours ago'));
      expect(DemoDataService.getRelativeTime(now.subtract(const Duration(days: 1))), equals('Yesterday'));
      expect(DemoDataService.getRelativeTime(now.subtract(const Duration(days: 4))), equals('4 days ago'));
    });
  });
}
