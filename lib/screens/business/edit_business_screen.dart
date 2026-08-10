import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/business_service.dart';
import '../../services/location_service.dart';


class EditBusinessScreen extends StatefulWidget {
  final String businessId;

  const EditBusinessScreen({super.key, required this.businessId});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _selectedCategory;
  bool _isLocating = false;
  bool _isLoading = true;
  bool _isSaving = false;

  double? _latitude;
  double? _longitude;

  // Images: existing (URLs) and new (local paths)
  List<String> _existingImageUrls = [];
  final List<String> _newLocalImagePaths = [];
  final ImagePicker _picker = ImagePicker();

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await BusinessService.instance.getCategories();
      final business = await BusinessService.instance.getBusinessById(widget.businessId);

      _nameController.text = business.name;
      _descriptionController.text = business.description;
      _addressController.text = business.address;
      _phoneController.text = business.phone ?? '';
      _websiteController.text = business.website ?? '';
      _latitude = business.latitude;
      _longitude = business.longitude;

      setState(() {
        _categories = categories.map((c) => c['name'] as String).toList();
        if (_categories.isEmpty) {
          _categories = ['Food', 'Restaurant', 'Café', 'Bakery', 'Shopping', 'Services', 'Home Business', 'Beauty', 'Electronics', 'Hangout', 'Other'];
        }
        _selectedCategory = _categories.contains(business.category) ? business.category : _categories.first;
        _existingImageUrls = List.from(business.images);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading business for edit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load listing: $e'), backgroundColor: AppColors.error),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onUseCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        final address = await LocationService.instance.getLocalityName(position.latitude, position.longitude);
        setState(() {
          _addressController.text = address;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch location. Ensure GPS is enabled.')),
        );
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _onAddPhoto() async {
    if (_existingImageUrls.length + _newLocalImagePaths.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed')),
      );
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() => _newLocalImagePaths.add(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _onRemoveExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _onRemoveNewImage(int index) {
    setState(() => _newLocalImagePaths.removeAt(index));
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await BusinessService.instance.updateBusiness(
        businessId: widget.businessId,
        name: _nameController.text.trim(),
        categoryName: _selectedCategory ?? 'Other',
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude ?? 12.9784,
        longitude: _longitude ?? 80.2212,
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        localImagePathsToUpload: _newLocalImagePaths,
        existingImageUrlsToKeep: _existingImageUrls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString().replaceAll('Exception:', '').trim()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HoodlyAppBar(title: 'Edit Listing', showBack: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.screenPaddingH),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photos
                      Text('Photos', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      _buildPhotoGrid(),
                      const SizedBox(height: AppConstants.spaceLG),

                      // Business Name
                      HoodlyTextField(
                        controller: _nameController,
                        label: 'Business Name',
                        hint: 'Enter business name',
                        prefixIcon: Icons.storefront_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),

                      // Category
                      Text('Category', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category_rounded, color: AppColors.textHint),
                          fillColor: AppColors.surface,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        style: AppTextStyles.bodyMedium,
                        items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) => v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),

                      // Description
                      HoodlyTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe your business...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),

                      // Phone
                      HoodlyTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Business contact number',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),

                      // Website
                      HoodlyTextField(
                        controller: _websiteController,
                        label: 'Website / Social Link (Optional)',
                        hint: 'www.yourbusiness.com',
                        prefixIcon: Icons.language_rounded,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),

                      // Address
                      HoodlyTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Business address or location',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),

                      // Use location button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isLocating ? null : _onUseCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                              : const Icon(Icons.my_location_rounded, size: 16),
                          label: Text(
                            _isLocating ? 'Fetching...' : 'Use Current Location',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spaceXXL),
                      PrimaryButton(
                        label: 'Save Changes',
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _onSave,
                      ),
                      const SizedBox(height: AppConstants.spaceLG),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoGrid() {
    final totalImages = _existingImageUrls.length + _newLocalImagePaths.length;
    return Row(
      children: [
        // Existing images
        ..._existingImageUrls.asMap().entries.map((entry) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppColors.border),
                  image: DecorationImage(image: NetworkImage(entry.value), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: -6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _onRemoveExistingImage(entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        }),
        // New local images
        ..._newLocalImagePaths.asMap().entries.map((entry) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppColors.border),
                  image: DecorationImage(image: FileImage(io.File(entry.value)), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: -6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _onRemoveNewImage(entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          );
        }),
        // Add photo button
        if (totalImages < 3)
          GestureDetector(
            onTap: _onAddPhoto,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 24),
                  SizedBox(height: 4),
                  Text('Add Photo', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
