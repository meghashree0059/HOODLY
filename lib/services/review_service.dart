import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import 'dart:io' as io;

/// Service for fetching, submitting, and managing business reviews.
class ReviewService {
  static final ReviewService instance = ReviewService._();
  ReviewService._();

  final _supabase = Supabase.instance.client;

  /// Fetch all reviews (with photos + reviewer name) for a given business.
  Future<List<ReviewModel>> getReviewsForBusiness(String businessId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('reviews')
          .select('*, profiles(name), review_photos(id, image_url)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return response
          .map((data) => ReviewModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ReviewService.getReviewsForBusiness: error: $e');
      return [];
    }
  }

  /// Submit a new review with optional photos.
  /// Throws [Exception] with a user-friendly message on failure.
  Future<ReviewModel> submitReview({
    required String businessId,
    required int rating,
    required String reviewText,
    List<String> localPhotoPaths = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to write a review.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5 stars.');
    }

    // Insert the review
    Map<String, dynamic> reviewData;
    try {
      reviewData = await _supabase
          .from('reviews')
          .insert({
            'business_id': businessId,
            'user_id': user.id,
            'rating': rating,
            'review_text': reviewText.trim(),
          })
          .select()
          .single();
    } catch (e) {
      debugPrint('ReviewService.submitReview: insert error: $e');
      if (e.toString().contains('one_review_per_user_per_business') ||
          e.toString().contains('duplicate key') ||
          e.toString().contains('23505')) {
        throw Exception('You have already reviewed this business. You can only submit one review per business.');
      }
      throw Exception('Unable to submit your review. Please try again.');
    }

    final String reviewId = reviewData['id'] as String;
    final List<String> uploadedPhotoUrls = [];

    // Upload photos (non-blocking — failure does not cancel review)
    for (int i = 0; i < localPhotoPaths.length; i++) {
      final path = localPhotoPaths[i];
      final ext = path.split('.').last.toLowerCase();
      final storagePath = 'reviews/${user.id}/$reviewId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final file = io.File(path);

      if (!await file.exists()) continue;

      try {
        final bytes = await file.readAsBytes();
        await _supabase.storage.from('review-images').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
        final url = _supabase.storage.from('review-images').getPublicUrl(storagePath);
        uploadedPhotoUrls.add(url);

        try {
          await _supabase.from('review_photos').insert({
            'review_id': reviewId,
            'image_url': url,
          });
        } catch (dbErr) {
          debugPrint('ReviewService.submitReview: review_photos insert error: $dbErr');
        }
      } catch (storageErr) {
        debugPrint('ReviewService.submitReview: photo upload error: $storageErr');
      }
    }

    // Fetch reviewer name from profiles
    String reviewerName = 'Anonymous';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();
      reviewerName = profile['name'] as String? ?? 'Anonymous';
    } catch (_) {}

    return ReviewModel(
      id: reviewId,
      businessId: businessId,
      userId: user.id,
      reviewerName: reviewerName,
      rating: rating,
      reviewText: reviewText.trim(),
      photoUrls: uploadedPhotoUrls,
      createdAt: DateTime.now(),
    );
  }

  /// Delete a review owned by the current authenticated user.
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);
    } catch (e) {
      debugPrint('ReviewService.deleteReview: error: $e');
      throw Exception('Unable to delete review. Please try again.');
    }
  }

  /// Compute average rating and review count from a list of reviews.
  static ({double average, int count}) computeStats(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return (average: 0.0, count: 0);
    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    final avg = sum / reviews.length;
    // Round to 1 decimal
    final rounded = (avg * 10).round() / 10;
    return (average: rounded, count: reviews.length);
  }
}
