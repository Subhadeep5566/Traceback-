import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/providers/asset_provider.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Traceback Belongings Complete Functional Lifecycle Tests', () {
    late StorageService storageService;
    late AssetProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
      provider = AssetProvider(storageService);
      // Wait for async init from telematics/storage
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Complete 12-stage Belonging Lifecycle: Register -> Tag -> Secure -> Lost -> Trace -> Found -> Notified -> Recover -> History -> Persist', () async {
      // ----------------------------------------------------
      // Stage 1 & 2: REGISTER & TAG
      // ----------------------------------------------------
      final registered = await provider.registerBelonging(
        name: 'MacBook Pro M3 Max',
        category: AssetCategory.electronics,
        brand: 'Apple',
        model: 'Space Black 16-inch',
        color: 'Space Black',
        description: 'BGU Engineering Department sticker on lid',
      );

      expect(registered.id, isNotEmpty);
      expect(registered.tracebackId, startsWith('TB-LAPTOP-'));
      expect(registered.category, equals(AssetCategory.electronics));
      expect(registered.brand, equals('Apple'));
      expect(registered.status, equals(AssetStatus.safe));
      expect(registered.trackingEnabled, isFalse);

      final foundInList = provider.getAssetById(registered.id);
      expect(foundInList, isNotNull);
      expect(foundInList!.tracebackId, equals(registered.tracebackId));

      // ----------------------------------------------------
      // Stage 3: SECURE
      // ----------------------------------------------------
      expect(registered.isSecure, isTrue);
      expect(registered.isLost, isFalse);

      // ----------------------------------------------------
      // Stage 4: LOST/STOLEN (Report Lost)
      // ----------------------------------------------------
      await provider.reportLostOrStolen(
        assetId: registered.id,
        reason: 'Stolen',
        locationAddress: 'Central Library, 2nd Floor Study Cubicle',
        notes: 'Left unattended while getting water from dispenser',
      );

      final lostAsset = provider.getAssetById(registered.id)!;
      expect(lostAsset.status, equals(AssetStatus.stolen));
      expect(lostAsset.isLost, isTrue);
      expect(provider.lostCount, greaterThanOrEqualTo(1));

      // ----------------------------------------------------
      // Stage 5 & 6: ACTIVATE TRACE & LOCATION DETECTED
      // ----------------------------------------------------
      await provider.activateTrace(lostAsset.id);
      final tracingAsset = provider.getAssetById(lostAsset.id)!;
      expect(tracingAsset.trackingEnabled, isTrue);
      expect(tracingAsset.locationAccuracy, isNotNull);

      // ----------------------------------------------------
      // Stage 7: FINDER FLOW (Report Found by Campus Peer/Security)
      // Note: In public view, finder only sees public metadata
      // ----------------------------------------------------
      await provider.reportFound(
        assetId: tracingAsset.id,
        foundLocation: 'Library Security Desk, Ground Floor',
        note: 'Handed in by cleaner. Safe at security counter.',
      );

      final reportedFoundAsset = provider.getAssetById(tracingAsset.id)!;
      expect(reportedFoundAsset.status, equals(AssetStatus.found));
      expect(reportedFoundAsset.isFound, isTrue);

      // ----------------------------------------------------
      // Stage 8: OWNER NOTIFIED
      // ----------------------------------------------------
      final notifications = provider.notifications;
      expect(notifications.any((n) => n.assetId == tracingAsset.id && n.type == 'found'), isTrue);

      // ----------------------------------------------------
      // Stage 9 & 10: VERIFY & RECOVER
      // ----------------------------------------------------
      await provider.confirmRecovery(reportedFoundAsset.id);

      final recoveredAsset = provider.getAssetById(reportedFoundAsset.id)!;
      expect(recoveredAsset.status, equals(AssetStatus.recovered));
      expect(recoveredAsset.isRecovered, isTrue);
      // Tracking must be automatically turned off upon recovery
      expect(recoveredAsset.trackingEnabled, isFalse);

      // ----------------------------------------------------
      // Stage 11: RECOVERY HISTORY AUDIT
      // ----------------------------------------------------
      final history = provider.getAssetHistory(recoveredAsset.id);
      expect(history, isNotEmpty);
      expect(history.any((e) => e.title.toLowerCase().contains('recovered') || e.title.toLowerCase().contains('found')), isTrue);

      // ----------------------------------------------------
      // Stage 12: PERSISTENCE ACROSS SESSIONS
      // ----------------------------------------------------
      // Create a fresh provider pointing to the same storage
      final restoredProvider = AssetProvider(storageService);
      await Future.delayed(const Duration(milliseconds: 100));

      final persistedAsset = restoredProvider.getAssetById(recoveredAsset.id);
      expect(persistedAsset, isNotNull);
      expect(persistedAsset!.tracebackId, equals(registered.tracebackId));
      expect(persistedAsset.status, equals(AssetStatus.recovered));
      expect(persistedAsset.brand, equals('Apple'));
      expect(persistedAsset.model, equals('Space Black 16-inch'));
      expect(persistedAsset.trackingEnabled, isFalse);
    });

    test('Unique Traceback ID format follows TB-<CATEGORY>-<SEQ> pattern', () async {
      final bike = await provider.registerBelonging(
        name: 'Firefox Mountain Bike',
        category: AssetCategory.vehicle,
      );
      expect(bike.tracebackId, matches(r'^TB-BIKE-\d{3,}$'));

      final phone = await provider.registerBelonging(
        name: 'iPhone 15',
        category: AssetCategory.phone,
      );
      expect(phone.tracebackId, matches(r'^TB-PHONE-\d{3,}$'));

      final keys = await provider.registerBelonging(
        name: 'Hostel Key Bundle',
        category: AssetCategory.belonging,
      );
      expect(keys.tracebackId, matches(r'^TB-ITEM-\d{3,}$'));
    });

    test('Stop Trace disables active tracking', () async {
      final item = await provider.registerBelonging(
        name: 'Bose Headphones',
        category: AssetCategory.electronics,
      );
      await provider.activateTrace(item.id);
      expect(provider.getAssetById(item.id)!.trackingEnabled, isTrue);

      await provider.stopTrace(item.id);
      expect(provider.getAssetById(item.id)!.trackingEnabled, isFalse);
    });

    test('Mark Safe returns recovered or safe item to fully secured status', () async {
      final item = await provider.registerBelonging(
        name: 'Scientific Calculator',
        category: AssetCategory.belonging,
      );
      await provider.reportLostOrStolen(
        assetId: item.id,
        reason: 'Lost',
        locationAddress: 'Lecture Hall 3',
        notes: 'Misplaced',
      );
      expect(provider.getAssetById(item.id)!.isLost, isTrue);

      await provider.confirmRecovery(item.id);
      expect(provider.getAssetById(item.id)!.isRecovered, isTrue);

      await provider.markAsSafe(item.id);
      final secured = provider.getAssetById(item.id)!;
      expect(secured.status, equals(AssetStatus.safe));
      expect(secured.isSecure, isTrue);
    });
  });
}
