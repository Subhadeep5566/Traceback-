import 'package:flutter_test/flutter_test.dart';
import 'package:traceback/models/asset.dart';
import 'package:traceback/models/found_item.dart';
import 'package:traceback/models/user_profile.dart';
import 'package:traceback/services/matching_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('General Purpose Traceback Workflow & Match Engine Tests', () {
    test('User A (Rahul Sharma) can register with general non-college email and UserRole.user', () {
      final userA = UserProfile(
        userId: 'usr_rahul_01',
        name: 'Rahul Sharma',
        email: 'rahul@example.com',
        phone: '9876543210',
        city: 'Bhubaneswar',
        role: UserRole.user,
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(userA.name, equals('Rahul Sharma'));
      expect(userA.email, equals('rahul@example.com'));
      expect(userA.role, equals(UserRole.user));
      expect(userA.city, equals('Bhubaneswar'));
      expect(userA.isActive, isTrue);

      final json = userA.toJson();
      expect(json['email'], equals('rahul@example.com'));
      expect(json['role'], equals('user'));
      expect(json['city'], equals('Bhubaneswar'));
      expect(json.containsKey('password'), isFalse);
    });

    test('User A registers belongings (Bike, Laptop) with unique identifiers', () {
      final bike = Asset(
        id: 'AST-BIKE-001',
        tracebackId: 'TB-BIKE-7788',
        ownerId: 'usr_rahul_01',
        name: 'Royal Enfield Classic 350',
        category: AssetCategory.bike,
        brand: 'Royal Enfield',
        model: 'Classic 350',
        color: 'Black',
        registrationNumber: 'OD-02-AB-1234',
        serialNumber: 'RE350CHASSIS999',
        status: AssetStatus.lost,
        createdAt: DateTime.now(),
      );

      expect(bike.category, equals(AssetCategory.bike));
      expect(bike.categoryName, equals('bike'));
      expect(bike.registrationNumber, equals('OD-02-AB-1234'));
      expect(bike.serialNumber, equals('RE350CHASSIS999'));
      expect(bike.isLost, isTrue);
    });

    test('User B (Subhadeep) reports finding a bike with matching registration number', () {
      final userB = UserProfile(
        userId: 'usr_subha_02',
        name: 'Subhadeep',
        email: 'subha@example.com',
        phone: '9123456789',
        role: UserRole.user,
      );

      final bike = Asset(
        id: 'AST-BIKE-001',
        tracebackId: 'TB-BIKE-7788',
        ownerId: 'usr_rahul_01',
        name: 'Royal Enfield Classic 350',
        category: AssetCategory.bike,
        brand: 'Royal Enfield',
        model: 'Classic 350',
        color: 'Black',
        registrationNumber: 'OD-02-AB-1234',
        serialNumber: 'RE350CHASSIS999',
        status: AssetStatus.lost,
        createdAt: DateTime.now(),
      );

      final foundBike = FoundItem(
        foundItemId: 'FND-BIKE-001',
        itemName: 'Found Royal Enfield Motorbike',
        category: 'bike',
        brand: 'Royal Enfield',
        model: 'Classic 350',
        color: 'Black',
        registrationNumber: 'OD02AB1234', // Normalized should match OD-02-AB-1234
        finderId: userB.userId,
        finderName: userB.name,
        finderContact: userB.phone,
        foundLocation: 'Jayadev Vihar, Bhubaneswar',
        status: FoundItemStatus.reported,
        createdAt: DateTime.now(),
      );

      final matchResults = MatchingService.findPossibleMatches(foundBike, [bike]);
      expect(matchResults.isNotEmpty, isTrue);

      final topMatch = matchResults.first;
      expect(topMatch.isStrongMatch, isTrue);
      expect(topMatch.percentage, equals(100));
      expect(topMatch.matchingFactors.any((f) => f.contains('Registration Match')), isTrue);
      expect(topMatch.matchedAsset.id, equals(bike.id));
    });

    test('Matching engine computes high confidence on brand + model + color + keywords for laptop', () {
      final laptop = Asset(
        id: 'AST-LAPTOP-002',
        tracebackId: 'TB-LAPTOP-1122',
        ownerId: 'usr_rahul_01',
        name: 'MacBook Air M2',
        category: AssetCategory.laptop,
        brand: 'Apple',
        model: 'MacBook Air',
        color: 'Midnight Blue',
        status: AssetStatus.lost,
        createdAt: DateTime.now(),
      );

      final foundLaptop = FoundItem(
        foundItemId: 'FND-LAP-002',
        itemName: 'Midnight Blue Apple Laptop',
        category: 'laptop',
        brand: 'Apple',
        model: 'MacBook Air',
        color: 'Midnight',
        description: 'Left on bench near cafeteria',
        finderId: 'usr_subha_02',
        finderName: 'Subhadeep',
        status: FoundItemStatus.reported,
        createdAt: DateTime.now(),
      );

      final matchResults = MatchingService.findPossibleMatches(foundLaptop, [laptop]);
      expect(matchResults.isNotEmpty, isTrue);

      final topMatch = matchResults.first;
      // Category(25) + Brand(25) + Model(20) + Color(15) + Lost status(10) >= 80%
      expect(topMatch.score, greaterThanOrEqualTo(80.0));
      expect(topMatch.isStrongMatch, isTrue);
      expect(topMatch.matchingFactors.any((f) => f.contains('Brand Match')), isTrue);
      expect(topMatch.matchingFactors.any((f) => f.contains('Model Match')), isTrue);
    });

    test('Recovery Flow: Item resolves to recovered and FoundItem resolves to returned', () {
      var asset = Asset(
        id: 'AST-WALLET-003',
        tracebackId: 'TB-WALLET-99',
        ownerId: 'usr_rahul_01',
        name: 'Brown Leather Wallet',
        category: AssetCategory.wallet,
        color: 'Brown',
        status: AssetStatus.lost,
        createdAt: DateTime.now(),
      );

      var foundItem = FoundItem(
        foundItemId: 'FND-WALLET-003',
        itemName: 'Found Brown Leather Wallet',
        category: 'wallet',
        color: 'Brown',
        finderId: 'usr_subha_02',
        finderName: 'Subhadeep',
        finderContact: '9123456789',
        status: FoundItemStatus.matched,
        matchedItemId: asset.id,
        createdAt: DateTime.now(),
      );

      // Recovery action
      final recoveredAsset = asset.copyWith(
        status: AssetStatus.recovered,
        matchedFoundItemId: foundItem.id,
      );

      final returnedFoundItem = foundItem.copyWith(
        status: FoundItemStatus.returned,
      );

      expect(recoveredAsset.status, equals(AssetStatus.recovered));
      expect(returnedFoundItem.status, equals(FoundItemStatus.returned));
      expect(recoveredAsset.matchedFoundItemId, equals('FND-WALLET-003'));
      expect(returnedFoundItem.matchedAssetId, equals('AST-WALLET-003'));
    });
  });
}
