import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/business_service.dart';
import '../../services/location_service.dart';

import '../../widgets/hoodly_image.dart';

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
  bool _isGeocoding = false;
  bool _isLoading = true;
  bool _isSaving = false;

  double? _latitude;
  double? _longitude;
  String? _geocodedLabel;
  String _lastGeocodedAddress = '';

  // Profile Image & Gallery Images
  String? _existingProfileUrl;
  String? _newProfilePath;
  List<String> _existingImageUrls = [];
  final List<String> _newLocalImagePaths = [];
  final ImagePicker _picker = ImagePicker();

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _addressController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    final text = _addressController.text.trim();
    if (text != _lastGeocodedAddress) {
      if (_latitude != null || _longitude != null) {
        setState(() {
          _latitude = null;
          _longitude = null;
          _geocodedLabel = null;
        });
      }
    }
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
        _existingProfileUrl = business.imageUrl;
        _existingImageUrls = List.from(business.images);
        _lastGeocodedAddress = business.address;
        _geocodedLabel = '✅ Current saved location: (${business.latitude.toStringAsFixed(4)}, ${business.longitude.toStringAsFixed(4)})';
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
    _addressController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onUploadProfilePhoto() async {
    if (!mounted) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() => _newProfilePath = image.path);
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  void _onRemoveProfilePhoto() {
    setState(() {
      _newProfilePath = null;
      _existingProfileUrl = null;
    });
  }

  void _onUseCurrentLocation() async {
    setState(() { _isLocating = true; _geocodedLabel = null; });
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        final address = await LocationService.instance.getLocalityName(position.latitude, position.longitude);
        _lastGeocodedAddress = address;
        setState(() {
          _addressController.text = address;
          _geocodedLabel = '📍 Set to phone GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
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

  Future<bool> _onGeocodeAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address first.')),
      );
      return false;
    }
    setState(() { _isGeocoding = true; _geocodedLabel = null; });
    try {
      final result = await LocationService.instance.geocodeAddress(address);
      if (result != null) {
        _lastGeocodedAddress = address;
        setState(() {
          _latitude = result.lat;
          _longitude = result.lng;
          _geocodedLabel = '✅ Located on map: (${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)})';
        });
        return true;
      } else {
        setState(() {
          _latitude = null;
          _longitude = null;
          _geocodedLabel = '⚠️ Could not resolve this address. Try refining the text or click "Use GPS".';
        });
        return false;
      }
    } catch (e) {
      setState(() => _geocodedLabel = '⚠️ Geocoding failed. Try again.');
      return false;
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  void _onAddPhoto() async {
    if (_existingImageUrls.length + _newLocalImagePaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 shop photos allowed')),
      );
      return;
    }
    if (!mounted) return;

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

  void _onConfirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          title: Text(
            'Delete Business Listing',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this business listing? This action cannot be undone. Customer reviews will remain protected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                setState(() => _isSaving = true);
                try {
                  await BusinessService.instance.deleteBusiness(widget.businessId);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Business listing deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  nav.pop(true);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_latitude == null || _longitude == null) {
      final success = await _onGeocodeAddress();
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve location for this address. Please click "Resolve Address" or "Use GPS".'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await BusinessService.instance.updateBusiness(
        businessId: widget.businessId,
        name: _nameController.text.trim(),
        categoryName: _selectedCategory ?? 'Other',
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        localImagePathsToUpload: _newLocalImagePaths,
        existingImageUrlsToKeep: _existingImageUrls,
        localProfileImagePath: _newProfilePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      // Show friendly message for network errors
      final String displayMsg;
      if (errStr.contains('SocketException') ||
          errStr.contains('ClientException') ||
          errStr.contains('host lookup') ||
          errStr.contains('errno = 7') ||
          errStr.contains('No address associated')) {
        displayMsg = 'No internet connection. Please check your network and try again.';
      } else {
        displayMsg = 'Update failed: ${errStr.replaceAll('Exception:', '').trim()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMsg), backgroundColor: AppColors.error),
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
                      // Profile Picture
                      Text('Business Profile Picture', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildProfilePhotoPicker(),
                      const SizedBox(height: AppConstants.spaceLG),

                      // Shop Photos
                      Text('Shop & Gallery Photos', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
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

                      // Location action buttons
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: (_isLocating || _isGeocoding) ? null : _onGeocodeAddress,
                            icon: _isGeocoding
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                                : const Icon(Icons.search_rounded, size: 16),
                            label: Text(_isGeocoding ? 'Resolving...' : 'Resolve Address', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          TextButton.icon(
                            onPressed: (_isLocating || _isGeocoding) ? null : _onUseCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                                : const Icon(Icons.my_location_rounded, size: 16),
                            label: Text(_isLocating ? 'Fetching...' : 'Use GPS', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),

                      if (_geocodedLabel != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: Text(
                            _geocodedLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: _geocodedLabel!.startsWith('✅') || _geocodedLabel!.startsWith('📍') ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      // Interactive Map Preview for verification
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          child: SizedBox(
                            height: 160,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(_latitude!, _longitude!),
                                initialZoom: 14.5,
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
                                      point: LatLng(_latitude!, _longitude!),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppConstants.spaceXXL),
                      PrimaryButton(
                        label: 'Save Changes',
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _onSave,
                      ),
                      const SizedBox(height: AppConstants.spaceMD),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _onConfirmDelete,
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                        label: const Text(
                          'Delete Business Listing',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          ),
                        ),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Existing images
        ..._existingImageUrls.asMap().entries.map((entry) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: HoodlyImage(
                    imageUrl: entry.value,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: HoodlyImage(
                    imageUrl: entry.value,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
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
        if (totalImages < 5)
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
                  Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 20),
                  SizedBox(height: 2),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilePhotoPicker() {
    // Determine which image to show (new local pick takes priority over existing)
    final String? displayUrl = _newProfilePath ?? 
        (_existingProfileUrl != null && _existingProfileUrl!.isNotEmpty ? _existingProfileUrl : null);

    if (displayUrl != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _onUploadProfilePhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: HoodlyImage(
                  imageUrl: displayUrl,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: AppColors.textHint, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: _onRemoveProfilePhoto,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _onUploadProfilePhoto,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
            SizedBox(height: 4),
            Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

