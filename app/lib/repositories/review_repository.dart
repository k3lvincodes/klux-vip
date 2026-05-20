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
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final response = await _supabase
          .from('reviews')
          .insert({
            'ride_id': rideId,
            'reviewer_id': reviewerId,
            'reviewee_id': revieweeId,
            'rating': rating,
            'comment': comment,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<Map<String, dynamic>?> getReviewForRide(
    String rideId,
    String reviewerId,
  ) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('ride_id', rideId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasReviewedRide(String rideId, String reviewerId) async {
    final review = await getReviewForRide(rideId, reviewerId);
    return review != null;
  }
}
