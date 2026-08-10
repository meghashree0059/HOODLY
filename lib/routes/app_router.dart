import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/business/business_screen.dart';
import '../screens/business/my_businesses_screen.dart';
import '../screens/business/edit_business_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'app_routes.dart';

/// GoRouter configuration for the Hoodly app.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => _slidePage(
        state,
        const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => _slidePage(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      pageBuilder: (context, state) => _slidePage(
        state,
        const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.business,
      name: 'business',
      pageBuilder: (context, state) => _slidePage(
        state,
        const BusinessScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessDetail,
      name: 'business_detail',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _slidePage(
          state,
          BusinessScreen(businessId: id),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.editBusiness,
      name: 'edit_business',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _slidePage(
          state,
          EditBusinessScreen(businessId: id),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.myBusinesses,
      name: 'my_businesses',
      pageBuilder: (context, state) => _slidePage(
        state,
        const MyBusinessesScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      pageBuilder: (context, state) => _slidePage(
        state,
        const ProfileScreen(),
      ),
    ),
  ],

  // Global error page
  errorPageBuilder: (context, state) => MaterialPage(
    child: Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  ),
);

/// Custom slide-up transition
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// Fade transition
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
