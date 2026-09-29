import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/community_post_model.dart';
import '../../services/community_service.dart';
import '../../routes/app_routes.dart';

/// Screen 6: My Posts matching mockup in project specifications.
class MyCommunityPostsScreen extends StatefulWidget {
  const MyCommunityPostsScreen({super.key});

  @override
  State<MyCommunityPostsScreen> createState() => _MyCommunityPostsScreenState();
}

class _MyCommunityPostsScreenState extends State<MyCommunityPostsScreen> {
  List<CommunityPostModel> _myPosts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Listings'; // 'All Listings', 'Active', 'Expired', 'Draft'

  static const Color _tealColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await CommunityService.instance.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to remove this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await CommunityService.instance.deletePost(id);
    _loadPosts();
  }

  List<CommunityPostModel> get _filteredPosts {
    if (_selectedFilter == 'Active') {
      return _myPosts.where((p) => p.status.toLowerCase() == 'active').toList();
    } else if (_selectedFilter == 'Expired') {
      return _myPosts.where((p) => p.status.toLowerCase() == 'expired' || p.status.toLowerCase() == 'closed').toList();
    } else if (_selectedFilter == 'Draft') {
      return _myPosts.where((p) => p.status.toLowerCase() == 'draft').toList();
    }
    return _myPosts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Posts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (val) => setState(() => _selectedFilter = val),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _selectedFilter,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All Listings', child: Text('All Listings')),
              PopupMenuItem(value: 'Active', child: Text('Active')),
              PopupMenuItem(value: 'Expired', child: Text('Expired')),
              PopupMenuItem(value: 'Draft', child: Text('Draft')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_tealColor),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _filteredPosts.isEmpty
                      ? Center(
                          child: Text(
                            'No $_selectedFilter found.',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, i) {
                            final post = _filteredPosts[i];
                            return _buildMyPostCard(post);
                          },
                        ),
                ),

                // Bottom banner: "+ Post a service to help your community"
                Container(
                  padding: const EdgeInsets.all(20),
                  child: InkWell(
                    onTap: () async {
                      await context.push(AppRoutes.createCommunityPost);
                      _loadPosts();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _tealColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: _tealColor, size: 22),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Post a service to help your community',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMyPostCard(CommunityPostModel post) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel = post.status.toUpperCase();

    if (post.status.toLowerCase() == 'active') {
      badgeBg = const Color(0xFFE8F8F3);
      badgeText = const Color(0xFF10B981);
    } else {
      badgeBg = const Color(0xFFF3F4F6);
      badgeText = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await context.push('/community/${post.id}');
          _loadPosts();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status tag on left; edit + delete icons on right
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await context.push('/community/edit/${post.id}');
                    _loadPosts();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deletePost(post.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Price / Fee
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
    );
  }
}
