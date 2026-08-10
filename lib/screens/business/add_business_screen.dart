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

class AddBusinessScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  
  const AddBusinessScreen({super.key, this.onBackToHome});

  @override
  State<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends State<AddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Form Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLocating = false;
  bool _isSubmitting = false;
  
  double? _latitude;
  double? _longitude;
  
  // Real uploaded photos list of local file paths
  final List<String> _uploadedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  
  // Categories from Database
  List<String> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await BusinessService.instance.getCategories();
      setState(() {
        _categories = list.map((item) => item['name'] as String).toList();
        if (_categories.isEmpty) {
          _categories = ['Food', 'Restaurant', 'Café', 'Bakery', 'Shopping', 'Services', 'Home Business', 'Beauty', 'Electronics', 'Hangout', 'Other'];
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _categories = ['Food', 'Restaurant', 'Café', 'Bakery', 'Shopping', 'Services', 'Home Business', 'Beauty', 'Electronics', 'Hangout', 'Other'];
        _isLoadingCategories = false;
      });
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
          const SnackBar(content: Text('Could not fetch location. Ensure GPS is enabled and permissions are granted.')),
        );
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _onUploadPhoto() async {
    if (_uploadedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _uploadedPhotos.add(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _onRemovePhoto(int index) {
    setState(() {
      _uploadedPhotos.removeAt(index);
    });
  }

  void _onSubmitListing() async {
    setState(() => _isSubmitting = true);
    try {
      await BusinessService.instance.createBusiness(
        name: _nameController.text.trim(),
        categoryName: _selectedCategory ?? 'Other',
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude ?? 12.9784, // Default to Chennai coords if gps not resolved
        longitude: _longitude ?? 80.2212,
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        localImagePaths: _uploadedPhotos,
      );
      
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onNext() {
    if (_currentStep == 1) {
      if (_formKey.currentState?.validate() ?? false) {
        if (_uploadedPhotos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload at least one photo')),
          );
          return;
        }
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
    } else {
      _onSubmitListing();
    }
  }

  void _onPrevious() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Business Submitted!',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your business has been successfully listed on Hoodly. Local community members can now discover your services!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss Dialog
                    if (widget.onBackToHome != null) {
                      widget.onBackToHome!();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HoodlyAppBar(
        title: 'Add Business',
        showBack: _currentStep > 1,
        onBackPressed: _onPrevious,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.screenPaddingH),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 32 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Step Indicator
                        _buildStepIndicator(),
                        const SizedBox(height: AppConstants.spaceXL),

                        // 2. Current Step Content
                        AnimatedSwitcher(
                          duration: AppConstants.animNormal,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildStepContent(),
                        ),

                        const SizedBox(height: AppConstants.spaceXXL),

                        // 3. Navigation Buttons
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getStepTitle(),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Step $_currentStep of $_totalSteps',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_totalSteps, (index) {
            final stepIndex = index + 1;
            final isCompleted = stepIndex < _currentStep;
            final isActive = stepIndex == _currentStep;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == _totalSteps - 1 ? 0 : 8,
                ),
                height: 6,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : isActive
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.border,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Business Details';
      case 2:
        return 'Contact Info';
      case 3:
        return 'Verification & Review';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1BasicInfo();
      case 2:
        return _buildStep2ContactInfo();
      case 3:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Photos Section
        Text(
          'Upload Photos',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPhotoUploadGrid(),
        const SizedBox(height: AppConstants.spaceLG),

        // Business Name
        HoodlyTextField(
          controller: _nameController,
          label: 'Business Name',
          hint: 'Enter your business name',
          prefixIcon: Icons.storefront_rounded,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Business name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spaceMD),

        // Category Dropdown
        Text(
          'Category',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCategories
            ? const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: Text(
                  'Select business category',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                ),
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
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
        const SizedBox(height: AppConstants.spaceMD),

        // Description
        HoodlyTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Tell the community about your products or services...',
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
        const SizedBox(height: AppConstants.spaceMD),

        // Address
        HoodlyTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter store address or location',
          prefixIcon: Icons.location_on_outlined,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Use Current Location Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isLocating ? null : _onUseCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(
              _isLocating ? 'Fetching Location...' : 'Use Current Location',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadGrid() {
    return Row(
      children: [
        // Uploaded pictures list
        ...List.generate(_uploadedPhotos.length, (index) {
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
                  image: DecorationImage(
                    image: FileImage(io.File(_uploadedPhotos[index])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _onRemovePhoto(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
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
        }),
        // Add Button dashed border box
        if (_uploadedPhotos.length < 3)
          GestureDetector(
            onTap: _onUploadPhoto,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep2ContactInfo() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HoodlyTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your business contact number',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
        ),
        const SizedBox(height: AppConstants.spaceMD),
        HoodlyTextField(
          controller: _websiteController,
          label: 'Website / Social Link (Optional)',
          hint: 'e.g. www.mybusiness.com or instagram.com/brand',
          keyboardType: TextInputType.url,
          prefixIcon: Icons.language_rounded,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppConstants.spaceMD),
        Text(
          'Operating Hours',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Hours Set',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Mon - Sat (9:00 AM - 8:00 PM)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Review() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Business Listing Details',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceMD),
        
        // Photos Row
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _uploadedPhotos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  image: DecorationImage(
                    image: FileImage(io.File(_uploadedPhotos[index])),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.spaceMD),

        // Info List
        _buildReviewRow('Business Name', _nameController.text),
        _buildReviewRow('Category', _selectedCategory ?? ''),
        _buildReviewRow('Description', _descriptionController.text),
        _buildReviewRow('Address', _addressController.text),
        _buildReviewRow('Phone', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided'),
        _buildReviewRow('Website', _websiteController.text.isNotEmpty ? _websiteController.text : 'Not provided'),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 1) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _onPrevious,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: PrimaryButton(
            label: _currentStep == _totalSteps ? 'Submit Listing' : 'Next',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _onNext,
          ),
        ),
      ],
    );
  }
}
