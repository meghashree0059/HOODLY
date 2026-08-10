import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

/// Reusable Hoodly AppBar.
///
/// Usage:
/// ```dart
/// HoodlyAppBar(title: 'Home')
/// HoodlyAppBar.transparent(title: 'Details', showBack: true)
/// ```
class HoodlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final bool transparent;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const HoodlyAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.transparent = false,
    this.onBackPressed,
    this.bottom,
  });

  const HoodlyAppBar.transparent({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.centerTitle = true,
    this.foregroundColor,
    this.actions,
    this.leading,
    this.onBackPressed,
    this.bottom,
  })  : backgroundColor = Colors.transparent,
        elevation = 0,
        transparent = true;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final bgColor = transparent
        ? Colors.transparent
        : (backgroundColor ?? AppColors.surface);

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: elevation,
      scrolledUnderElevation: transparent ? 0 : 0.5,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      bottom: bottom,
      leading: _buildLeading(context),
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: foregroundColor ?? AppColors.textPrimary,
                  ),
                )
              : null),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: AppConstants.spaceXS),
            ]
          : null,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBack) return null;

    return GestureDetector(
      onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        margin: const EdgeInsets.only(left: AppConstants.spaceMD),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: foregroundColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}
