import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/community_post_model.dart';
import '../../services/community_service.dart';
import '../../services/location_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/community_post_card.dart';

/// Full-page Community Services browse screen (matching the project mockup).
class CommunityServicesScreen extends StatefulWidget {
  const CommunityServicesScreen({super.key});

  @override
  State<CommunityServicesScreen> createState() =>
      CommunityServicesScreenState();
}

class CommunityServicesScreenState extends State<CommunityServicesScreen> {
  Position? _userPosition;

  /// Public reload method callable from parent widgets / tab switches.
  Future<void> reload() => _loadPosts();

  // Filter: null = 'All', 'offering', 'requesting'
  String? _selectedPostType;

  List<CommunityPostModel> _posts = [];
  bool _isLoading = true;
  String? _error;

  static const Color _tealColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadLocation();
    await _loadPosts();
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = pos;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await CommunityService.instance.getPosts(
        postType: _selectedPostType,
        userLatitude: _userPosition?.latitude,
        userLongitude: _userPosition?.longitude,
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load community posts.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _init,
          color: _tealColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Header (Title + Subtitle + My Posts shortcut)
              SliverToBoxAdapter(child: _buildHeader()),

              // 2. Filter Pills: [ All ] [ Offering ] [ Requesting ]
              SliverToBoxAdapter(child: _buildFilterPills()),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 3. Post Feed Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_tealColor),
                    ),
                  ),
                )
              else if (_error != null && _posts.isEmpty)
                SliverFillRemaining(child: _buildError())
              else if (_posts.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPaddingH,
                    vertical: 4,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final post = _posts[i];
                        return CommunityPostCard(
                          post: post,
                          onTap: () async {
                            await context.push('/community/${post.id}');
                            _loadPosts();
                          },
                        );
                      },
                      childCount: _posts.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.createCommunityPost);
          _loadPosts();
        },
        backgroundColor: _tealColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH,
        18,
        AppConstants.screenPaddingH,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Services',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Help & requests within 5 km',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'My Posts',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 20,
                color: _tealColor,
              ),
            ),
            onPressed: () {
              context.push('/community/my-posts');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      (null, 'All'),
      ('offering', 'Offering'),
      ('requesting', 'Requesting'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPaddingH,
        vertical: 4,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedPostType == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                if (_selectedPostType != f.$1) {
                  setState(() => _selectedPostType = f.$1);
                  _loadPosts();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _tealColor : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? _tealColor : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _tealColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Failed to load community posts.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh_rounded, color: _tealColor),
              label: const Text('Retry', style: TextStyle(color: _tealColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _tealColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_outlined, color: _tealColor, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts in this category',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to offer or request help in your neighbourhood.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
