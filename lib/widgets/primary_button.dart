import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

/// A fully-featured gradient primary button with loading state.
///
/// Usage:
/// ```dart
/// PrimaryButton(
///   label: 'Get Started',
///   onPressed: () {},
/// )
/// ```
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppConstants.buttonHeight,
    this.borderRadius = AppConstants.radiusLG,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  });

  /// Outlined / secondary variant
  const PrimaryButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppConstants.buttonHeight,
    this.borderRadius = AppConstants.radiusLG,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  }) : isOutlined = true;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();
  void _onTapUp(_) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: widget.isOutlined
              ? _buildOutlined(context)
              : _buildFilled(context),
        ),
      ),
    );
  }

  Widget _buildFilled(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isDisabled ? 0.6 : 1.0,
      duration: AppConstants.animFast,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isDisabled
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isDisabled ? AppColors.textHint : widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isDisabled ? null : AppColors.primaryShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDisabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Center(child: _buildContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlined(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isDisabled ? 0.6 : 1.0,
      duration: AppConstants.animFast,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1.8),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Colors.transparent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDisabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Center(child: _buildContent(outlined: true)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({bool outlined = false}) {
    final labelColor = outlined
        ? (widget.textColor ?? AppColors.primary)
        : (widget.textColor ?? AppColors.textOnPrimary);

    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(labelColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, color: labelColor, size: AppConstants.iconSM),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: (widget.textStyle ?? AppTextStyles.buttonLabel).copyWith(
            color: labelColor,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, color: labelColor, size: AppConstants.iconSM),
        ],
      ],
    );
  }
}
