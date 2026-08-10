import '../constants/app_strings.dart';

/// Form field validators used across the Hoodly app.
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
  static String? Function(String?) confirmPassword(String originalPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.validPasswordRequired;
      }
      if (value != originalPassword) {
        return AppStrings.validPasswordMismatch;
      }
      return null;
    };
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
}
