import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

/// A reusable Material 3 styled text field.
///
/// Usage:
/// ```dart
/// HoodlyTextField(
///   controller: _emailController,
///   label: 'Email Address',
///   hint: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
///   validator: AppValidators.email,
/// )
/// ```
class HoodlyTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const HoodlyTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<HoodlyTextField> createState() => _HoodlyTextFieldState();
}

class _HoodlyTextFieldState extends State<HoodlyTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          autocorrect: widget.obscureText ? false : widget.autocorrect,
          enableSuggestions: widget.obscureText ? false : widget.enableSuggestions,
          keyboardType: widget.keyboardType,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textHint,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? AnimatedContainer(
                    duration: AppConstants.animFast,
                    child: Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: AppConstants.iconMD,
                    ),
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _isFocused ? AppColors.primary : AppColors.textHint,
          size: AppConstants.iconMD,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffix;
  }
}
