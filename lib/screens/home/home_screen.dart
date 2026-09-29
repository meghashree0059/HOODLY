import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/section_title.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/business_card.dart';
import '../../models/business_model.dart';
import '../../models/community_post_model.dart';
import '../../services/business_service.dart';
import '../../services/community_service.dart';
import '../../services/location_service.dart';
import '../../widgets/community_post_card.dart';

import '../business/add_business_screen.dart';
import '../community/community_services_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final GlobalKey<CommunityServicesScreenState> _communityServicesKey =
      GlobalKey<CommunityServicesScreenState>();

  // Location
  Position? _userPosition;
  String _locationLabel = 'Fetching location...';
  bool _locationPermanentlyDenied = false;

  // Categories
  List<Map<String, dynamic>> _dbCategories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Businesses
  List<BusinessModel> _businesses = [];
  bool _isLoadingBusinesses = true;
  String? _businessError;

  // Community Posts
  List<CommunityPostModel> _communityPosts = [];
  bool _isLoadingCommunity = true;
  String? _communityError;

  // Search
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  // Category icon/color mapping
  static const Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_menu_rounded,
    'café': Icons.local_cafe_rounded,
    'bakery': Icons.cake_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'clothing': Icons.checkroom_rounded,
    'services': Icons.construction_rounded,
    'home business': Icons.home_work_rounded,
    'beauty': Icons.face_rounded,
    'electronics': Icons.devices_rounded,
    'hangout': Icons.nightlife_rounded,
    'other': Icons.grid_view_rounded,
  };

  static const Map<String, Color> _categoryColors = {
    'food': Color(0xFFEDE8FD),
    'restaurant': Color(0xFFFFF3D0),
    'café': Color(0xFFFFEAD4),
    'bakery': Color(0xFFFFF3D0),
    'shopping': Color(0xFFE8F5E9),
    'clothing': Color(0xFFE1F5FE),
    'services': Color(0xFFE8F5E9),
    'home business': Color(0xFFEDE8FD),
    'beauty': Color(0xFFFFEAEA),
    'electronics': Color(0xFFE1F5FE),
    'hangout': Color(0xFFF3E5F5),
    'other': Color(0xFFF2F0FA),
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);

    // Trigger location permission (real Android OS dialog) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initLocation();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text.trim()) {
        setState(() => _searchQuery = _searchController.text.trim());
        _loadBusinesses();
      }
    });
  }

  Future<void> _initLocation() async {
    // Check OS permission first, request if needed (triggers real Android system dialog)
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationPermanentlyDenied = true;
          _locationLabel = 'Location access blocked';
        });
      }
      return;
    }

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        final label = await LocationService.instance.getLocalityName(
            position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _userPosition = position;
            _locationLabel = label;
            _locationPermanentlyDenied = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locationLabel = 'Location unavailable';
          });
        }
      }
      // Load businesses and community posts after location resolves
      if (mounted) {
        _loadBusinesses();
        _loadCommunityPosts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationLabel = 'Location unavailable';
        });
        _loadBusinesses();
        _loadCommunityPosts();
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final list = await BusinessService.instance.getCategories();
      setState(() => _dbCategories = list);
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoadingBusinesses = true;
      _businessError = null;
    });

    try {
      final businesses = await BusinessService.instance.getBusinesses(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        userLatitude: _userPosition?.latitude,
        userLongitude: _userPosition?.longitude,
      );
      setState(() {
        _businesses = businesses;
        _isLoadingBusinesses = false;
      });
    } catch (e) {
      setState(() {
        _businessError = 'Failed to load businesses. Check your connection and try again.';
        _isLoadingBusinesses = false;
      });
    }
  }

  Future<void> _loadCommunityPosts() async {
    setState(() {
      _isLoadingCommunity = true;
      _communityError = null;
    });

    try {
      final posts = await CommunityService.instance.getPosts(
        userLatitude: _userPosition?.latitude,
        userLongitude: _userPosition?.longitude,
      );
      if (mounted) {
        setState(() {
          _communityPosts = posts;
          _isLoadingCommunity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _communityError = 'Failed to load community services.';
          _isLoadingCommunity = false;
        });
      }
    }
  }

  void _onCategoryTap(String? categoryId, String? categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
    });
    _loadBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          // Index 0: Home Feed
          _buildHomeFeed(context, isTablet),
          // Index 1: Explore Page (Search-focused)
          _buildExplorePage(context),
          // Index 2: Add Business Page
          AddBusinessScreen(
            onBackToHome: () {
              setState(() => _currentNavIndex = 0);
              _loadBusinesses();
            },
          ),
          // Index 3: Community Services Page
          CommunityServicesScreen(key: _communityServicesKey),
          // Index 4: Profile Page
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: HoodlyBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          setState(() => _currentNavIndex = i);
          if (i == 0) {
            _loadCommunityPosts();
          } else if (i == 3) {
            _communityServicesKey.currentState?.reload();
          }
        },
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context, bool isTablet) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _initLocation();
          await _loadCategories();
          await _loadCommunityPosts();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. App Header with Location & Notification Icon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH,
                  vertical: AppConstants.spaceMD,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Picker
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _locationLabel,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textPrimary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification Icon
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingH,
                  vertical: AppConstants.spaceXS,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search businesses, cafés, services...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadBusinesses();
                              },
                            )
                          : Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                            ),
                      fillColor: AppColors.surface,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceMD)),

            // 3. Banner Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4F2ED9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20, top: -20,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                      Positioned(
                        right: 40, bottom: -30,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.spaceXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Support Local\nGrow Local',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800, height: 1.25,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spaceSM),
                            GestureDetector(
                              onTap: () => setState(() => _currentNavIndex = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                                  boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Text(
                                  'List Your Business',
                                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceLG)),

            // 4. Categories Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                    child: Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: AppConstants.spaceMD),
                  _buildCategoryScroll(isTablet),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceXL)),

            // 5. Businesses Section title
            SliverToBoxAdapter(
              child: SectionTitle(
                title: _searchQuery.isNotEmpty
                    ? 'Results for "$_searchQuery"'
                    : _selectedCategoryName != null
                        ? _selectedCategoryName!
                        : 'Popular Near You',
                onSeeAll: () {},
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceSM)),

            // 6. Business Cards or state widgets
            if (_isLoadingBusinesses)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
                ),
              )
            else if (_businessError != null)
              SliverToBoxAdapter(child: _buildErrorState())
            else if (_businesses.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 295,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                    itemCount: _businesses.length,
                    itemBuilder: (context, index) {
                      final business = _businesses[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.spaceMD),
                        child: BusinessCard(
                          business: business,
                          onTap: () {
                            context.push('/business/${business.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceXL)),

            // 7. Community Services Section Title
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Community Services',
                seeAllLabel: 'See All',
                onSeeAll: () {
                  setState(() => _currentNavIndex = 3);
                },
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.spaceSM)),

            // 8. Community Services Cards
            if (_isLoadingCommunity)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1BA97F)),
                    ),
                  ),
                ),
              )
            else if (_communityError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                  child: Text(
                    _communityError!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (_communityPosts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1BA97F).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: Color(0xFF1BA97F), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No community posts nearby yet',
                                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Offer or request help from your neighbours.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _currentNavIndex = 3),
                          child: const Text('Browse', style: TextStyle(color: Color(0xFF1BA97F))),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 135,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
                    itemCount: _communityPosts.length,
                    itemBuilder: (context, index) {
                      final post = _communityPosts[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.spaceMD),
                        child: CommunityPostCard(
                          post: post,
                          compact: true,
                          onTap: () {
                            context.push('/community/${post.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.space4XL)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScroll(bool isTablet) {
    // "All" option + db categories
    final List<Map<String, dynamic>> displayCategories = [
      {'id': null, 'name': 'All', 'icon': Icons.apps_rounded, 'color': const Color(0xFFEDE8FD), 'iconColor': AppColors.primary},
      ..._dbCategories.map((cat) {
        final key = (cat['name'] as String).toLowerCase();
        return {
          'id': cat['id'],
          'name': cat['name'],
          'icon': _categoryIcons[key] ?? Icons.storefront_rounded,
          'color': _categoryColors[key] ?? const Color(0xFFF2F0FA),
          'iconColor': AppColors.primary,
        };
      }),
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final cat = displayCategories[index];
          final bool isSelected = cat['id'] == _selectedCategoryId;
          return GestureDetector(
            onTap: () => _onCategoryTap(cat['id'], cat['name'] == 'All' ? null : cat['name'] as String),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : cat['iconColor'] as Color, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingH),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 48),
          const SizedBox(height: AppConstants.spaceMD),
          Text(_businessError!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppConstants.spaceMD),
          TextButton.icon(
            onPressed: _loadBusinesses,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isLocationMissing = _userPosition == null;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingH),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              isLocationMissing ? Icons.location_off_rounded : Icons.search_off_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppConstants.spaceMD),
          Text(
            isLocationMissing
                ? (_locationPermanentlyDenied
                    ? 'Location Access Blocked'
                    : 'Location Access Required')
                : _searchQuery.isNotEmpty
                    ? 'No results for "$_searchQuery"'
                    : 'No businesses found within 5 km',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spaceXS),
          Text(
            isLocationMissing
                ? (_locationPermanentlyDenied
                    ? 'Location access was permanently denied. Open App Settings, enable location for Hoodly, then return.'
                    : 'Hoodly needs your location to discover local businesses within 5 km. Please allow location access.')
                : 'Try adjusting your search query or selecting a different category.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (isLocationMissing) ...[
            const SizedBox(height: AppConstants.spaceMD),
            if (_locationPermanentlyDenied)
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  // Re-check permission when user returns from Settings
                  if (mounted) await _initLocation();
                },
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Open App Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  await _initLocation();
                },
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Allow Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplorePage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.spaceMD),
            Text('Explore', style: AppTextStyles.headingXL),
            const SizedBox(height: AppConstants.spaceXS),
            Text('Browse all local listings in your area',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.spaceMD),
            // Search bar
            TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search businesses, services...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                fillColor: AppColors.surface,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceMD),
            // Businesses list
            Expanded(
              child: _isLoadingBusinesses
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                  : _businesses.isEmpty
                      ? Center(child: Text('No businesses found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _businesses.length,
                          itemBuilder: (context, index) {
                            final business = _businesses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppConstants.spaceMD),
                              child: BusinessCard(
                                business: business,
                                layout: BusinessCardLayout.horizontal,
                                onTap: () => context.push('/business/${business.id}'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
