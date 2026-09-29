import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../models/community_post_model.dart';
import '../../services/community_service.dart';

/// Screen 5: Post Detail matching mockup in project specifications.
class CommunityPostDetailScreen extends StatefulWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  CommunityPostModel? _post;
  bool _isLoading = true;
  String? _error;

  static const Color _tealColor = Color(0xFF0D9488);
  static const Color _offeringColor = Color(0xFF10B981);
  static const Color _requestingColor = Color(0xFFD97706);
  static const Color _offeringBg = Color(0xFFE8F8F3);
  static const Color _requestingBg = Color(0xFFFEF3C7);

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  bool get _isAuthor =>
      _post != null &&
      (_post!.authorId == _currentUserId ||
       _post!.authorId == 'current-user' ||
       _post!.authorId.startsWith('local-'));

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await CommunityService.instance.getPostById(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Post not found.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  Future<void> _sendMail(String email, String title) async {
    if (email.trim().isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: email.trim(),
      query: 'subject=${Uri.encodeComponent('Regarding: $title')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open mail client.')),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePrimaryContact() {
    if (_post == null) return;
    final phone = _post!.contactPhone;
    final email = _post!.contactEmail;

    if (phone.isNotEmpty && email.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact ${_post!.authorName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: _tealColor),
                  title: const Text('Call / Phone'),
                  subtitle: Text(phone),
                  onTap: () {
                    Navigator.pop(ctx);
                    _makeCall(phone);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_rounded, color: _tealColor),
                  title: const Text('Send Email'),
                  subtitle: Text(email),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMail(email, _post!.title);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else if (phone.isNotEmpty) {
      _makeCall(phone);
    } else if (email.isNotEmpty) {
      _sendMail(email, _post!.title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact information provided.')),
      );
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this community post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await CommunityService.instance.deletePost(_post!.id);
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Post Detail',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_isAuthor && _post != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
              onPressed: () async {
                await context.push('/community/edit/${_post!.id}');
                _loadPost();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              onPressed: _deletePost,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_tealColor),
              ),
            )
          : _error != null || _post == null
              ? Center(
                  child: Text(
                    _error ?? 'Post not found.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final post = _post!;
    final isOffering = post.isOffering;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Author profile section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE6F4F1),
                      backgroundImage: post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty
                          ? NetworkImage(post.authorAvatarUrl!)
                          : null,
                      child: post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 26,
                              color: _tealColor,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.authorMemberSince,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 2. Tag & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOffering ? _offeringBg : _requestingBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOffering ? 'OFFERING' : 'REQUESTING',
                        style: TextStyle(
                          color: isOffering ? _offeringColor : _requestingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Description
                Text(
                  post.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF4B5563),
                  ),
                ),

                const SizedBox(height: 22),

                // 5. Fee / Payment Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.feePayment.isNotEmpty
                        ? (post.feePayment.toLowerCase().contains('/')
                            ? post.feePayment.replaceAll('/', ' / ')
                            : post.feePayment)
                        : 'Free',
                    style: const TextStyle(
                      color: _tealColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 6. Contact Details Section
                const Text(
                  'Contact Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Email row
                if (post.contactMethod != 'phone' && post.contactEmail.isNotEmpty)
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    text: post.contactEmail,
                    onCopy: () => _copyToClipboard(post.contactEmail, 'Email'),
                  ),

                if (post.contactMethod != 'phone' && post.contactEmail.isNotEmpty &&
                    post.contactMethod != 'email' && post.contactPhone.isNotEmpty)
                  const SizedBox(height: 10),

                // Phone row
                if (post.contactMethod != 'email' && post.contactPhone.isNotEmpty)
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    text: post.contactPhone,
                    onCopy: () => _copyToClipboard(post.contactPhone, 'Phone number'),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom CTA Button: "Contact [AuthorFirstName]"
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handlePrimaryContact,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                'Contact ${post.authorName.split(' ').first}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String text,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
