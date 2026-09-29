import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _PermissiveHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  const supabaseUrl = 'https://pdskyrijjzrqgbnzxmvi.supabase.co';
  const supabaseKey = 'sb_publishable_L3n5c-uiZrHmS3Mdt6UMXQ__AOB8hZ-';
  const password = 'Hoodly@12345';

  group('Supabase auth flow', () {
    late SupabaseClient client;
    late String email;

    setUpAll(() async {
      await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
      client = Supabase.instance.client;
    });

    setUp(() {
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      email = 'hoodlyflow$uniqueId@gmail.com';
    });

    test('signup creates user and session when email confirmation is disabled',
        () async {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': 'Flow Test User', 'role': 'user'},
      );

      expect(response.user, isNotNull);
      expect(response.user!.email, email);

      // Session may be null if email confirmation is required in the project.
      if (response.session != null) {
        expect(client.auth.currentSession, isNotNull);
        expect(client.auth.currentUser?.id, response.user!.id);
      }
    });

    test('login succeeds with valid credentials after signup', () async {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': 'Login Test User', 'role': 'user'},
      );

      await client.auth.signOut();

      final loginResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      expect(loginResponse.user, isNotNull);
      expect(loginResponse.session, isNotNull);
      expect(client.auth.currentSession, isNotNull);
      expect(client.auth.currentUser?.email, email);
    });

    test('login fails with invalid credentials', () async {
      expect(
        () => client.auth.signInWithPassword(
          email: 'nonexistent@example.com',
          password: 'WrongPassword123!',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut clears session', () async {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': 'Logout Test User', 'role': 'user'},
      );

      if (client.auth.currentSession == null) {
        // Email confirmation required — skip logout portion for this project config.
        return;
      }

      await client.auth.signOut();
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
    });
  });
}

class _PermissiveHttpOverrides extends HttpOverrides {}
