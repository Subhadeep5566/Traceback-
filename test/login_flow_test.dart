import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/main.dart';
import 'package:traceback/screens/dashboard_screen.dart';
import 'package:traceback/screens/login_screen.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Traceback Login Flow Tests', () {
    testWidgets('Complete login flow with valid credentials navigates to dashboard', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Should be on login screen initially
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Enter valid BGU email
      await tester.enterText(find.byKey(const Key('email_field')), 'student@bgu.edu.in');
      await tester.pumpAndSettle();

      // Enter valid phone
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.pumpAndSettle();

      // Tap Continue button
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should navigate to dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Tapping Try Demo enters demo mode and navigates to dashboard', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('try_demo_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('try_demo_button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('YOUR BELONGINGS'), findsOneWidget);
    });

    testWidgets('Login shows validation error for empty fields', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Tap Continue without entering anything
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your BGU email'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login shows validation error for invalid email', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login shows validation error for non-BGU email', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Enter non-BGU email
      await tester.enterText(find.byKey(const Key('email_field')), 'user@gmail.com');
      await tester.enterText(find.byKey(const Key('phone_field')), '9876543210');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Only BGU email addresses (@bgu.edu.in, @bgu.ac.in) are allowed'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login shows validation error for invalid phone', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(TracebackApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Enter valid email but invalid phone
      await tester.enterText(find.byKey(const Key('email_field')), 'student@bgu.edu.in');
      await tester.enterText(find.byKey(const Key('phone_field')), '123');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid 10-digit phone number'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}