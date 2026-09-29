import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hoodly/core/utils/validators.dart';

class MyHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  test('Supabase signUp integration test with Hoodly@12345', () async {
    // Initialize Supabase client using project configuration
    await Supabase.initialize(
      url: 'https://pdskyrijjzrqgbnzxmvi.supabase.co',
      publishableKey: 'sb_publishable_L3n5c-uiZrHmS3Mdt6UMXQ__AOB8hZ-',
    );

    final uniqueId = DateTime.now().millisecondsSinceEpoch % 100000;
    final email = 'hoodlytest$uniqueId@gmail.com';
    const password = 'Hoodly@12345';
    const confirmPassword = 'Hoodly@12345';

    // 1. Password validation check
    final validationResult = AppValidators.confirmPassword(confirmPassword, password);
    expect(validationResult, isNull, reason: 'Password validation should pass when passwords match');

    // 2. Perform actual Supabase Auth signUp call
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': 'Test Hoodly User',
        'role': 'user',
      },
    );

    expect(response.user, isNotNull, reason: 'Supabase signUp should return a valid User object');
    expect(response.user!.email, equals(email));
  });
}
