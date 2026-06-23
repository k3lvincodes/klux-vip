import 'package:kenick_vip/models/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> submitReview({
    required String rideId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _supabase
          .from('reviews')
          .insert({
            'ride_id': rideId,
            'reviewer_id': reviewerId,
            'reviewee_id': revieweeId,
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          })
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<List<Review>> getReviewsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<Review?> getReviewForRide(String rideId, String reviewerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('ride_id', rideId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();
      if (response == null) return null;
      return Review.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch review: $e');
    }
  }

  Future<bool> hasReviewedRide(String rideId, String reviewerId) async {
    final review = await getReviewForRide(rideId, reviewerId);
    return review != null;
  }
}
