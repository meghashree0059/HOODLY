/// Hoodly UI Strings — single source of truth for all user-visible text.
/// Centralised here for easy localisation in the future (ARB / l10n).
abstract final class AppStrings {
  // ── App ──────────────────────────────────────────────────────
  static const String appName = 'Hoodly';
  static const String appTagline = 'Discover Hidden Local Businesses Around You';

  // ── Splash ───────────────────────────────────────────────────
  static const String splashLoading = 'Loading…';

  // ── Onboarding ───────────────────────────────────────────────
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get Started';

  static const String onboarding1Title = 'Explore Your Hood';
  static const String onboarding1Body =
      'Find hidden gems, local shops, and neighbourhood services right around you.';

  static const String onboarding2Title = 'Support Local';
  static const String onboarding2Body =
      'Discover authentic local businesses that make your community unique.';

  static const String onboarding3Title = 'Stay Connected';
  static const String onboarding3Body =
      'Get real-time updates, deals, and events from businesses near you.';

  // ── Auth ─────────────────────────────────────────────────────
  static const String login = 'Log In';
  static const String register = 'Sign Up';
  static const String logout = 'Log Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String orContinueWith = 'Or continue with';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String createAccount = 'Create Account';
  static const String welcomeBack = 'Welcome back!';
  static const String joinHoodly = 'Join Hoodly';
  static const String loginSubtitle = 'Log in to discover your neighbourhood';
  static const String registerSubtitle = 'Create your account to get started';

  // ── Form Fields ──────────────────────────────────────────────
  static const String labelEmail = 'Email Address';
  static const String labelPassword = 'Password';
  static const String labelConfirmPassword = 'Confirm Password';
  static const String labelFullName = 'Full Name';
  static const String labelPhone = 'Phone Number';
  static const String hintEmail = 'Enter your email';
  static const String hintPassword = 'Enter your password';
  static const String hintConfirmPassword = 'Re-enter your password';
  static const String hintFullName = 'Enter your full name';
  static const String hintPhone = 'Enter your phone number';

  // ── Validation ───────────────────────────────────────────────
  static const String validEmail = 'Please enter a valid email address';
  static const String validEmailRequired = 'Email is required';
  static const String validPasswordMin = 'Password must be at least 8 characters';
  static const String validPasswordRequired = 'Password is required';
  static const String validPasswordMismatch = 'Passwords do not match';
  static const String validNameRequired = 'Full name is required';
  static const String validPhoneRequired = 'Phone number is required';
  static const String validPhoneInvalid = 'Please enter a valid phone number';

  // ── Home ─────────────────────────────────────────────────────
  static const String homeGreeting = 'Good morning 👋';
  static const String homeSearchHint = 'Search businesses, services…';
  static const String homeSectionNearby = 'Nearby Businesses';
  static const String homeSectionTrending = 'Trending Now';
  static const String homeSectionCategories = 'Browse Categories';
  static const String homeSeeAll = 'See All';

  // ── Business ─────────────────────────────────────────────────
  static const String businessOpen = 'Open Now';
  static const String businessClosed = 'Closed';
  static const String businessContact = 'Contact';
  static const String businessDirections = 'Directions';
  static const String businessShare = 'Share';
  static const String businessReviews = 'Reviews';
  static const String businessAbout = 'About';

  // ── Profile ──────────────────────────────────────────────────
  static const String profileTitle = 'My Profile';
  static const String profileEdit = 'Edit Profile';
  static const String profileSavedPlaces = 'Saved Places';
  static const String profileSettings = 'Settings';
  static const String profileHelp = 'Help & Support';
  static const String profilePrivacy = 'Privacy Policy';

  // ── Navigation ───────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navExplore = 'Explore';
  static const String navSaved = 'Saved';
  static const String navBusiness = 'Business';
  static const String navProfile = 'Profile';

  // ── Errors ───────────────────────────────────────────────────
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Check your network.';
  static const String errorNotFound = 'No results found.';
  static const String errorTimeout = 'Request timed out. Please try again.';

  // ── Actions ──────────────────────────────────────────────────
  static const String actionRetry = 'Retry';
  static const String actionCancel = 'Cancel';
  static const String actionConfirm = 'Confirm';
  static const String actionSave = 'Save';
  static const String actionDelete = 'Delete';
  static const String actionContinue = 'Continue';
}
