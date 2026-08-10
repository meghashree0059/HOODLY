import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/business_service.dart';
import '../../models/business_model.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_business_screen.dart';

class MyBusinessesScreen extends StatefulWidget {
  const MyBusinessesScreen({super.key});

  @override
  State<MyBusinessesScreen> createState() => _MyBusinessesScreenState();
}

class _MyBusinessesScreenState extends State<MyBusinessesScreen> {
  List<BusinessModel> _businesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final list = await BusinessService.instance.getOwnerBusinesses();
      setState(() {
        _businesses = list;
      });
    } catch (e) {
      debugPrint('Error loading owner businesses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBusinessStatus(BusinessModel business) async {
    final targetState = !business.isOpen;
    setState(() => _isLoading = true);
    try {
      await BusinessService.instance.setBusinessActiveState(business.id, targetState);
      await _loadBusinesses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(targetState ? 'Listing activated' : 'Listing deactivated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update listing: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HoodlyAppBar(title: 'My Listings', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Push Add Business screen as a standalone page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: AddBusinessScreen(
                  onBackToHome: () {
                    Navigator.pop(context);
                    _loadBusinesses();
                  },
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _businesses.isEmpty
              ? _buildEmptyState()
              : _buildListState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: AppConstants.spaceLG),
            Text(
              'No Listings Yet',
              style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppConstants.spaceSM),
            Text(
              'You have not registered any business listing. Tap the button below to add your first neighborhood listing!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListState() {
    return RefreshIndicator(
      onRefresh: _loadBusinesses,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH,
          vertical: AppConstants.spaceMD,
        ),
        itemCount: _businesses.length,
        itemBuilder: (context, index) {
          final item = _businesses[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppConstants.spaceMD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceMD),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Thumbnail
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(color: AppColors.border),
                          image: item.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(item.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.surfaceVariant,
                        ),
                        child: item.imageUrl == null
                            ? const Icon(Icons.storefront_rounded, color: AppColors.textHint)
                            : null,
                      ),
                      const SizedBox(width: AppConstants.spaceMD),
                      // Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.isOpen ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.isOpen ? 'Active' : 'Inactive',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: item.isOpen ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Edit Button
                      TextButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.editBusiness.replaceAll(':id', item.id)).then((_) => _loadBusinesses());
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      // Toggle active button
                      TextButton.icon(
                        onPressed: () => _toggleBusinessStatus(item),
                        icon: Icon(
                          item.isOpen ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                          color: item.isOpen ? AppColors.error : AppColors.success,
                        ),
                        label: Text(
                          item.isOpen ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: item.isOpen ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
