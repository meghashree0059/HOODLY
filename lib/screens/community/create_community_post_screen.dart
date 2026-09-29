import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/community_service.dart';
import '../../services/location_service.dart';

/// Screen: Create Post matching the provided UI mockup.
class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  State<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController(text: '₹ 500/hr');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController(text: 'Current Location');

  String _postType = 'offering'; // 'offering' | 'requesting'
  String _selectedCategory = 'General';
  List<Map<String, dynamic>> _categories = [];
  bool _isFree = false;
  String _contactMethod = 'both'; // 'both' | 'phone' | 'email'

  final List<XFile> _selectedPhotos = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  Position? _userPosition;

  static const Color _tealColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _initUserData();
    _fetchCategories();
    _fetchLocation();
  }

  void _initUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      final phone = user.userMetadata?['phone'] as String? ?? user.phone ?? '';
      _phoneController.text = phone;
    }
  }

  Future<void> _fetchCategories() async {
    final cats = await CommunityService.instance.getCategories();
    if (mounted && cats.isNotEmpty) {
      setState(() {
        _categories = cats;
        _selectedCategory = cats.first['name'] as String? ?? 'General';
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null && mounted) {
        final loc = await LocationService.instance.getLocalityName(pos.latitude, pos.longitude);
        setState(() {
          _userPosition = pos;
          _addressController.text = loc;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingLocation = false);
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
      return;
    }

    final picker = ImagePicker();
    final remaining = 3 - _selectedPhotos.length;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _selectedPhotos.addAll(picked.take(remaining));
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _feeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a community post.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fee = _isFree ? 'Free' : _feeController.text.trim();

      // Upload photos if any
      final List<String> uploadedUrls = [];
      for (final img in _selectedPhotos) {
        try {
          final url = await CommunityService.instance.uploadPhoto(File(img.path));
          uploadedUrls.add(url);
        } catch (e) {
          debugPrint('Photo upload notice: $e');
        }
      }

      await CommunityService.instance.createPost(
        title: _titleController.text,
        description: _descController.text,
        category: _selectedCategory,
        postType: _postType,
        feePayment: fee.isEmpty ? 'Free' : fee,
        contactMethod: _contactMethod,
        contactPhone: _phoneController.text,
        contactEmail: _emailController.text,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : 'Nearby',
        latitude: _userPosition?.latitude ?? 0.0,
        longitude: _userPosition?.longitude ?? 0.0,
        photoUrls: uploadedUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_postType == 'offering'
                ? 'Service posted successfully!'
                : 'Request posted successfully!'),
            backgroundColor: _tealColor,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffering = _postType == 'offering';

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
          'Create Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Post Type Segmented Control
              _buildLabel('Post Type'),
              const SizedBox(height: 8),
              Container(
                height: 46,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _postType = 'offering'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: isOffering ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isOffering
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Offering',
                            style: TextStyle(
                              color: isOffering ? _tealColor : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _postType = 'requesting'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: !isOffering ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !isOffering
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Requesting',
                            style: TextStyle(
                              color: !isOffering ? const Color(0xFFD97706) : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Service / Request Title
              _buildLabel(isOffering ? 'Service Title' : 'Request Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  isOffering ? 'Math Tutoring for High School' : 'Urgent: Need Plumber for Leak',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 20),

              // 3. Category Dropdown
              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categories.any((c) => c['name'] == _selectedCategory)
                    ? _selectedCategory
                    : (_categories.isNotEmpty ? _categories.first['name'] as String : 'General'),
                items: (_categories.isNotEmpty ? _categories : [{'name': 'General'}])
                    .map((c) {
                  final name = c['name'] as String? ?? 'General';
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: _inputDecoration('Select category'),
              ),

              const SizedBox(height: 20),

              // 4. Description
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  'Helping students prepare for board exams. 5+ years of experience in simplifying complex calculus and algebra. Free doubt solving sessions on weekends.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a description' : null,
              ),

              const SizedBox(height: 20),

              // 5. Location / Address
              _buildLabel('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: _inputDecoration('Your neighbourhood or locality').copyWith(
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 20),
                  suffixIcon: IconButton(
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_tealColor)),
                          )
                        : const Icon(Icons.my_location_rounded, color: _tealColor, size: 20),
                    onPressed: _fetchLocation,
                    tooltip: 'Use current GPS location',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 6. Optional Photos
              _buildLabel('Photos (Optional, up to 3)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ..._selectedPhotos.map((photo) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(photo.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedPhotos.remove(photo)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                    if (_selectedPhotos.length < 3)
                      GestureDetector(
                        onTap: _pickPhotos,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint, size: 24),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 7. Fee/Payment + Mark as Free Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Fee/Payment'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mark as Free',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch.adaptive(
                          value: _isFree,
                          activeTrackColor: _tealColor,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _isFree = val;
                              if (_isFree) {
                                _feeController.text = 'Free';
                              } else {
                                _feeController.text = '₹ 500/hr';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feeController,
                enabled: !_isFree,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _isFree ? _tealColor : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration('₹ 500/hr'),
              ),

              const SizedBox(height: 20),

              // 8. Contact Method
              _buildLabel('Contact Method'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRadioOption('Both', 'both'),
                  _buildRadioOption('Phone only', 'phone'),
                  _buildRadioOption('Email only', 'email'),
                ],
              ),
              const SizedBox(height: 12),

              if (_contactMethod != 'phone') ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('arjun.sharma@email.com').copyWith(
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textHint),
                  ),
                  validator: (v) {
                    if (_contactMethod != 'phone' && (v == null || v.trim().isEmpty)) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (_contactMethod != 'email') ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('+91 98765 43210').copyWith(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textHint),
                  ),
                  validator: (v) {
                    if (_contactMethod != 'email' && (v == null || v.trim().isEmpty)) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // 9. Post Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isOffering ? 'Post Service' : 'Post Request',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _contactMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _contactMethod = value),
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _tealColor : const Color(0xFFD1D5DB),
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _tealColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
