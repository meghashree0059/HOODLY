/// Business listing model for the Hoodly app.
class BusinessModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final List<String> images;
  final List<String> tags;
  final bool isOpen;
  final String? openHours;
  final String? phone;
  final String? website;
  final double distanceKm;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl,
    this.images = const [],
    this.tags = const [],
    this.isOpen = true,
    this.openHours,
    this.phone,
    this.website,
    this.distanceKm = 0.0,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    // Resolve category name (handles join query and flat mock data)
    String categoryName = 'Other';
    if (json['categories'] != null) {
      if (json['categories'] is Map) {
        categoryName = json['categories']['name'] as String? ?? 'Other';
      } else {
        categoryName = json['categories'].toString();
      }
    } else if (json['category'] != null) {
      categoryName = json['category'] as String;
    }

    // Resolve images
    List<String> imagesList = [];
    if (json['business_images'] != null && json['business_images'] is List) {
      imagesList = (json['business_images'] as List)
          .map((img) => (img is Map) ? (img['image_url'] as String? ?? '') : img.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['images'] != null) {
      imagesList = List<String>.from(json['images'] as List);
    }

    // Resolve main image url
    String? mainImageUrl = json['image_url'] as String?;
    if ((mainImageUrl == null || mainImageUrl.isEmpty) && imagesList.isNotEmpty) {
      mainImageUrl = imagesList.first;
    }

    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: categoryName,
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      imageUrl: mainImageUrl,
      images: imagesList,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isOpen: json['is_open'] as bool? ?? true,
      openHours: json['open_hours'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'review_count': reviewCount,
        'image_url': imageUrl,
        'images': images,
        'tags': tags,
        'is_open': isOpen,
        'open_hours': openHours,
        'phone': phone,
        'website': website,
        'distance_km': distanceKm,
      };

  BusinessModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    List<String>? images,
    List<String>? tags,
    bool? isOpen,
    String? openHours,
    String? phone,
    String? website,
    double? distanceKm,
  }) =>
      BusinessModel(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        imageUrl: imageUrl ?? this.imageUrl,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        isOpen: isOpen ?? this.isOpen,
        openHours: openHours ?? this.openHours,
        phone: phone ?? this.phone,
        website: website ?? this.website,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  String get distanceLabel {
    if (distanceKm < 1.0) return '${(distanceKm * 1000).round()}m away';
    return '${distanceKm.toStringAsFixed(1)}km away';
  }

  @override
  String toString() => 'BusinessModel(id: $id, name: $name)';
}
