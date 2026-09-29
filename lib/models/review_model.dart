/// Review data model for Hoodly.
class ReviewModel {
  final String id;
  final String businessId;
  final String userId;
  final String reviewerName;
  final int rating;          // 1–5
  final String reviewText;
  final List<String> photoUrls;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    this.photoUrls = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Reviewer name from joined profiles table or flat field
    String name = 'Anonymous';
    if (json['profiles'] != null && json['profiles'] is Map) {
      name = (json['profiles'] as Map)['name'] as String? ?? 'Anonymous';
    } else if (json['reviewer_name'] != null) {
      name = json['reviewer_name'] as String;
    }

    // Photos from joined review_photos table
    List<String> photos = [];
    if (json['review_photos'] != null && json['review_photos'] is List) {
      photos = (json['review_photos'] as List)
          .map((p) {
            if (p is Map) return p['image_url'] as String? ?? '';
            return p.toString();
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return ReviewModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      reviewerName: name,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewText: json['review_text'] as String? ?? '',
      photoUrls: photos,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'user_id': userId,
        'reviewer_name': reviewerName,
        'rating': rating,
        'review_text': reviewText,
        'photo_urls': photoUrls,
        'created_at': createdAt.toIso8601String(),
      };

  /// Human-readable elapsed time string for display.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
