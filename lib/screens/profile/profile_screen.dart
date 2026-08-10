import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.currentUser;
      setState(() {
        _user = user;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user!.fullName);
    final phoneController = TextEditingController(text: _user!.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXL),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppConstants.screenPaddingH,
                24,
                AppConstants.screenPaddingH,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppConstants.spaceMD),
                    HoodlyTextField(
                      controller: nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spaceMD),
                    HoodlyTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton.outlined(
                            label: 'Cancel',
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Save',
                            isLoading: isSaving,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ?? false)) return;

                                    setSheetState(() => isSaving = true);
                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final updated = await AuthService.instance.updateProfile(
                                        fullName: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                      );
                                      setState(() {
                                        _user = updated;
                                      });
                                      if (!mounted) return;
                                      nav.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Profile updated successfully!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Update failed: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } finally {
                                      setSheetState(() => isSaving = false);
                                    }
                                  },
                        ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. Premium Purple Gradient Header
              _buildProfileHeader(context),
              
              const SizedBox(height: AppConstants.spaceLG),

              // 2. Options List
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        // Basic Account Actions
                        _buildOptionsCard([
                          _buildOptionTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile',
                            subtitle: 'Change name, phone, or avatar',
                            onTap: () => _showEditProfileBottomSheet(context),
                          ),
                          _buildOptionTile(
                            icon: Icons.storefront_outlined,
                            title: 'My Businesses',
                            subtitle: 'Manage your listed stores and services',
                            onTap: () {
                              context.push(AppRoutes.myBusinesses);
                            },
                          ),
                        ]),

                        const SizedBox(height: AppConstants.spaceMD),

                        // System Actions
                        _buildOptionsCard([
                          _buildOptionTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'Preferences, security, notifications',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'FAQs, contact us, feedback',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: AppConstants.spaceMD),

                        // Logout Card
                        _buildOptionsCard([
                          _buildOptionTile(
                            icon: Icons.logout_rounded,
                            title: 'Logout',
                            titleColor: AppColors.error,
                            iconColor: AppColors.error,
                            showTrailing: false,
                            onTap: () {
                              _showLogoutConfirmDialog(context);
                            },
                          ),
                        ]),
                        
                        const SizedBox(height: AppConstants.space4XL),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final name = _user?.fullName ?? 'Hoodly User';
    final email = _user?.email ?? '';
    final phone = _user?.phone ?? 'No phone provided';
    final avatarUrl = _user?.avatarUrl ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF4F2ED9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusXXL + 8),
          bottomRight: Radius.circular(AppConstants.radiusXXL + 8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH,
        statusBarHeight + AppConstants.spaceLG,
        AppConstants.screenPaddingH,
        AppConstants.spaceXXL,
      ),
      child: Column(
        children: [
          // Header title
          Text(
            'Profile',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),
          
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: NetworkImage(avatarUrl),
            ),
          ),
          const SizedBox(height: AppConstants.spaceMD),
          
          // Name
          Text(
            name,
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          
          // Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(List<Widget> tiles) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: tiles,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: showTrailing
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceMD,
        vertical: 6,
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          title: Text(
            'Confirm Logout',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to log out of Hoodly?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final router = GoRouter.of(context);
                nav.pop();
                await AuthService.instance.signOut();
                if (!mounted) return;
                router.go(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
