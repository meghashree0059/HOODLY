import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/business_model.dart';
import '../../services/business_service.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadBusiness();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    if (widget.businessId == null || widget.businessId!.isEmpty) {
      setState(() {
        _error = 'Invalid business ID.';
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final business = await BusinessService.instance.getBusinessById(widget.businessId!);
      setState(() {
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load business details. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final raw = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
    // Open in Google Maps
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    final allImages = b.images.isNotEmpty ? b.images : (b.imageUrl != null ? [b.imageUrl!] : <String>[]);
    final hasImages = allImages.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Hero Image Carousel with back button overlay
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
                // Image carousel / placeholder
                hasImages
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: allImages.length,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemBuilder: (context, index) {
                          return Image.network(
                            allImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _buildPlaceholderHero(b),
                          );
                        },
                      )
                    : _buildPlaceholderHero(b),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Image count dot indicators
                if (allImages.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0, right: 0,
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
                        color: b.isOpen
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
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

                // Category chip + distance
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
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(b.distanceLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                // Rating row
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      b.rating.toStringAsFixed(1),
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${b.reviewCount} reviews)',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceLG),

                // Action Buttons Row
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

                // Address Section
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

                // OpenStreetMap section
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

                // Contact Details Section
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

                // Tags if present
                if (b.tags.isNotEmpty) ...[
                  _SectionHeader(title: 'Tags'),
                  const SizedBox(height: AppConstants.spaceSM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: b.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.spaceXL),
                ],

                const SizedBox(height: AppConstants.space4XL),
              ],
            ),
          ),
        ),
      ],
    );
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w800,
          ),
        ),
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
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
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
    );
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
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4F2ED9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
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
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isPrimary ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
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
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      contentPadding: EdgeInsets.zero,
    );
  }
}
