import 'package:flutter_test/flutter_test.dart';
import 'package:sp_app/utils/validators.dart';

void main() {
  group('Password Validation Tests', () {
    test('Empty or null password returns error', () {
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword(''), 'Password is required');
    });

    test('Valid password passes validation', () {
      expect(Validators.validatePassword('StrongPass123!'), null);
    });

    test('Password too short and missing uppercase returns error', () {
      final res = Validators.validatePassword('sh1!');
      expect(res, contains('8+ characters'));
      expect(res, contains('uppercase letter'));
    });

    test('Password missing uppercase returns error', () {
      final res = Validators.validatePassword('strongpass123!');
      expect(res, contains('uppercase letter'));
      expect(res, isNot(contains('8+ characters')));
    });

    test('Password missing lowercase returns error', () {
      final res = Validators.validatePassword('STRONGPASS123!');
      expect(res, contains('lowercase letter'));
    });

    test('Password missing number returns error', () {
      final res = Validators.validatePassword('StrongPass!');
      expect(res, contains('number'));
    });

    test('Password missing special character returns error', () {
      final res = Validators.validatePassword('StrongPass123');
      expect(res, contains('special character'));
    });
  });
}
