import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/business_model.dart';
import '../../models/review_model.dart';
import '../../services/business_service.dart';
import '../../services/location_service.dart';
import '../../services/review_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as io;
import '../../widgets/hoodly_image.dart';

class BusinessScreen extends StatefulWidget {
  final String? businessId;

  const BusinessScreen({super.key, this.businessId});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  BusinessModel? _business;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  late final PageController _pageController;

  // Distance
  Position? _userPosition;
  double? _distanceKm;
  bool _locationDenied = false;

  // Reviews
  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = true;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadBusiness();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    if (widget.businessId == null || widget.businessId!.isEmpty) {
      setState(() { _error = 'Invalid business ID.'; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final business = await BusinessService.instance.getBusinessById(widget.businessId!);
      setState(() { _business = business; _isLoading = false; });
      _loadReviews();
      _updateDistance();
    } catch (e) {
      setState(() { _error = 'Could not load business details. Please try again.'; _isLoading = false; });
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        setState(() => _userPosition = pos);
        _updateDistance();
      } else {
        setState(() => _locationDenied = true);
      }
    } catch (_) {
      setState(() => _locationDenied = true);
    }
  }

  void _updateDistance() {
    if (_userPosition == null || _business == null) return;
    final b = _business!;
    if (b.latitude == 0.0 && b.longitude == 0.0) return;
    final dist = LocationService.instance.calculateDistanceKm(
      _userPosition!.latitude,
      _userPosition!.longitude,
      b.latitude,
      b.longitude,
    );
    setState(() => _distanceKm = dist);
  }

  Future<void> _loadReviews() async {
    if (widget.businessId == null) return;
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await ReviewService.instance.getReviewsForBusiness(widget.businessId!);
      final stats = ReviewService.computeStats(reviews);
      setState(() {
        _reviews = reviews;
        _avgRating = stats.average;
        _reviewsLoading = false;
      });
    } catch (e) {
      debugPrint('BusinessScreen._loadReviews error: $e');
      setState(() => _reviewsLoading = false);
    }
  }

  String get _distanceLabel {
    if (_distanceKm == null) {
      return _locationDenied ? 'Location unavailable' : 'Calculating...';
    }
    final km = _distanceKm!;
    if (km < 1.0) return '${(km * 1000).round()}m away';
    return '${km.toStringAsFixed(1)}km away';
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final raw = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(raw);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard!')),
    );
  }

  Future<void> _launchMapsDirections(double lat, double lng) async {
    if (lat == 0.0 && lng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business location not available for directions.')),
      );
      return;
    }
    final mapsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    try {
      bool launched = await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.')),
        );
      }
    } catch (_) {
      try {
        await launchUrl(geoUri);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.')),
        );
      }
    }
  }

  void _showWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WriteReviewSheet(
        businessId: widget.businessId!,
        onReviewSubmitted: () {
          Navigator.pop(ctx);
          _loadReviews();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const _LoadingState()
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadBusiness)
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final b = _business!;
    final List<String> allImages = [];
    if (b.imageUrl != null && b.imageUrl!.isNotEmpty) {
      allImages.add(b.imageUrl!);
    }
    for (final img in b.images) {
      if (img.isNotEmpty && !allImages.contains(img)) {
        allImages.add(img);
      }
    }
    final hasImages = allImages.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Hero Image Carousel
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                hasImages
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: allImages.length,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemBuilder: (context, index) {
                          return HoodlyImage(
                            imageUrl: allImages[index],
                            fit: BoxFit.cover,
                            fallbackWidget: _buildPlaceholderHero(b),
                          );
                        },
                      )
                    : _buildPlaceholderHero(b),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                if (allImages.length > 1)
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allImages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentImageIndex == i ? 20 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business name + open status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: AppTextStyles.headingLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: b.isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                        border: Border.all(color: b.isOpen ? AppColors.success : AppColors.error),
                      ),
                      child: Text(
                        b.isOpen ? 'Open' : 'Closed',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: b.isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category + real distance
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      ),
                      child: Text(
                        b.category,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _distanceLabel,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rating row — live from reviews
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _avgRating.toStringAsFixed(1),
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_reviews.length} ${_reviews.length == 1 ? "review" : "reviews"})',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceLG),

                // Action Buttons
                Row(
                  children: [
                    if (b.phone != null && b.phone!.isNotEmpty) ...[
                      Expanded(
                        child: _ActionButton(
                          label: 'Call',
                          icon: Icons.phone_rounded,
                          onTap: () => _launchPhone(b.phone!),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _ActionButton(
                        label: 'Directions',
                        icon: Icons.directions_rounded,
                        onTap: () => _launchMapsDirections(b.latitude, b.longitude),
                        isPrimary: false,
                      ),
                    ),
                    if (b.website != null && b.website!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Website',
                          icon: Icons.language_rounded,
                          onTap: () => _launchUrl(b.website!),
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppConstants.spaceXL),

                // About Section
                _SectionHeader(title: 'About'),
                const SizedBox(height: AppConstants.spaceSM),
                Text(b.description, style: AppTextStyles.bodyMedium.copyWith(height: 1.65)),
                const SizedBox(height: AppConstants.spaceXL),

                // Shop Photos Section
                if (b.images.isNotEmpty) ...[
                  const _SectionHeader(title: 'Shop Photos'),
                  const SizedBox(height: AppConstants.spaceSM),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: b.images.length,
                      itemBuilder: (ctx, i) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _PhotoViewerScreen(urls: b.images, initialIndex: i),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: HoodlyImage(
                                imageUrl: b.images[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceXL),
                ],

                // Location Section
                _SectionHeader(title: 'Location'),
                const SizedBox(height: AppConstants.spaceSM),
                GestureDetector(
                  onTap: () => _copyToClipboard(b.address),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            b.address,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.copy_rounded, color: AppColors.textHint, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMD),

                // Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(b.latitude, b.longitude),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.hoodly.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(b.latitude, b.longitude),
                              width: 50,
                              height: 50,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ],
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),

                // Contact Section
                if (b.phone != null || b.website != null) ...[
                  _SectionHeader(title: 'Contact'),
                  const SizedBox(height: AppConstants.spaceSM),
                  if (b.phone != null && b.phone!.isNotEmpty)
                    _ContactTile(
                      icon: Icons.phone_rounded,
                      label: b.phone!,
                      onTap: () => _launchPhone(b.phone!),
                    ),
                  if (b.website != null && b.website!.isNotEmpty)
                    _ContactTile(
                      icon: Icons.language_rounded,
                      label: b.website!,
                      onTap: () => _launchUrl(b.website!),
                    ),
                  const SizedBox(height: AppConstants.spaceXL),
                ],

                // Reviews Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(title: 'Reviews'),
                    TextButton.icon(
                      onPressed: _showWriteReviewSheet,
                      icon: const Icon(Icons.rate_review_rounded, size: 16),
                      label: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceSM),
                _buildReviewsSection(),

                const SizedBox(height: AppConstants.space4XL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    if (_reviewsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 2,
        )),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.star_outline_rounded, size: 40, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'No reviews yet',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to share your experience!',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _reviews.map((review) => _ReviewCard(
        review: review,
        onDelete: _supabaseUserId == review.userId ? () => _deleteReview(review.id) : null,
      )).toList(),
    );
  }

  String? get _supabaseUserId {
    try {
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await ReviewService.instance.deleteReview(reviewId);
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete review. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPlaceholderHero(BusinessModel b) {
    final hash = b.name.hashCode;
    final gradients = [
      [const Color(0xFF6C3EF4), const Color(0xFF8B65F7)],
      [const Color(0xFFFFB800), const Color(0xFFFFD04D)],
      [const Color(0xFF3498DB), const Color(0xFF5DADE2)],
      [const Color(0xFF2ECC71), const Color(0xFF58D68D)],
      [const Color(0xFFE74C3C), const Color(0xFFEC7063)],
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
        child: Text(
          b.name.isNotEmpty ? b.name[0].toUpperCase() : 'H',
          style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─── Write Review Bottom Sheet ────────────────────────────────────────────────

class _WriteReviewSheet extends StatefulWidget {
  final String businessId;
  final VoidCallback onReviewSubmitted;

  const _WriteReviewSheet({required this.businessId, required this.onReviewSubmitted});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _selectedRating = 0;
  final _textController = TextEditingController();
  final List<String> _photoPaths = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos per review')),
      );
      return;
    }
    if (!mounted) return;

    try {
      final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) setState(() => _photoPaths.add(img.path));
    } catch (e) {
      debugPrint('_WriteReviewSheet._pickPhoto error: $e');
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating (1–5).'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ReviewService.instance.submitReview(
        businessId: widget.businessId,
        rating: _selectedRating,
        reviewText: _textController.text.trim(),
        localPhotoPaths: _photoPaths,
      );
      widget.onReviewSubmitted();
    } catch (e) {
      debugPrint('_WriteReviewSheet._submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXXL)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppConstants.screenPaddingH, 24,
        AppConstants.screenPaddingH,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Write a Review', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Star Rating
            Text('Your Rating', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.secondary,
                      size: 38,
                    ),
                  ),
                );
              }),
            ),
            if (_selectedRating > 0) ...[
              const SizedBox(height: 4),
              Text(
                ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_selectedRating],
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),

            // Review text
            Text('Your Review', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: AppTextStyles.bodyMedium,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                fillColor: AppColors.surface,
                filled: true,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            Text('Add Photos (optional)', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._photoPaths.asMap().entries.map((entry) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 76, height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            image: DecorationImage(
                              image: FileImage(io.File(entry.value)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _photoPaths.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_photoPaths.length < 5)
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                            SizedBox(height: 4),
                            Text('Add Photo', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLG)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onDelete;

  const _ReviewCard({required this.review, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + time + delete
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    Text(review.timeAgo, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  ],
                ),
              ),
              // Star rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 14),
                    const SizedBox(width: 3),
                    Text('${review.rating}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Stars row
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.secondary,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 8),

          // Review text
          if (review.reviewText.isNotEmpty)
            Text(review.reviewText, style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary)),

          // Photos
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                itemBuilder: (ctx, i) {
                  return GestureDetector(
                    onTap: () => _showPhotoViewer(context, review.photoUrls, i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                        image: DecorationImage(
                          image: NetworkImage(review.photoUrls[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, List<String> urls, int startIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewerScreen(urls: urls, initialIndex: startIndex)));
  }
}

// ─── Photo Viewer Screen ──────────────────────────────────────────────────────

class _PhotoViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewerScreen({required this.urls, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (ctx, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(widget.urls[i], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}



// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPaddingH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 56),
              const SizedBox(height: AppConstants.spaceLG),
              Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppConstants.spaceLG),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [AppColors.primary, Color(0xFF4F2ED9)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isPrimary ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: isPrimary ? null : Border.all(color: AppColors.border),
          boxShadow: isPrimary
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isPrimary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      contentPadding: EdgeInsets.zero,
    );
  }
}
