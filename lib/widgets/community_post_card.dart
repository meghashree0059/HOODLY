import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/community_post_model.dart';

/// Card widget for a Community Post — matching the project mockups exactly.
class CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback? onTap;
  final bool compact;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.compact = false,
  });

  static const Color _tealColor = Color(0xFF0D9488);
  static const Color _offeringColor = Color(0xFF10B981);
  static const Color _requestingColor = Color(0xFFD97706);
  static const Color _offeringBg = Color(0xFFE8F8F3);
  static const Color _requestingBg = Color(0xFFFEF3C7);

  Future<void> _makeCall(BuildContext context) async {
    if (post.contactPhone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: post.contactPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided for this post.')),
      );
    }
  }

  Future<void> _sendMail(BuildContext context) async {
    if (post.contactEmail.isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: post.contactEmail,
        query: 'subject=${Uri.encodeComponent('Regarding: ${post.title}')}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address provided for this post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactCard(context);
    return _buildFeedCard(context);
  }

  Widget _buildFeedCard(BuildContext context) {
    final isOffering = post.isOffering;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Author Avatar + Name + Distance on left; Type Badge on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE6F4F1),
                      backgroundImage: post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty
                          ? NetworkImage(post.authorAvatarUrl!)
                          : null,
                      child: post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: _tealColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            post.distanceLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOffering ? _offeringBg : _requestingBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOffering ? 'OFFERING' : 'REQUESTING',
                        style: TextStyle(
                          color: isOffering ? _offeringColor : _requestingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  post.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  post.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Bottom Row: Price / Fee on left; Contact icons on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      post.feePayment.isNotEmpty ? post.feePayment : 'Free',
                      style: const TextStyle(
                        color: _tealColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    // Contact icons
                    if (post.contactMethod != 'email')
                      InkWell(
                        onTap: () => _makeCall(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (post.contactMethod != 'email') const SizedBox(width: 8),
                    if (post.contactMethod != 'phone')
                      InkWell(
                        onTap: () => _sendMail(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
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

  Widget _buildCompactCard(BuildContext context) {
    final isOffering = post.isOffering;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOffering ? _offeringBg : _requestingBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOffering ? 'OFFERING' : 'REQUESTING',
                        style: TextStyle(
                          color: isOffering ? _offeringColor : _requestingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post.distanceLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  post.feePayment.isNotEmpty ? post.feePayment : 'Free',
                  style: const TextStyle(
                    color: _tealColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
