import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/providers/asset_provider.dart';
import 'package:traceback/screens/main_navigation_shell.dart';
import 'package:traceback/screens/map_location_picker_screen.dart';
import 'package:traceback/services/auth_service.dart';
import 'package:traceback/services/location_service.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map & Location System Tests', () {
    test('LocationService defaults to Bhubaneswar, Odisha, India', () {
      expect(LocationService.bhubaneswarLatitude, 20.2961);
      expect(LocationService.bhubaneswarLongitude, 85.8245);
      expect(LocationService.defaultCityAddress, contains('Bhubaneswar'));
      expect(LocationService.bhubaneswarCenter.latitude, 20.2961);
      expect(LocationService.bhubaneswarCenter.longitude, 85.8245);
    });

    test('reverseGeocodeLabel generates appropriate campus or city labels', () {
      final campusLabel = LocationService.reverseGeocodeLabel(20.2982, 85.7434);
      expect(campusLabel, contains('BGU'));

      final cityLabel = LocationService.reverseGeocodeLabel(20.3500, 85.9000);
      expect(cityLabel, contains('Bhubaneswar'));
    });

    test('MapLocationResult holds coordinates and formatted address', () {
      const result = MapLocationResult(
        latitude: 20.2961,
        longitude: 85.8245,
        address: 'BGU Central Library, Bhubaneswar',
      );
      expect(result.latitude, 20.2961);
      expect(result.longitude, 85.8245);
      expect(result.address, contains('Central Library'));
    });

    testWidgets('MainNavigationShell renders 5 tabs including Map', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      await storageService.init();
      final authService = AuthService(storageService);
      final assetProvider = AssetProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authService),
            ChangeNotifierProvider.value(value: assetProvider),
          ],
          child: const MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );

      // Verify all 5 tab labels exist in bottom navigation bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Map icon exists
      expect(find.byIcon(Icons.map_rounded), findsWidgets);
    });
  });
}
