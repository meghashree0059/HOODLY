import 'package:flutter_test/flutter_test.dart';
import 'package:hoodly/core/utils/validators.dart';
import 'package:hoodly/core/constants/app_strings.dart';

void main() {
  group('Signup Validation Tests', () {
    test('Identical password kio123@12 is accepted', () {
      const password = 'kio123@12';
      const confirmPassword = 'kio123@12';

      final result = AppValidators.confirmPassword(confirmPassword, password);
      expect(result, isNull, reason: 'Identical passwords must be valid');
    });

    test('Mismatched password kio123@12 vs kio123@123 is rejected', () {
      const password = 'kio123@12';
      const confirmPassword = 'kio123@123';

      final result = AppValidators.confirmPassword(confirmPassword, password);
      expect(result, equals(AppStrings.validPasswordMismatch));
    });

    test('AppValidators.confirmPassword succeeds when passwords match', () {
      const password = 'Hoodly@12345';
      const confirmPassword = 'Hoodly@12345';

      final result = AppValidators.confirmPassword(confirmPassword, password);
      expect(result, isNull);
    });

    test('AppValidators.confirmPassword fails when passwords do not match', () {
      const password = 'Hoodly@12345';
      const confirmPassword = 'DifferentPassword123';

      final result = AppValidators.confirmPassword(confirmPassword, password);
      expect(result, equals(AppStrings.validPasswordMismatch));
    });

    test('AppValidators.password enforces minimum length of 8', () {
      expect(AppValidators.password('short'), equals(AppStrings.validPasswordMin));
      expect(AppValidators.password('kio123@12'), isNull);
    });

    test('AppValidators.email validates email address format', () {
      expect(AppValidators.email(''), equals(AppStrings.validEmailRequired));
      expect(AppValidators.email('invalid-email'), equals(AppStrings.validEmail));
      expect(AppValidators.email('test@example.com'), isNull);
    });

    test('Password text is compared directly without altering spaces or trimming password', () {
      const password = ' Hoodly@12345 ';
      const confirmPassword = ' Hoodly@12345 ';

      // Must match exact spacing without trimming
      final result = AppValidators.confirmPassword(confirmPassword, password);
      expect(result, isNull);

      // If one has spaces and other doesn't, must report mismatch
      final resultMismatch = AppValidators.confirmPassword('Hoodly@12345', password);
      expect(resultMismatch, equals(AppStrings.validPasswordMismatch));
    });
  });
}
