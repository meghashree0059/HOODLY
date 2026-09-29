import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_strings.dart';

/// Form field validators and auth error formatting used across the Hoodly app.
abstract final class AppValidators {
  /// Email validator
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validEmailRequired;
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.validEmail;
    }
    return null;
  }

  /// Password validator (min 8 chars)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.validPasswordRequired;
    }
    if (value.length < 8) {
      return AppStrings.validPasswordMin;
    }
    return null;
  }

  /// Confirm password validator
  static String? confirmPassword(String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppStrings.validPasswordRequired;
    }
    if (confirmPassword != password) {
      return AppStrings.validPasswordMismatch;
    }
    return null;
  }

  /// Full name validator
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validNameRequired;
    }
    return null;
  }

  /// Phone number validator
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validPhoneRequired;
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return AppStrings.validPhoneInvalid;
    }
    return null;
  }

  /// Generic required field validator
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  /// Format raw Supabase or technical exceptions into clean, friendly user error messages.
  static String formatAuthError(Object error) {
    if (error is AuthException) {
      final code = error.code ?? '';
      final msg = error.message.toLowerCase();

      if (code == 'invalid_credentials' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials')) {
        return 'Invalid email or password. Please check your credentials and try again.';
      }
      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return 'Your email is not confirmed yet. Please check your inbox for the confirmation link.';
      }
      if (code == 'over_email_send_rate_limit' ||
          msg.contains('rate limit') ||
          msg.contains('email rate limit exceeded')) {
        return 'Too many requests. Please wait a few minutes before trying again.';
      }
      if (code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('user already registered')) {
        return 'An account with this email already exists. Please log in instead.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      if (msg.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }
      return error.message;
    }
    if (error is SocketException ||
        error.toString().toLowerCase().contains('socketexception') ||
        error.toString().toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    final text = error.toString().replaceAll('Exception:', '').trim();
    return text.isNotEmpty ? text : 'An error occurred. Please try again.';
  }
}
