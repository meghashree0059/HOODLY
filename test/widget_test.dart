import 'package:flutter_test/flutter_test.dart';
import 'package:hoodly/core/utils/validators.dart';

void main() {
  test('AppValidators test', () {
    expect(AppValidators.confirmPassword('Hoodly@12345', 'Hoodly@12345'), isNull);
  });
}
