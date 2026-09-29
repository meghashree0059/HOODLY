import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/community_post_model.dart';
import '../../services/community_service.dart';

/// Screen to edit an existing Community Post.
class EditCommunityPostScreen extends StatefulWidget {
  final String postId;

  const EditCommunityPostScreen({super.key, required this.postId});

  @override
  State<EditCommunityPostScreen> createState() =>
      _EditCommunityPostScreenState();
}

class _EditCommunityPostScreenState extends State<EditCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  CommunityPostModel? _post;
  bool _isLoading = true;
  bool _isSaving = false;

  String _postType = 'offering';
  bool _isFree = false;
  String _contactMethod = 'both';
  String _status = 'active';

  static const Color _tealColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _feeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final post = await CommunityService.instance.getPostById(widget.postId);

    if (mounted) {
      if (post != null) {
        _post = post;
        _titleController.text = post.title;
        _descController.text = post.description;
        _postType = post.postType;
        _status = post.status;
        _feeController.text = post.feePayment;
        _isFree = post.feePayment.toLowerCase() == 'free';
        _contactMethod = post.contactMethod;
        _phoneController.text = post.contactPhone;
        _emailController.text = post.contactEmail;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final fee = _isFree ? 'Free' : _feeController.text.trim();

      await CommunityService.instance.updatePost(
        id: widget.postId,
        title: _titleController.text,
        description: _descController.text,
        postType: _postType,
        feePayment: fee.isEmpty ? 'Free' : fee,
        contactMethod: _contactMethod,
        contactPhone: _phoneController.text,
        contactEmail: _emailController.text,
        status: _status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: _tealColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_tealColor),
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
        body: const Center(child: Text('Post not found.')),
      );
    }

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
          'Edit Post',
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
              // Status Toggle
              _buildLabel('Status'),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Active'),
                    selected: _status == 'active',
                    onSelected: (val) {
                      if (val) setState(() => _status = 'active');
                    },
                    selectedColor: _tealColor,
                    labelStyle: TextStyle(
                      color: _status == 'active' ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Closed'),
                    selected: _status == 'closed',
                    onSelected: (val) {
                      if (val) setState(() => _status = 'closed');
                    },
                    selectedColor: AppColors.textSecondary,
                    labelStyle: TextStyle(
                      color: _status == 'closed' ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Post Type Toggle
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

              // Title
              _buildLabel('Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),

              const SizedBox(height: 20),

              // Description
              _buildLabel('Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),

              const SizedBox(height: 20),

              // Fee / Payment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Fee/Payment'),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFree = !_isFree;
                        if (_isFree) {
                          _feeController.text = 'Free';
                        } else {
                          _feeController.text = '₹ 500/hr';
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _isFree,
                            activeColor: _tealColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _isFree = val ?? false;
                                if (_isFree) {
                                  _feeController.text = 'Free';
                                } else {
                                  _feeController.text = '₹ 500/hr';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Mark as Free',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                decoration: _inputDecoration('e.g. ₹ 500/hr or Free'),
              ),

              const SizedBox(height: 20),

              // Contact Method
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
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('email@example.com').copyWith(
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_contactMethod != 'email') ...[
                TextFormField(
                  controller: _phoneController,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('+91 98765 43210').copyWith(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textHint),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
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
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
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
