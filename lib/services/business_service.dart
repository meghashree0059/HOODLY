import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_model.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'review_service.dart';

class BusinessService {
  static final BusinessService instance = BusinessService._();
  BusinessService._();

  final _supabase = Supabase.instance.client;

  /// Default mock businesses shown on the public discovery feed only.
  /// These are never returned for the owner's "My Businesses" dashboard.
  static final List<BusinessModel> mockBusinesses = [
    BusinessModel(
      id: 'mock-1',
      name: 'easySale',
      category: 'Shopping',
      description: 'Best deals on everyday products, home appliances, clothing and lifestyle accessories.',
      address: '12th Main Road, Anna Nagar, Chennai',
      latitude: 13.0850,
      longitude: 80.2100,
      rating: 4.7,
      reviewCount: 34,
      imageUrl: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=800&q=80',
      images: [
        'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
      ],
      tags: ['Shopping', 'Discounts', 'Supermarket'],
      isOpen: true,
      openHours: '09:00 AM - 09:30 PM',
      phone: '9876543210',
      website: 'https://www.easysale.com',
      distanceKm: 0.8,
    ),
    BusinessModel(
      id: 'mock-2',
      name: 'Ridicula',
      category: 'Hangout',
      description: 'Fun neighborhood hangout cafe with board games, signature mocktails, and gourmet snacks.',
      address: 'Khadder Nawaz Khan Road, Nungambakkam, Chennai',
      latitude: 13.0600,
      longitude: 80.2400,
      rating: 4.8,
      reviewCount: 52,
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
      images: [
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
      ],
      tags: ['Hangout', 'Café', 'Games', 'Snacks'],
      isOpen: true,
      openHours: '10:00 AM - 11:00 PM',
      phone: '9876543211',
      website: 'https://www.ridiculacafe.com',
      distanceKm: 1.4,
    ),
    BusinessModel(
      id: 'mock-3',
      name: 'Selvan bakery',
      category: 'Bakery',
      description: 'Freshly baked hot breads, artisan sweet cakes, traditional cookies, and savory puffs daily.',
      address: 'Poonamallee High Road, Arumbakkam, Chennai',
      latitude: 13.0720,
      longitude: 80.2110,
      rating: 4.9,
      reviewCount: 89,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
      images: [
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517433670267-08bbd4be890f?auto=format&fit=crop&w=800&q=80',
      ],
      tags: ['Bakery', 'Fresh Cakes', 'Pastries', 'Breads'],
      isOpen: true,
      openHours: '07:00 AM - 10:00 PM',
      phone: '9123581148',
      website: 'https://www.selvanbakery.com',
      distanceKm: 0.5,
    ),
    BusinessModel(
      id: 'mock-4',
      name: 'Laila shopping',
      category: 'Clothing',
      description: 'Trendy fashion wear, designer ethnic suits, sarees, and modern lifestyle clothing boutique.',
      address: 'Usman Road, T. Nagar, Chennai',
      latitude: 13.0400,
      longitude: 80.2300,
      rating: 4.6,
      reviewCount: 41,
      imageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=800&q=80',
      images: [
        'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=800&q=80',
      ],
      tags: ['Clothing', 'Fashion', 'Sarees', 'Boutique'],
      isOpen: true,
      openHours: '09:30 AM - 09:00 PM',
      phone: '9876543212',
      website: 'https://www.lailashopping.com',
      distanceKm: 2.1,
    ),
  ];

  /// Fetch all categories from the database, with a hardcoded fallback if the
  /// table does not yet exist in Supabase.
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final List<dynamic> response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name');
      if (response.isNotEmpty) {
        return response.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('BusinessService.getCategories: table query failed, using fallback: $e');
    }

    // Hardcoded fallback — used when DB table does not yet exist.
    const defaultNames = [
      'Food',
      'Restaurant',
      'Café',
      'Bakery',
      'Shopping',
      'Clothing',
      'Services',
      'Home Business',
      'Beauty',
      'Electronics',
      'Hangout',
      'Other'
    ];
    return defaultNames.map((name) => {'id': name, 'name': name}).toList();
  }

  /// Fetch all review ratings from the reviews table and aggregate count & average per business.
  Future<Map<String, ({int count, int totalStars})>> _fetchReviewStats() async {
    try {
      final List<dynamic> reviewsRes = await _supabase
          .from('reviews')
          .select('business_id, rating');

      final Map<String, ({int count, int totalStars})> stats = {};
      for (final r in reviewsRes) {
        if (r is Map) {
          final bId = r['business_id']?.toString();
          final rating = (r['rating'] as num?)?.toInt();
          if (bId != null && rating != null) {
            final current = stats[bId] ?? (count: 0, totalStars: 0);
            stats[bId] = (
              count: current.count + 1,
              totalStars: current.totalStars + rating,
            );
          }
        }
      }
      return stats;
    } catch (e) {
      debugPrint('BusinessService._fetchReviewStats: non-fatal: $e');
      return {};
    }
  }

  /// Query active businesses from Supabase with optional search & category
  /// filters, filtered strictly to within 5km of the user's current GPS location.
  Future<List<BusinessModel>> getBusinesses({
    String? categoryId,
    String? searchQuery,
    double? userLatitude,
    double? userLongitude,
    double maxRadiusKm = 5.0,
  }) async {
    try {
      List<dynamic> response = [];

      try {
        var query = _supabase
            .from('businesses')
            .select('*, categories(id, name), business_images(id, image_url)')
            .eq('is_active', true);

        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.eq('category_id', categoryId);
        }
        response = await query;
      } catch (e) {
        debugPrint('BusinessService.getBusinesses: categories join failed, retrying: $e');
        try {
          var query = _supabase
              .from('businesses')
              .select('*, business_images(id, image_url)')
              .eq('is_active', true);
          response = await query;
        } catch (e2) {
          debugPrint('BusinessService.getBusinesses: images join failed, retrying: $e2');
          try {
            var query = _supabase
                .from('businesses')
                .select('*')
                .eq('is_active', true);
            response = await query;
          } catch (e3) {
            debugPrint('BusinessService.getBusinesses: plain select failed: $e3');
          }
        }
      }

      List<BusinessModel> listings =
          response.map((data) => BusinessModel.fromJson(data as Map<String, dynamic>)).toList();

      // Populate live review ratings and review counts from reviews table
      final reviewStats = await _fetchReviewStats();
      if (reviewStats.isNotEmpty) {
        listings = listings.map((b) {
          final stat = reviewStats[b.id];
          if (stat != null && stat.count > 0) {
            final double avg = ((stat.totalStars / stat.count) * 10).round() / 10.0;
            return b.copyWith(rating: avg, reviewCount: stat.count);
          }
          return b;
        }).toList();
      }

      // Merge mock businesses into the public discovery feed.
      final Set<String> existingNames =
          listings.map((b) => b.name.toLowerCase()).toSet();
      for (final mock in mockBusinesses) {
        if (!existingNames.contains(mock.name.toLowerCase())) {
          if (categoryId == null ||
              categoryId.isEmpty ||
              mock.category.toLowerCase() == categoryId.toLowerCase()) {
            listings.add(mock);
          }
        }
      }

      // Local search filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        listings = listings.where((item) {
          return item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.address.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q);
        }).toList();
      }

      // HYPERLOCAL 5 KM DISTANCE FILTERING
      if (userLatitude != null && userLongitude != null) {
        // Compute real geographic distance using Haversine formula
        listings = listings.map((item) {
          final double dist = LocationService.instance.calculateDistanceKm(
            userLatitude,
            userLongitude,
            item.latitude,
            item.longitude,
          );
          return item.copyWith(distanceKm: dist);
        }).toList();

        // Filter strictly to <= 5 km
        listings = listings.where((item) => item.distanceKm <= maxRadiusKm).toList();

        // Sort nearest distance first
        listings.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      } else {
        // If GPS location is unavailable, handle gracefully by returning no unverified nearby results.
        listings = [];
      }

      return listings;
    } catch (e) {
      debugPrint('BusinessService.getBusinesses: unexpected error: $e');
      return [];
    }
  }

  /// Get specific business details by ID.
  Future<BusinessModel> getBusinessById(String id) async {
    // Return mock business immediately if it is a mock ID
    if (id.startsWith('mock-') || mockBusinesses.any((b) => b.id == id)) {
      return mockBusinesses.firstWhere(
        (b) => b.id == id,
        orElse: () => mockBusinesses.first,
      );
    }

    try {
      Map<String, dynamic> response;
      try {
        response = await _supabase
            .from('businesses')
            .select('*, categories(id, name), business_images(id, image_url)')
            .eq('id', id)
            .single();
      } catch (e) {
        try {
          response = await _supabase
              .from('businesses')
              .select('*, business_images(id, image_url)')
              .eq('id', id)
              .single();
        } catch (e2) {
          response = await _supabase
              .from('businesses')
              .select('*')
              .eq('id', id)
              .single();
        }
      }

      var model = BusinessModel.fromJson(response);
      try {
        final reviews = await ReviewService.instance.getReviewsForBusiness(id);
        final stats = ReviewService.computeStats(reviews);
        model = model.copyWith(rating: stats.average, reviewCount: stats.count);
      } catch (_) {}
      return model;
    } catch (e) {
      debugPrint('BusinessService.getBusinessById: error for id=$id: $e');
      // Return first mock as last-resort fallback
      return mockBusinesses.first;
    }
  }

  /// Fetch all businesses owned by the currently signed-in user.
  /// Returns an EMPTY LIST (not mock data) when the user has no real businesses,
  /// so the dashboard accurately reflects their actual listings.
  Future<List<BusinessModel>> getOwnerBusinesses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('BusinessService.getOwnerBusinesses: no authenticated user');
      return [];
    }

    try {
      List<dynamic> response = [];

      try {
        response = await _supabase
            .from('businesses')
            .select('*, categories(id, name), business_images(id, image_url)')
            .eq('owner_id', user.id)
            .order('created_at', ascending: false);
      } catch (e) {
        debugPrint('BusinessService.getOwnerBusinesses: categories join failed, retrying: $e');
        try {
          response = await _supabase
              .from('businesses')
              .select('*, business_images(id, image_url)')
              .eq('owner_id', user.id)
              .order('created_at', ascending: false);
        } catch (e2) {
          debugPrint('BusinessService.getOwnerBusinesses: images join failed, retrying: $e2');
          response = await _supabase
              .from('businesses')
              .select('*')
              .eq('owner_id', user.id)
              .order('created_at', ascending: false);
        }
      }

      var ownerListings = response
          .map((data) => BusinessModel.fromJson(data as Map<String, dynamic>))
          .toList();

      final reviewStats = await _fetchReviewStats();
      if (reviewStats.isNotEmpty) {
        ownerListings = ownerListings.map((b) {
          final stat = reviewStats[b.id];
          if (stat != null && stat.count > 0) {
            final double avg = ((stat.totalStars / stat.count) * 10).round() / 10.0;
            return b.copyWith(rating: avg, reviewCount: stat.count);
          }
          return b;
        }).toList();
      }

      return ownerListings;
    } catch (e) {
      debugPrint('BusinessService.getOwnerBusinesses: error: $e');
      // Return empty list — do NOT fall back to mock data for the owner dashboard.
      return [];
    }
  }

  /// Create a new business listing with separate Profile Image and Shop Gallery Photos.
  Future<BusinessModel> createBusiness({
    required String name,
    required String categoryName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phone,
    required String website,
    String? localProfileImagePath,
    List<String> localShopImagePaths = const [],
    List<String> localImagePaths = const [], // Backwards-compatibility fallback
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to register a business.');
    }

    // 1. Resolve category_id (null-safe — OK if categories table is missing)
    String? categoryId;
    try {
      categoryId = await _getCategoryId(categoryName);
    } catch (e) {
      debugPrint('BusinessService.createBusiness: category resolution failed (non-fatal): $e');
    }

    // 2. Build insert payload using ONLY existing DB columns.
    final Map<String, dynamic> insertPayload = {
      'owner_id': user.id,
      'name': name.trim(),
      'description': description.trim(),
      'address': address.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone.trim().isNotEmpty ? phone.trim() : null,
      'website': website.trim().isNotEmpty ? website.trim() : null,
      'is_active': true,
    };

    if (categoryId != null) {
      insertPayload['category_id'] = categoryId;
    }

    // 3. Insert the business record
    Map<String, dynamic> businessData;
    try {
      businessData = await _supabase
          .from('businesses')
          .insert(insertPayload)
          .select()
          .single();
    } catch (e) {
      debugPrint('BusinessService.createBusiness: insert failed: $e');
      throw Exception(
        'Unable to register your business right now. Please try again.',
      );
    }

    final String businessId = businessData['id'] as String;
    String? profileImageUrl;

    // 4. Upload Profile Image (if provided)
    if (localProfileImagePath != null && localProfileImagePath.isNotEmpty) {
      final file = io.File(localProfileImagePath);
      if (await file.exists()) {
        try {
          final ext = localProfileImagePath.split('.').last.toLowerCase();
          final storagePath = 'businesses/$businessId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final bytes = await file.readAsBytes();
          
          profileImageUrl = await _uploadImageToStorage(
            storagePath: storagePath,
            bytes: bytes,
          );

          if (profileImageUrl != null) {
            // Only insert into business_images — businesses table has no image_url column
            try {
              await _supabase.from('business_images').insert({
                'business_id': businessId,
                'image_url': profileImageUrl,
              });
            } catch (imgDbErr) {
              debugPrint('BusinessService.createBusiness: business_images insert failed: $imgDbErr');
            }
          }
        } catch (err) {
          debugPrint('BusinessService.createBusiness: profile image upload error: $err');
        }
      }
    }

    // Combine shop photos list (handling fallback)
    final shopPhotosToUpload = localShopImagePaths.isNotEmpty ? localShopImagePaths : localImagePaths;
    final List<String> shopPhotoUrls = [];

    // 5. Upload Shop / Gallery Photos
    for (int i = 0; i < shopPhotosToUpload.length; i++) {
      final path = shopPhotosToUpload[i];
      final extension = path.split('.').last.toLowerCase();
      final storagePath = 'businesses/$businessId/shop_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

      final file = io.File(path);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          final publicUrl = await _uploadImageToStorage(
            storagePath: storagePath,
            bytes: bytes,
          );

          if (publicUrl != null) {
            shopPhotoUrls.add(publicUrl);

            try {
              await _supabase.from('business_images').insert({
                'business_id': businessId,
                'image_url': publicUrl,
              });
            } catch (imgDbErr) {
              debugPrint('BusinessService.createBusiness: business_images insert failed: $imgDbErr');
            }
          }
        } catch (storageErr) {
          debugPrint('BusinessService.createBusiness: shop photo upload failed: $storageErr');
        }
      }
    }

    // 5. Upgrade user role to 'business_owner' if still 'user'
    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      if (profile['role'] == 'user') {
        await AuthService.instance.updateProfile(role: 'business_owner');
      }
    } catch (roleError) {
      debugPrint('BusinessService.createBusiness: role upgrade failed (non-fatal): $roleError');
    }

    // 6. Return the newly created business model
    final List<String> allImages = [];
    if (profileImageUrl != null) allImages.add(profileImageUrl);
    allImages.addAll(shopPhotoUrls);

    return BusinessModel.fromJson({
      ...businessData,
      'image_url': profileImageUrl ?? businessData['image_url'],
      // Inject category name for immediate display before next DB fetch
      'categories': {'name': categoryName},
      'business_images': allImages
          .map((url) => {'image_url': url})
          .toList(),
    });
  }

  /// Update an existing business listing, managing image deletions and uploads.
  Future<void> updateBusiness({
    required String businessId,
    required String name,
    required String categoryName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phone,
    required String website,
    required List<String> localImagePathsToUpload,
    required List<String> existingImageUrlsToKeep,
    String? localProfileImagePath,
    bool isActive = true,
  }) async {
    try {
      String? categoryId;
      try {
        categoryId = await _getCategoryId(categoryName);
      } catch (e) {
        debugPrint('BusinessService.updateBusiness: category resolution failed (non-fatal): $e');
      }

      final Map<String, dynamic> updatePayload = {
        'name': name.trim(),
        'description': description.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone.trim().isNotEmpty ? phone.trim() : null,
        'website': website.trim().isNotEmpty ? website.trim() : null,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (categoryId != null) {
        updatePayload['category_id'] = categoryId;
      }

      // Handle new profile image upload
      if (localProfileImagePath != null && localProfileImagePath.isNotEmpty) {
        final file = io.File(localProfileImagePath);
        if (await file.exists()) {
          try {
            final ext = localProfileImagePath.split('.').last.toLowerCase();
            final storagePath = 'businesses/$businessId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
            final bytes = await file.readAsBytes();
            final newProfileUrl = await _uploadImageToStorage(
              storagePath: storagePath,
              bytes: bytes,
            );
            if (newProfileUrl != null) {
              // Only insert into business_images — businesses table has no image_url column
              try {
                await _supabase.from('business_images').insert({
                  'business_id': businessId,
                  'image_url': newProfileUrl,
                });
              } catch (imgDbErr) {
                debugPrint('BusinessService.updateBusiness: business_images insert failed: $imgDbErr');
              }
            }
          } catch (profileErr) {
            debugPrint('BusinessService.updateBusiness: profile image upload failed: $profileErr');
          }
        }
      }

      await _supabase
          .from('businesses')
          .update(updatePayload)
          .eq('id', businessId);

      // Delete removed business images
      try {
        final currentImagesResponse = await _supabase
            .from('business_images')
            .select('image_url')
            .eq('business_id', businessId);

        final List<String> currentDbUrls = (currentImagesResponse as List)
            .map((img) => img['image_url'] as String)
            .toList();

        for (final dbUrl in currentDbUrls) {
          if (!existingImageUrlsToKeep.contains(dbUrl)) {
            await _supabase
                .from('business_images')
                .delete()
                .eq('business_id', businessId)
                .eq('image_url', dbUrl);
          }
        }
      } catch (imgDelErr) {
        debugPrint('BusinessService.updateBusiness: image cleanup failed: $imgDelErr');
      }

      // Upload new shop images
      for (int i = 0; i < localImagePathsToUpload.length; i++) {
        final path = localImagePathsToUpload[i];
        final extension = path.split('.').last.toLowerCase();
        final storagePath =
            'businesses/$businessId/${DateTime.now().millisecondsSinceEpoch}_u_$i.$extension';

        final file = io.File(path);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final publicUrl = await _uploadImageToStorage(
              storagePath: storagePath,
              bytes: bytes,
            );

            if (publicUrl != null) {
              try {
                await _supabase.from('business_images').insert({
                  'business_id': businessId,
                  'image_url': publicUrl,
                });
              } catch (imgInsErr) {
                debugPrint('BusinessService.updateBusiness: image record insert failed: $imgInsErr');
              }
            }
          } catch (stErr) {
            debugPrint('BusinessService.updateBusiness: image upload failed: $stErr');
          }
        }
      }
    } catch (e) {
      debugPrint('BusinessService.updateBusiness: error: $e');
      rethrow;
    }
  }

  /// Toggle the active/inactive state of a business (soft delete).
  Future<void> setBusinessActiveState(String businessId, bool isActive) async {
    try {
      await _supabase
          .from('businesses')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', businessId);
    } catch (e) {
      debugPrint('BusinessService.setBusinessActiveState: error: $e');
      rethrow;
    }
  }

  /// Delete a business owned by the currently authenticated user.
  /// Customer reviews remain protected; only business and image entries are removed.
  /// Enforces owner verification: business.owner_id == auth.uid() & Supabase RLS.
  Future<void> deleteBusiness(String businessId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to delete a business.');
    }

    try {
      // 1. Delete associated business images from DB
      try {
        await _supabase
            .from('business_images')
            .delete()
            .eq('business_id', businessId);
      } catch (imgErr) {
        debugPrint('BusinessService.deleteBusiness: image cleanup warning: $imgErr');
      }

      // 2. Delete business record (Supabase RLS policy enforces auth.uid() == owner_id)
      await _supabase
          .from('businesses')
          .delete()
          .eq('id', businessId)
          .eq('owner_id', user.id);

      debugPrint('BusinessService.deleteBusiness: business $businessId deleted successfully');
    } catch (e) {
      debugPrint('BusinessService.deleteBusiness error: $e');
      rethrow;
    }
  }

  /// Resolve a category name to its UUID from the categories table.
  /// Returns null if the table does not exist or the name is not found.
  /// Does NOT create new categories (seeded ones are sufficient).
  Future<String?> _getCategoryId(String name) async {
    try {
      final List<dynamic> result = await _supabase
          .from('categories')
          .select('id')
          .eq('name', name)
          .limit(1);

      if (result.isNotEmpty) {
        return result.first['id'] as String?;
      }

      // Category name not found — try case-insensitive match via ilike
      final List<dynamic> ilikeResult = await _supabase
          .from('categories')
          .select('id, name')
          .ilike('name', name)
          .limit(1);

      if (ilikeResult.isNotEmpty) {
        return ilikeResult.first['id'] as String?;
      }

      debugPrint('BusinessService._getCategoryId: no match for "$name"');
      return null;
    } catch (e) {
      debugPrint('BusinessService._getCategoryId: error: $e');
      return null;
    }
  }

  /// Safe helper method to upload binary data to Supabase Storage with bucket auto-creation / fallback
  Future<String?> _uploadImageToStorage({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    const bucketName = 'business-images';
    try {
      // 1. Try uploading to default bucket 'business-images'
      await _supabase.storage.from(bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: contentType,
              upsert: true,
            ),
          );
      return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('BusinessService._uploadImageToStorage primary upload failed ($e), attempting bucket creation/fallback...');
      try {
        // Attempt to create bucket 'business-images' if it doesn't exist
        await _supabase.storage.createBucket(
          bucketName,
          const BucketOptions(public: true),
        );
        await _supabase.storage.from(bucketName).uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                contentType: contentType,
                upsert: true,
              ),
            );
        return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
      } catch (e2) {
        debugPrint('BusinessService._uploadImageToStorage fallback bucket creation failed ($e2), attempting fallback bucket...');
        // Fallback to existing public buckets if 'business-images' cannot be created
        for (final fallbackBucket in ['public', 'businesses', 'images']) {
          try {
            await _supabase.storage.from(fallbackBucket).uploadBinary(
                  storagePath,
                  bytes,
                  fileOptions: FileOptions(
                    cacheControl: '3600',
                    contentType: contentType,
                    upsert: true,
                  ),
                );
            return _supabase.storage.from(fallbackBucket).getPublicUrl(storagePath);
          } catch (_) {}
        }
        
        // 4. Guaranteed Fallback: Base64 Data URI (stores in DB even if Storage bucket does not exist)
        debugPrint('BusinessService._uploadImageToStorage: using Base64 Data URI fallback for DB persistence');
        final base64Str = base64Encode(bytes);
        final mime = contentType.isNotEmpty ? contentType : 'image/jpeg';
        return 'data:$mime;base64,$base64Str';
      }
    }
  }
}
