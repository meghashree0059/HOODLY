import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post_model.dart';
import 'location_service.dart';

/// Fully functional, real Supabase-backed Community Service.
/// Posts dynamically resolve the author's live profile (name + avatar)
/// from public.profiles so profile updates reflect everywhere immediately.
class CommunityService {
  static final CommunityService instance = CommunityService._();
  CommunityService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const double _radiusKm = 5.0;
  static const String _storageBucket = 'business-images';
  static const String _communityPhotoPrefix = 'community';
  static const String _avatarPrefix = 'avatars';

  // ── Categories ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('community_service_categories')
          .select('id, name')
          .order('name');
      final list = List<Map<String, dynamic>>.from(response as List);
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('CommunityService.getCategories notice: $e');
    }

    const defaultCats = [
      'Tutoring',
      'Babysitting',
      'Plumbing',
      'Electrical',
      'Cleaning',
      'Pet Care',
      'Cooking',
      'Music & Arts',
      'Gardening',
      'Delivery',
      'Repairs',
      'Other'
    ];
    return defaultCats.map((name) => {'id': name, 'name': name}).toList();
  }

  // ── Profile Dynamic Enrichment ──────────────────────────────────────────

  /// Enriches raw community post maps with the latest profile details
  /// (name, avatar_url, phone, email) from public.profiles in a single batch.
  Future<List<Map<String, dynamic>>> _enrichWithProfiles(
      List<Map<String, dynamic>> rawList) async {
    if (rawList.isEmpty) return rawList;

    // Collect distinct author_ids
    final authorIds = rawList
        .map((p) => p['author_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    if (authorIds.isEmpty) return rawList;

    try {
      final profilesResp = await _client
          .from('profiles')
          .select('id, name, avatar_url, phone, email')
          .filter('id', 'in', authorIds);

      final Map<String, Map<String, dynamic>> profileMap = {
        for (final p in (profilesResp as List))
          p['id'].toString(): Map<String, dynamic>.from(p as Map)
      };

      for (final post in rawList) {
        final authorId = post['author_id']?.toString();
        if (authorId != null && profileMap.containsKey(authorId)) {
          post['profiles'] = profileMap[authorId];
        }
      }
    } catch (e) {
      debugPrint('Notice: unable to batch fetch author profiles: $e');
    }

    return rawList;
  }

  // ── Read Nearby Community Posts ─────────────────────────────────────────

  /// Fetch active community posts within [_radiusKm] km of user GPS,
  /// enriched with each author's current profile data, sorted nearest-first.
  Future<List<CommunityPostModel>> getPosts({
    String? categoryId,
    String? postType,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      var query = _client
          .from('community_posts')
          .select()
          .eq('status', 'active');

      if (postType != null && postType.isNotEmpty) {
        query = query.eq('post_type', postType.toLowerCase());
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query.order('created_at', ascending: false);
      final rawList = List<Map<String, dynamic>>.from(response as List);

      // Dynamically resolve author name and avatar from public.profiles
      await _enrichWithProfiles(rawList);

      List<CommunityPostModel> posts =
          rawList.map(CommunityPostModel.fromJson).toList();

      // Compute straight-line distance via Hoodly location service
      if (userLatitude != null && userLongitude != null) {
        posts = posts.map((post) {
          if (post.latitude != 0.0 && post.longitude != 0.0) {
            final dist = LocationService.instance.calculateDistanceKm(
              userLatitude,
              userLongitude,
              post.latitude,
              post.longitude,
            );
            return post.copyWith(distanceKm: dist);
          }
          return post;
        }).toList();

        // 5 km radius filtering
        posts = posts.where((p) => p.distanceKm <= _radiusKm).toList();

        // Nearest-first sorting
        posts.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      return posts;
    } catch (e) {
      debugPrint('CommunityService.getPosts error: $e');
      rethrow;
    }
  }

  /// Fetch a single real post by ID from Supabase, with live profile enrichment.
  Future<CommunityPostModel?> getPostById(String id) async {
    try {
      final response = await _client
          .from('community_posts')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        final list = [Map<String, dynamic>.from(response)];
        await _enrichWithProfiles(list);
        return CommunityPostModel.fromJson(list.first);
      }
      return null;
    } catch (e) {
      debugPrint('CommunityService.getPostById error for id=$id: $e');
      return null;
    }
  }

  /// Fetch all posts authored by the currently signed-in user, with live profile enrichment.
  Future<List<CommunityPostModel>> getMyPosts() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('CommunityService.getMyPosts: unauthenticated');
      return [];
    }

    try {
      final response = await _client
          .from('community_posts')
          .select()
          .eq('author_id', user.id)
          .order('created_at', ascending: false);

      final rawList = List<Map<String, dynamic>>.from(response as List);
      await _enrichWithProfiles(rawList);
      return rawList.map(CommunityPostModel.fromJson).toList();
    } catch (e) {
      debugPrint('CommunityService.getMyPosts error: $e');
      rethrow;
    }
  }

  // ── Write (Create, Update, Delete) ──────────────────────────────────────

  /// Create a real community post in Supabase owned by the current auth.uid().
  Future<CommunityPostModel> createPost({
    required String title,
    required String description,
    String? categoryId,
    String? category,
    required String postType,
    String feePayment = 'Free',
    String contactMethod = 'both',
    String contactPhone = '',
    String contactEmail = '',
    required String address,
    required double latitude,
    required double longitude,
    List<String> photoUrls = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to post in the community.');
    }

    final Map<String, dynamic> insertPayload = {
      'author_id': user.id,
      'title': title.trim(),
      'description': description.trim(),
      'category': category ?? 'General',
      'post_type': postType.toLowerCase(),
      'fee_payment': feePayment.trim().isNotEmpty ? feePayment.trim() : 'Free',
      'contact_method': contactMethod.toLowerCase(),
      'contact_phone': contactPhone.trim(),
      'contact_email': contactEmail.trim().isNotEmpty
          ? contactEmail.trim()
          : (user.email ?? ''),
      'address': address.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'photo_urls': photoUrls,
      'status': 'active',
    };

    if (categoryId != null && categoryId.isNotEmpty) {
      insertPayload['category_id'] = categoryId;
    }

    try {
      final response = await _client
          .from('community_posts')
          .insert(insertPayload)
          .select()
          .single();

      final list = [Map<String, dynamic>.from(response)];
      await _enrichWithProfiles(list);
      return CommunityPostModel.fromJson(list.first);
    } catch (e) {
      debugPrint('CommunityService.createPost insert error: $e');
      rethrow;
    }
  }

  /// Update an existing post authored by the current user.
  Future<CommunityPostModel> updatePost({
    required String id,
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to update this post.');
    }

    final Map<String, dynamic> data = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) data['title'] = title.trim();
    if (description != null) data['description'] = description.trim();
    if (categoryId != null) data['category_id'] = categoryId;
    if (category != null) data['category'] = category;
    if (postType != null) data['post_type'] = postType.toLowerCase();
    if (feePayment != null) data['fee_payment'] = feePayment.trim();
    if (contactMethod != null) data['contact_method'] = contactMethod.toLowerCase();
    if (contactPhone != null) data['contact_phone'] = contactPhone.trim();
    if (contactEmail != null) data['contact_email'] = contactEmail.trim();
    if (address != null) data['address'] = address.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (photoUrls != null) data['photo_urls'] = photoUrls;
    if (status != null) data['status'] = status.toLowerCase();

    try {
      final response = await _client
          .from('community_posts')
          .update(data)
          .eq('id', id)
          .eq('author_id', user.id)
          .select()
          .single();

      final list = [Map<String, dynamic>.from(response)];
      await _enrichWithProfiles(list);
      return CommunityPostModel.fromJson(list.first);
    } catch (e) {
      debugPrint('CommunityService.updatePost error: $e');
      rethrow;
    }
  }

  /// Delete a post authored by the current user.
  Future<void> deletePost(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to delete this post.');
    }

    try {
      await _client
          .from('community_posts')
          .delete()
          .eq('id', id)
          .eq('author_id', user.id);
    } catch (e) {
      debugPrint('CommunityService.deletePost error: $e');
      rethrow;
    }
  }

  // ── Photo & Avatar Storage ──────────────────────────────────────────────

  /// Ensures storage bucket exists if client permissions permit.
  Future<void> _ensureBucketExists() async {
    try {
      await _client.storage.createBucket(
        _storageBucket,
        const BucketOptions(public: true),
      );
    } catch (_) {
      // Ignored: bucket already exists or requires dashboard SQL creation
    }
  }

  /// Upload a community post photo and return its public URL.
  Future<String> uploadPhoto(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _ensureBucketExists();

    final ext = file.path.split('.').last.toLowerCase();
    final fileName =
        '$_communityPhotoPrefix/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage
          .from(_storageBucket)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      return _client.storage.from(_storageBucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('CommunityService.uploadPhoto error: $e');
      rethrow;
    }
  }

  /// Upload a user profile/avatar photo to the avatars/ prefix and return
  /// the public URL. Overwrites any previous upload for this user.
  Future<String> uploadProfilePhoto(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _ensureBucketExists();

    final ext = file.path.split('.').last.toLowerCase();
    // Unique filename with timestamp to bust network image caches
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$_avatarPrefix/${user.id}/avatar_$timestamp.$ext';

    try {
      await _client.storage
          .from(_storageBucket)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _client.storage.from(_storageBucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('CommunityService.uploadProfilePhoto error: $e');
      if (e.toString().contains('Bucket not found')) {
        throw Exception(
            "Storage bucket 'business-images' not found. Please run the SQL setup script in your Supabase SQL Editor to create it.");
      }
      rethrow;
    }
  }
}
