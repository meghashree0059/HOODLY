import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

/// A reusable section title with optional subtitle and "See All" action.
///
/// Usage:
/// ```dart
/// SectionTitle(title: 'Nearby Businesses')
/// SectionTitle(
///   title: 'Trending Now',
///   subtitle: 'Popular in your area',
///   onSeeAll: () {},
/// )
/// ```
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.seeAllLabel = 'See All',
    this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppConstants.screenPaddingH,
      vertical: AppConstants.spaceMD,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: accent bar + title
          Expanded(
            child: Row(
              children: [
                // Purple accent bar
                Container(
                  width: 4,
                  height: subtitle != null ? 38 : 22,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSM),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: See All
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.only(left: AppConstants.spaceSM),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seeAllLabel,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
