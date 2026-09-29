/// Community post model for the Hoodly app.
class CommunityPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorMemberSince;
  final String title;
  final String description;
  final String? categoryId;
  final String category;
  final String postType; // 'offering' | 'requesting'
  final String feePayment; // e.g. "₹500/hr", "₹250/hr", "Free"
  final String contactMethod; // 'both' | 'phone' | 'email'
  final String contactPhone;
  final String contactEmail;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
  final String status; // 'active' | 'closed' | 'expired' | 'draft'
  final DateTime createdAt;
  final DateTime updatedAt;
  final double distanceKm;

  const CommunityPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorMemberSince = 'Member • Local Neighbor',
    required this.title,
    required this.description,
    this.categoryId,
    required this.category,
    required this.postType,
    this.feePayment = 'Free',
    this.contactMethod = 'both',
    this.contactPhone = '',
    this.contactEmail = '',
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoUrls = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm = 0.0,
  });

  bool get isOffering => postType.toLowerCase() == 'offering';
  bool get isRequesting => postType.toLowerCase() == 'requesting';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isDraft => status.toLowerCase() == 'draft';

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    // Resolve author details from flat fields or joined profiles table
    String authorName = json['author_name'] as String? ?? '';
    String? authorAvatarUrl = json['author_avatar_url'] as String?;
    String? phone = json['contact_phone'] as String? ?? '';
    String? email = json['contact_email'] as String? ?? '';

    if (json['profiles'] != null && json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      final profileName = profile['name'] as String?;
      if (profileName != null && profileName.trim().isNotEmpty) {
        authorName = profileName.trim();
      }
      final profileAvatar = profile['avatar_url'] as String?;
      if (profileAvatar != null && profileAvatar.trim().isNotEmpty) {
        authorAvatarUrl = profileAvatar.trim();
      }
      if (phone.isEmpty) phone = profile['phone'] as String? ?? '';
      if (email.isEmpty) email = profile['email'] as String? ?? '';
    }

    if (authorName.isEmpty) {
      authorName = 'Local Neighbor';
    }

    // Resolve category name from joined categories table or flat field
    String categoryName = json['category'] as String? ?? 'General';
    String? categoryId;
    if (json['community_service_categories'] != null &&
        json['community_service_categories'] is Map) {
      final cat = json['community_service_categories'] as Map<String, dynamic>;
      categoryName = cat['name'] as String? ?? categoryName;
      categoryId = cat['id'] as String?;
    } else if (json['category_id'] != null) {
      categoryId = json['category_id'] as String?;
    }

    // Resolve photo URLs
    List<String> photoUrls = [];
    final rawPhotos = json['photo_urls'];
    if (rawPhotos != null && rawPhotos is List) {
      photoUrls = rawPhotos
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final fee = json['fee_payment'] as String? ??
        json['fee'] as String? ??
        'Free';

    final contactM = json['contact_method'] as String? ?? 'both';

    return CommunityPostModel(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorMemberSince: json['author_member_since'] as String? ??
          'Member since Nov 2023 • Local Neighbor',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: categoryId,
      category: categoryName,
      postType: json['post_type'] as String? ?? 'offering',
      feePayment: fee,
      contactMethod: contactM,
      contactPhone: phone,
      contactEmail: email,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrls: photoUrls,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'author_avatar_url': authorAvatarUrl,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'category': category,
        'post_type': postType,
        'fee_payment': feePayment,
        'contact_method': contactMethod,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'photo_urls': photoUrls,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CommunityPostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? authorMemberSince,
    String? title,
    String? description,
    String? categoryId,
    String? category,
    String? postType,
    String? feePayment,
    String? contactMethod,
    String? contactPhone,
    String? contactEmail,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceKm,
  }) =>
      CommunityPostModel(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
        authorMemberSince: authorMemberSince ?? this.authorMemberSince,
        title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        category: category ?? this.category,
        postType: postType ?? this.postType,
        feePayment: feePayment ?? this.feePayment,
        contactMethod: contactMethod ?? this.contactMethod,
        contactPhone: contactPhone ?? this.contactPhone,
        contactEmail: contactEmail ?? this.contactEmail,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photoUrls: photoUrls ?? this.photoUrls,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  String get distanceLabel {
    if (distanceKm <= 0.0) return 'Nearby';
    if (distanceKm < 0.1) return 'Nearby';
    if (distanceKm < 1.0) return '${(distanceKm * 1000).round()}m away';
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  String get postTypeLabel =>
      isOffering ? 'OFFERING' : 'REQUESTING';

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 30) {
      return 'Posted on ${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (diff.inDays >= 1) {
      return 'Posted ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else if (diff.inHours >= 1) {
      return 'Posted ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inMinutes >= 1) {
      return 'Posted ${diff.inMinutes} mins ago';
    } else {
      return 'Posted just now';
    }
  }

  @override
  String toString() => 'CommunityPostModel(id: $id, title: $title)';
}
