import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/primary_button.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';

/// Onboarding data model
class _OnboardingPage {
  final String title;
  final String body;
  final IconData icon;
  final Color iconBg;

  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconBg,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: AppStrings.onboarding1Title,
      body: AppStrings.onboarding1Body,
      icon: Icons.explore_rounded,
      iconBg: Color(0xFFEDE8FD),
    ),
    _OnboardingPage(
      title: AppStrings.onboarding2Title,
      body: AppStrings.onboarding2Body,
      icon: Icons.storefront_rounded,
      iconBg: Color(0xFFFFF3D0),
    ),
    _OnboardingPage(
      title: AppStrings.onboarding3Title,
      body: AppStrings.onboarding3Body,
      icon: Icons.notifications_rounded,
      iconBg: Color(0xFFE8F5E9),
    ),
  ];

  Future<void> _completeOnboarding() async {
    try {
      final storage = await StorageService.getInstance();
      await storage.setBool(StorageKeys.hasSeenOnboarding, true);
    } catch (e) {
      debugPrint('Error setting onboarding state: $e');
    }
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animNormal,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.screenPaddingH),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    AppStrings.onboardingSkip,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPaddingH,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: page.iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spaceXXL),
                        Text(
                          page.title,
                          style: AppTextStyles.headingXL,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spaceMD),
                        Text(
                          page.body,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.all(AppConstants.screenPaddingH),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: AppConstants.animFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppConstants.spaceXL),
                  PrimaryButton(
                    label: _currentPage == _pages.length - 1
                        ? AppStrings.onboardingGetStarted
                        : AppStrings.onboardingNext,
                    onPressed: _nextPage,
                    trailingIcon: _currentPage < _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
