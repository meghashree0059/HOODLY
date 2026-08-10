import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Abstract authentication service interface.
abstract class AuthService {
  /// Singleton instance of the active authentication service.
  static final AuthService instance = SupabaseAuthService();

  /// Returns the currently signed-in user, or null if not authenticated.
  Future<UserModel?> get currentUser;

  /// Stream of authentication state changes.
  Stream<UserModel?> get authStateChanges;

  /// Sign in with email and password.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register a new user with email and password.
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Update the current user's profile.
  Future<UserModel> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? role,
  });

  /// Delete the current user's account.
  Future<void> deleteAccount();
}

/// Concrete implementation of [AuthService] using Supabase.
class SupabaseAuthService implements AuthService {
  final _supabase = Supabase.instance.client;

  @override
  Future<UserModel?> get currentUser async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase.from('profiles').select().eq('id', user.id).single();
      final userModel = UserModel.fromJson(data);
      _cacheUser(userModel);
      return userModel;
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return UserModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? 'User',
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) {
        await _clearCache();
        return null;
      }

      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .single();
        final userModel = UserModel.fromJson(data);
        await _cacheUser(userModel);
        return userModel;
      } catch (e) {
        debugPrint('Error in auth state change profile query: $e');
        return UserModel(
          id: session.user.id,
          fullName: session.user.userMetadata?['full_name'] ?? 'User',
          email: session.user.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Login failed. Please check your credentials.');
    }

    final data = await _supabase.from('profiles').select().eq('id', user.id).single();
    final userModel = UserModel.fromJson(data);
    await _cacheUser(userModel);
    return userModel;
  }

  @override
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'role': 'user',
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Registration failed.');
    }

    // Wait for DB trigger to create profiles row
    await Future.delayed(const Duration(milliseconds: 600));

    final data = await _supabase.from('profiles').select().eq('id', user.id).single();
    final userModel = UserModel.fromJson(data);
    await _cacheUser(userModel);
    return userModel;
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearCache();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? role,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final Map<String, dynamic> updates = {};
    if (fullName != null) updates['name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (role != null) updates['role'] = role;

    if (updates.isEmpty) {
      final currentData = await _supabase.from('profiles').select().eq('id', user.id).single();
      return UserModel.fromJson(currentData);
    }

    final data = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();

    final userModel = UserModel.fromJson(data);
    await _cacheUser(userModel);
    return userModel;
  }

  @override
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('profiles').delete().eq('id', user.id);
    await signOut();
  }

  Future<void> _cacheUser(UserModel user) async {
    try {
      final storage = await StorageService.getInstance();
      await storage.setBool(StorageKeys.isLoggedIn, true);
      await storage.setString(StorageKeys.userId, user.id);
      await storage.setString(StorageKeys.userEmail, user.email);
      await storage.setString(StorageKeys.userFullName, user.fullName);
    } catch (e) {
      debugPrint('Error caching user: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final storage = await StorageService.getInstance();
      await storage.remove(StorageKeys.isLoggedIn);
      await storage.remove(StorageKeys.userId);
      await storage.remove(StorageKeys.userEmail);
      await storage.remove(StorageKeys.userFullName);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
