import 'package:flutter/material.dart';
import 'hoodly_image.dart';
import '../models/business_model.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';

enum BusinessCardLayout { horizontal, vertical }

class BusinessCard extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback? onTap;
  final BusinessCardLayout layout;
  final double? width;
  final double? height;

  const BusinessCard({
    super.key,
    required this.business,
    this.onTap,
    this.layout = BusinessCardLayout.vertical,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width ?? (layout == BusinessCardLayout.vertical ? 240 : double.infinity),
          height: height ?? (layout == BusinessCardLayout.vertical ? 290 : 120),
          child: layout == BusinessCardLayout.vertical
              ? _buildVerticalLayout(context)
              : _buildHorizontalLayout(context),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Header
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              // Rating Badge
              Positioned(
                top: AppConstants.spaceSM,
                right: AppConstants.spaceSM,
                child: _buildRatingBadge(),
              ),
              // Category Overlay on bottom-left of image
              Positioned(
                bottom: AppConstants.spaceSM,
                left: AppConstants.spaceSM,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                  ),
                  child: Text(
                    business.category,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Footer Row: Distance
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        business.distanceLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (business.isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OPEN',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Image
        AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              Positioned(
                top: AppConstants.spaceXS,
                left: AppConstants.spaceXS,
                child: _buildRatingBadge(),
              ),
            ],
          ),
        ),
        // Right: Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            business.category.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (business.isOpen)
                          Text(
                            'OPEN',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${business.distanceLabel} • ${business.address.split(',').first}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return HoodlyImage(
      imageUrl: business.imageUrl,
      fit: BoxFit.cover,
      fallbackWidget: _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    // Generate a consistent color based on the business name hash
    final hash = business.name.hashCode;
    final gradients = [
      [const Color(0xFF6C3EF4), const Color(0xFF8B65F7)],
      [const Color(0xFFFFB800), const Color(0xFFFFD04D)],
      [const Color(0xFF3498DB), const Color(0xFF5DADE2)],
      [const Color(0xFF2ECC71), const Color(0xFF58D68D)],
      [const Color(0xFFE74C3C), const Color(0xFFEC7063)],
      [const Color(0xFF9B59B6), const Color(0xFFAF7AC5)],
    ];
    final colorPair = gradients[hash.abs() % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(business.category),
              color: Colors.white.withValues(alpha: 0.9),
              size: layout == BusinessCardLayout.vertical ? 40 : 30,
            ),
            if (layout == BusinessCardLayout.vertical) ...[
              const SizedBox(height: 8),
              Text(
                business.name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppColors.secondary,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            business.rating.toStringAsFixed(1),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' (${business.reviewCount})',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'home food':
      case 'food':
        return Icons.restaurant_menu_rounded;
      case 'bakery':
        return Icons.cake_rounded;
      case 'beauty':
        return Icons.face_rounded;
      case 'services':
        return Icons.construction_rounded;
      case 'crafts':
        return Icons.brush_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
