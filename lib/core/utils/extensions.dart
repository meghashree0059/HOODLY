import 'package:flutter/material.dart';

/// Dart extension methods used throughout the Hoodly app.
extension BuildContextX on BuildContext {
  // ── Theme Shortcuts ──────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── Media Query Shortcuts ─────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomBarHeight => MediaQuery.paddingOf(this).bottom;

  // ── Breakpoints ──────────────────────────────────────────────
  bool get isSmall => screenWidth < 360;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // ── Navigation ───────────────────────────────────────────────
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  void popUntilRoot() =>
      Navigator.of(this).popUntil((route) => route.isFirst);

  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );

  Future<T?> pushReplacement<T>(Widget page) =>
      Navigator.of(this).pushReplacement<T, dynamic>(
        MaterialPageRoute(builder: (_) => page),
      );

  Future<T?> pushAndRemoveUntilRoot<T>(Widget page) =>
      Navigator.of(this).pushAndRemoveUntil<T>(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );

  // ── Snackbar ─────────────────────────────────────────────────
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.black87,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Keyboard ─────────────────────────────────────────────────
  void hideKeyboard() => FocusScope.of(this).unfocus();
}

extension StringX on String {
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  bool get isValidPhone =>
      RegExp(r'^\+?[0-9]{7,15}$').hasMatch(replaceAll(' ', ''));

  bool get isValidPassword => length >= 8;

  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String truncate(int maxLength, {String ellipsis = '…'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$ellipsis';
}

extension DoubleX on double {
  SizedBox get verticalSpace => SizedBox(height: this);
  SizedBox get horizontalSpace => SizedBox(width: this);
}

extension IntX on int {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
  Duration get ms => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
}
