import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traceback/services/auth_service.dart';
import 'package:traceback/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Validation Tests', () {
    test('Validates BGU email domains correctly', () {
      // Primary domains
      expect(AuthService.isBguEmail('student@bgu.edu.in'), isTrue);
      expect(AuthService.isBguEmail('subhadeep@bgu.ac.in'), isTrue);
      expect(AuthService.isBguEmail('subhadeep.saha@bgu.edu.in'), isTrue);
      expect(AuthService.isBguEmail('subhadeep_saha@bgu.ac.in'), isTrue);
      expect(AuthService.isBguEmail('STUDENT@BGU.EDU.IN'), isTrue);
      expect(AuthService.isBguEmail('FACULTY@BGU.AC.IN'), isTrue);

      // Subdomains
      expect(AuthService.isBguEmail('student@alumni.bgu.edu.in'), isTrue);
      expect(AuthService.isBguEmail('student@cs.bgu.ac.in'), isTrue);

      // Non-BGU domains must fail
      expect(AuthService.isBguEmail('student@gmail.com'), isFalse);
      expect(AuthService.isBguEmail('student@yahoo.in'), isFalse);
      expect(AuthService.isBguEmail('student@kiit.ac.in'), isFalse);
      expect(AuthService.isBguEmail('invalid-email'), isFalse);
      expect(AuthService.isBguEmail(''), isFalse);
    });

    test('Validates email format correctly', () {
      expect(AuthService.isValidEmail('student@bgu.edu.in'), isTrue);
      expect(AuthService.isValidEmail('subhadeep.saha@bgu.ac.in'), isTrue);
      expect(AuthService.isValidEmail('student+tag@bgu.edu.in'), isTrue);

      expect(AuthService.isValidEmail('not-an-email'), isFalse);
      expect(AuthService.isValidEmail('@bgu.edu.in'), isFalse);
      expect(AuthService.isValidEmail('student@'), isFalse);
      expect(AuthService.isValidEmail(''), isFalse);
    });

    test('Normalizes and validates Indian phone numbers', () {
      // Standard 10 digits
      expect(AuthService.isValidPhone('9876543210'), isTrue);
      expect(AuthService.normalizePhone('9876543210'), equals('9876543210'));

      // Formatted with spaces or dashes
      expect(AuthService.isValidPhone('98765 43210'), isTrue);
      expect(AuthService.normalizePhone('98765 43210'), equals('9876543210'));
      expect(AuthService.isValidPhone('98765-43210'), isTrue);
      expect(AuthService.normalizePhone('98765-43210'), equals('9876543210'));

      // With +91 country code
      expect(AuthService.isValidPhone('+91 98765 43210'), isTrue);
      expect(AuthService.normalizePhone('+91 98765 43210'), equals('9876543210'));
      expect(AuthService.isValidPhone('+919876543210'), isTrue);
      expect(AuthService.normalizePhone('+919876543210'), equals('9876543210'));

      // With leading zero
      expect(AuthService.isValidPhone('09876543210'), isTrue);
      expect(AuthService.normalizePhone('09876543210'), equals('9876543210'));

      // Invalid formats
      expect(AuthService.isValidPhone('12345'), isFalse);
      expect(AuthService.isValidPhone(''), isFalse);
      expect(AuthService.isValidPhone('abcdefghij'), isFalse);
    });

    test('Login end-to-end with valid credentials', () async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      final authService = AuthService(storageService);

      final result = await authService.login(
        email: 'subhadeep.saha@bgu.ac.in',
        phone: '+91 98765 43210',
      );

      expect(result.isSuccess, isTrue);
      expect(result.name, equals('Subhadeep Saha'));
      expect(result.phone, equals('9876543210'));
      expect(authService.isLoggedIn, isTrue);
      expect(authService.userPhone, equals('9876543210'));
      expect(authService.userEmail, equals('subhadeep.saha@bgu.ac.in'));
      expect(authService.userName, equals('Subhadeep Saha'));
    });

    test('Login accepts general email without BGU domain restriction', () async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      final authService = AuthService(storageService);

      final result = await authService.login(
        email: 'user@gmail.com',
        phone: '9876543210',
      );

      expect(result.isSuccess, isTrue);
      expect(authService.isLoggedIn, isTrue);
      expect(authService.userEmail, equals('user@gmail.com'));
    });
  });
}
