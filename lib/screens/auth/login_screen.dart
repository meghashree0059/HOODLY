import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HoodlyAppBar(title: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spaceLG),
                Text(AppStrings.welcomeBack, style: AppTextStyles.headingXL),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  AppStrings.loginSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXXL),
                HoodlyTextField(
                  controller: _emailController,
                  label: AppStrings.labelEmail,
                  hint: AppStrings.hintEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: AppConstants.spaceMD),
                HoodlyTextField(
                  controller: _passwordController,
                  label: AppStrings.labelPassword,
                  hint: AppStrings.hintPassword,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: AppValidators.password,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppConstants.spaceSM),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      if (email.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email first.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        return;
                      }
                      try {
                        await AuthService.instance.sendPasswordResetEmail(email: email);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Password reset link sent! Check your email.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception:', '').trim()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: Text(AppStrings.forgotPassword),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),
                PrimaryButton(
                  label: AppStrings.login,
                  onPressed: _onLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppConstants.spaceXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: Text(AppStrings.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
