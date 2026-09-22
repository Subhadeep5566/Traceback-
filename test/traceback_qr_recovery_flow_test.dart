import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/providers/asset_provider.dart';
import 'package:traceback/screens/qr_view_screen.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('End-to-End Traceback ID, QR, Scan, Found & Recovery Workflow', () {
    test('1. Automatic unique Traceback ID generation matching TB-XXXXXX format', () async {
      final storage = StorageService();
      await storage.init();
      final provider = AssetProvider(storage);
      await Future.delayed(const Duration(milliseconds: 50));

      final id1 = provider.generateUniqueTracebackId(AssetCategory.electronics);
      final id2 = provider.generateUniqueTracebackId(AssetCategory.belonging);

      expect(id1.startsWith('TB-'), isTrue);
      expect(id2.startsWith('TB-'), isTrue);
      expect(id1.length, 9); // 'TB-' + 6 chars
      expect(id2.length, 9);
      expect(id1, isNot(equals(id2)));
      expect(RegExp(r'^TB-[2-9A-Z]{6}$').hasMatch(id1), isTrue);
    });

    test('2. Item registration with unique Traceback ID and Safe status', () async {
      final storage = StorageService();
      await storage.init();
      final provider = AssetProvider(storage);
      await Future.delayed(const Duration(milliseconds: 50));

      final asset = await provider.registerBelonging(
        name: 'MacBook Air M2',
        category: AssetCategory.electronics,
        brand: 'Apple',
        model: 'A2681',
      );

      expect(asset.name, 'MacBook Air M2');
      expect(asset.status, AssetStatus.safe);
      expect(asset.tracebackId.startsWith('TB-'), isTrue);
      expect(asset.createdAt, isNotNull);
      expect(provider.allAssets.any((a) => a.id == asset.id), isTrue);
    });

    test('3. Tag lookup supports raw ID, case-insensitivity, and deep-link URLs', () async {
      final storage = StorageService();
      await storage.init();
      final provider = AssetProvider(storage);
      await Future.delayed(const Duration(milliseconds: 50));

      final asset = await provider.registerBelonging(
        name: 'Campus Backpack',
        category: AssetCategory.belonging,
      );

      // Exact match
      final match1 = provider.lookupByTracebackId(asset.tracebackId);
      expect(match1?.id, asset.id);

      // Lowercase match
      final match2 = provider.lookupByTracebackId(asset.tracebackId.toLowerCase());
      expect(match2?.id, asset.id);

      // Deep-link URL
      final match3 = provider.lookupByTracebackId('https://traceback.bgu.ac.in/item/${asset.tracebackId}');
      expect(match3?.id, asset.id);

      // Non-existent
      final match4 = provider.lookupByTracebackId('TB-NONEXIST');
      expect(match4, isNull);
    });

    test('4. Full Lifecycle: Register -> Report Lost -> Report Found -> Recovery Handover', () async {
      final storage = StorageService();
      await storage.init();
      final provider = AssetProvider(storage);
      await Future.delayed(const Duration(milliseconds: 50));

      // Step 1: Register
      final asset = await provider.registerBelonging(
        name: 'Scientific Calculator',
        category: AssetCategory.electronics,
      );
      expect(asset.status, AssetStatus.safe);

      // Step 2: Owner marks as Lost
      await provider.markAsLost(
        asset.id,
        location: 'Lecture Hall Block B',
        note: 'Left on desk after Physics exam',
      );
      final lostAsset = provider.getAssetById(asset.id)!;
      expect(lostAsset.status, AssetStatus.stolen);
      expect(lostAsset.isLost, isTrue);
      expect(lostAsset.lostAt, isNotNull);

      // Step 3: Peer/Finder reports Found
      final initialUnreadNotifs = provider.unreadNotificationCount;
      await provider.reportFound(
        assetId: lostAsset.tracebackId,
        foundLocation: 'Main Library Reception',
        note: 'Handed over to librarian Mr. Patnaik',
      );
      final foundAsset = provider.getAssetById(asset.id)!;
      expect(foundAsset.status, AssetStatus.found);
      expect(foundAsset.isFound, isTrue);
      expect(foundAsset.foundAt, isNotNull);
      expect(foundAsset.foundLocation, 'Main Library Reception');
      expect(foundAsset.finderNote, 'Handed over to librarian Mr. Patnaik');

      // Verify owner notification was dispatched
      expect(provider.unreadNotificationCount, greaterThan(initialUnreadNotifs));
      final latestNotif = provider.notifications.first;
      expect(latestNotif.type, 'found');
      expect(latestNotif.title, contains('Found'));

      // Step 4: Owner confirms Recovery
      await provider.confirmRecovery(asset.id);
      final recoveredAsset = provider.getAssetById(asset.id)!;
      expect(recoveredAsset.status, AssetStatus.recovered);
      expect(recoveredAsset.isRecovered, isTrue);
      expect(recoveredAsset.recoveredAt, isNotNull);

      // Step 5: Mark all notifications read
      provider.markAllNotificationsAsRead();
      expect(provider.unreadNotificationCount, 0);
    });

    testWidgets('5. QrViewScreen displays item details and QR without personal contact info', (tester) async {
      final asset = Asset(
        id: 'AST-TEST-001',
        tracebackId: 'TB-8F42A1',
        ownerId: 'student_123',
        name: 'Engineering Backpack',
        category: AssetCategory.belonging,
        brand: 'Wildcraft',
        model: 'Classic 30L',
        status: AssetStatus.safe,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'Birla Global University, Bhubaneswar',
        lastPing: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QrViewScreen(asset: asset),
        ),
      );
      await tester.pumpAndSettle();

      // Item Name and ID visible
      expect(find.text('Engineering Backpack'), findsOneWidget);
      expect(find.text('TB-8F42A1'), findsOneWidget);
      expect(find.text('Scan to report a found item'), findsOneWidget);
      expect(find.text('Copy ID'), findsOneWidget);
      expect(find.text('Share Tag'), findsOneWidget);
      expect(find.text('No personal contact info is shared in this QR'), findsOneWidget);

      // Verify ZERO owner personal details are displayed
      expect(find.text('student_123'), findsNothing);
      expect(find.textContaining('@'), findsNothing); // no email
      expect(find.textContaining('+91'), findsNothing); // no phone
    });
  });
}
