import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_model.dart';
import 'auth_service.dart';
import 'location_service.dart';

class BusinessService {
  static final BusinessService instance = BusinessService._();
  BusinessService._();

  final _supabase = Supabase.instance.client;

  /// Fetch all categories listed in the database.
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final List<dynamic> response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  /// Query active businesses from Supabase, applying optional search & category filters,
  /// and sorting them locally by distance from user if user coordinates are provided.
  Future<List<BusinessModel>> getBusinesses({
    String? categoryId,
    String? searchQuery,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      var query = _supabase
          .from('businesses')
          .select('*, categories(id, name), business_images(id, image_url)')
          .eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final List<dynamic> response = await query;
      List<BusinessModel> listings = response.map((data) => BusinessModel.fromJson(data)).toList();

      // Apply search query filter locally for robust fallback
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        listings = listings.where((item) {
          return item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.address.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q);
        }).toList();
      }

      // Calculate distance and sort if user coordinates are available
      if (userLatitude != null && userLongitude != null) {
        listings = listings.map((item) {
          final double dist = LocationService.instance.calculateDistanceKm(
            userLatitude,
            userLongitude,
            item.latitude,
            item.longitude,
          );
          return item.copyWith(distanceKm: dist);
        }).toList();

        // Sort ascending by distance (closest first)
        listings.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      return listings;
    } catch (e) {
      debugPrint('Error getting businesses: $e');
      rethrow;
    }
  }

  /// Get specific business details by ID.
  Future<BusinessModel> getBusinessById(String id) async {
    try {
      final response = await _supabase
          .from('businesses')
          .select('*, categories(id, name), business_images(id, image_url)')
          .eq('id', id)
          .single();

      return BusinessModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching business by ID: $e');
      rethrow;
    }
  }

  /// Fetch all businesses listed by the currently signed-in business owner.
  Future<List<BusinessModel>> getOwnerBusinesses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final List<dynamic> response = await _supabase
          .from('businesses')
          .select('*, categories(id, name), business_images(id, image_url)')
          .eq('owner_id', user.id);

      return response.map((data) => BusinessModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching owner businesses: $e');
      return [];
    }
  }

  /// Create a new business listing, upload images, and register image records.
  Future<BusinessModel> createBusiness({
    required String name,
    required String categoryName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phone,
    required String website,
    required List<String> localImagePaths,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User must be logged in to list a business');

      // 1. Resolve Category ID
      final categoryId = await _getOrCreateCategoryId(categoryName);

      // 2. Insert Business row
      final businessData = await _supabase.from('businesses').insert({
        'owner_id': user.id,
        'name': name,
        'category_id': categoryId,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone.trim().isNotEmpty ? phone.trim() : null,
        'website': website.trim().isNotEmpty ? website.trim() : null,
        'is_active': true,
      }).select().single();

      final String businessId = businessData['id'] as String;

      // 3. Upload images and record URLs
      final List<String> imageUrls = [];
      for (int i = 0; i < localImagePaths.length; i++) {
        final path = localImagePaths[i];
        final extension = path.split('.').last;
        final storagePath = 'businesses/$businessId/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

        final file = io.File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          // Upload to 'business-images' bucket
          await _supabase.storage.from('business-images').uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );

          final publicUrl = _supabase.storage.from('business-images').getPublicUrl(storagePath);
          imageUrls.add(publicUrl);

          // Save link in DB
          await _supabase.from('business_images').insert({
            'business_id': businessId,
            'image_url': publicUrl,
          });
        }
      }

      // 4. Update profiles table to reflect 'business_owner' role if currently user
      try {
        final profile = await _supabase.from('profiles').select('role').eq('id', user.id).single();
        if (profile['role'] == 'user') {
          await AuthService.instance.updateProfile(role: 'business_owner');
        }
      } catch (roleError) {
        debugPrint('Error updating user role: $roleError');
      }

      return BusinessModel.fromJson({
        ...businessData,
        'categories': {'name': categoryName},
        'images': imageUrls,
      });
    } catch (e) {
      debugPrint('Error creating business listing: $e');
      rethrow;
    }
  }

  /// Update an existing business listing, managing deletions and new uploads of photos.
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
    bool isActive = true,
  }) async {
    try {
      // 1. Resolve Category ID
      final categoryId = await _getOrCreateCategoryId(categoryName);

      // 2. Update Business record
      await _supabase.from('businesses').update({
        'name': name,
        'category_id': categoryId,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone.trim().isNotEmpty ? phone.trim() : null,
        'website': website.trim().isNotEmpty ? website.trim() : null,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', businessId);

      // 3. Delete removed business images
      final currentImagesResponse = await _supabase
          .from('business_images')
          .select('image_url')
          .eq('business_id', businessId);

      final List<String> currentDbUrls = (currentImagesResponse as List)
          .map((img) => img['image_url'] as String)
          .toList();

      for (final dbUrl in currentDbUrls) {
        if (!existingImageUrlsToKeep.contains(dbUrl)) {
          // Remove from database
          await _supabase
              .from('business_images')
              .delete()
              .eq('business_id', businessId)
              .eq('image_url', dbUrl);
        }
      }

      // 4. Upload new images
      for (int i = 0; i < localImagePathsToUpload.length; i++) {
        final path = localImagePathsToUpload[i];
        final extension = path.split('.').last;
        final storagePath = 'businesses/$businessId/${DateTime.now().millisecondsSinceEpoch}_u_$i.$extension';

        final file = io.File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          await _supabase.storage.from('business-images').uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );

          final publicUrl = _supabase.storage.from('business-images').getPublicUrl(storagePath);

          // Save link in DB
          await _supabase.from('business_images').insert({
            'business_id': businessId,
            'image_url': publicUrl,
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating business: $e');
      rethrow;
    }
  }

  /// Toggle the active state of a business (Soft Delete).
  Future<void> setBusinessActiveState(String businessId, bool isActive) async {
    try {
      await _supabase
          .from('businesses')
          .update({'is_active': isActive})
          .eq('id', businessId);
    } catch (e) {
      debugPrint('Error deactivating business: $e');
      rethrow;
    }
  }

  /// Get category ID from name, creating it if not present.
  Future<String> _getOrCreateCategoryId(String name) async {
    final categories = await _supabase
        .from('categories')
        .select('id')
        .eq('name', name);

    if ((categories as List).isNotEmpty) {
      return categories.first['id'] as String;
    }

    final newCategory = await _supabase
        .from('categories')
        .insert({'name': name})
        .select('id')
        .single();

    return newCategory['id'] as String;
  }
}
