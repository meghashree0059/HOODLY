/// Named route constants for the Hoodly app.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String home = '/home';
  static const String business = '/business';
  static const String businessDetail = '/business/:id';
  static const String editBusiness = '/business/edit/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String myBusinesses = '/profile/businesses';
  static const String settings = '/settings';
}
