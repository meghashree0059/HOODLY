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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
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
      appBar: HoodlyAppBar(
        title: '',
        showBack: true,
        onBackPressed: () => context.go(AppRoutes.login),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spaceLG),
                Text(AppStrings.joinHoodly, style: AppTextStyles.headingXL),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  AppStrings.registerSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXXL),
                HoodlyTextField(
                  controller: _nameController,
                  label: AppStrings.labelFullName,
                  hint: AppStrings.hintFullName,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.fullName,
                ),
                const SizedBox(height: AppConstants.spaceMD),
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
                ),
                const SizedBox(height: AppConstants.spaceMD),
                HoodlyTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.labelConfirmPassword,
                  hint: AppStrings.hintConfirmPassword,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: AppValidators.confirmPassword(
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppConstants.spaceXXL),
                PrimaryButton(
                  label: AppStrings.createAccount,
                  onPressed: _onRegister,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppConstants.spaceXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(AppStrings.login),
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
