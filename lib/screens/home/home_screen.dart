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
import '../../services/business_service.dart';
import '../../services/location_service.dart';

import '../business/add_business_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  // Location
  Position? _userPosition;
  String _locationLabel = 'Fetching location...';

  // Categories
  List<Map<String, dynamic>> _dbCategories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Businesses
  List<BusinessModel> _businesses = [];
  bool _isLoadingBusinesses = true;
  String? _businessError;

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
    _initLocation();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
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
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        final label = await LocationService.instance.getLocalityName(position.latitude, position.longitude);
        setState(() {
          _userPosition = position;
          _locationLabel = label;
        });
      } else {
        setState(() {
          _locationLabel = 'Location unavailable';
        });
      }
      // Load businesses after location resolves
      _loadBusinesses();
    } catch (e) {
      setState(() {
        _locationLabel = 'Location unavailable';
      });
      _loadBusinesses();
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
          // Index 3: Bookmarks Page (Placeholder for Phase 3)
          _buildPlaceholderPage(Icons.bookmark_rounded, 'Saved Businesses. Your bookmarked spots will appear here.'),
          // Index 4: Profile Page
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: HoodlyBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context, bool isTablet) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _initLocation();
          await _loadCategories();
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
                    Row(
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
                        Column(
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
                                Text(
                                  _locationLabel,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
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
                      ],
                    ),
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
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingH),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: AppConstants.spaceMD),
          Text(
            _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No businesses found in this area',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
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

  Widget _buildPlaceholderPage(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: AppConstants.spaceLG),
            Text('Coming Soon', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppConstants.spaceSM),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
