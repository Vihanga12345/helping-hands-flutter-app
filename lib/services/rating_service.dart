import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  static final _supabase = Supabase.instance.client;

  /// Get detailed job information for rating display
  static Future<Map<String, dynamic>?> getJobDetailsForRating(
      String jobId) async {
    try {
      print('🔍 Fetching job details for rating: $jobId');

      // Fix: Use assigned_helper_id instead of helper_id
      final response = await _supabase.from('jobs').select('''
            *,
            helpee:helpee_id(id, first_name, last_name, profile_image_url),
            assigned_helper:assigned_helper_id(id, first_name, last_name, profile_image_url),
            job_categories(id, name)
          ''').eq('id', jobId).single();

      print('✅ Job details fetched successfully');
      return response;
    } catch (e) {
      print('❌ Error fetching job details: $e');
      return null;
    }
  }

  /// Submit a rating for a completed job
  static Future<bool> submitRating({
    required String jobId,
    required String raterId,
    required String ratedUserId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      print('💾 Submitting rating: $rating stars');

      // Insert rating using correct column names
      await _supabase.from('ratings').insert({
        'job_id': jobId,
        'rater_id': raterId,
        'rated_user_id': ratedUserId,
        'rating': rating,
        'review_text': reviewText,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update job rating flags based on rater
      final jobDetails = await _supabase
          .from('jobs')
          .select('helpee_id, assigned_helper_id')
          .eq('id', jobId)
          .single();

      final updateData = <String, dynamic>{};
      if (jobDetails['helpee_id'] == raterId) {
        updateData['is_rated_by_helpee'] = true;
      } else if (jobDetails['assigned_helper_id'] == raterId) {
        updateData['is_rated_by_helper'] = true;
      }

      if (updateData.isNotEmpty) {
        await _supabase.from('jobs').update(updateData).eq('id', jobId);
      }

      // Update average rating for the rated user
      await _updateUserAverageRating(ratedUserId);

      print('✅ Rating submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting rating: $e');
      return false;
    }
  }

  /// Calculate and update user's average rating
  static Future<void> _updateUserAverageRating(String userId) async {
    try {
      // Calculate average rating for the user
      final response = await _supabase
          .from('ratings')
          .select('rating')
          .eq('rated_user_id', userId);

      if (response.isNotEmpty) {
        final ratings = response.map((r) => r['rating'] as int).toList();
        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
        final totalReviews = ratings.length;

        // Update user's average rating only (total_reviews column doesn't exist)
        await _supabase.from('users').update({
          'average_rating': averageRating,
        }).eq('id', userId);

        print(
            '📊 Updated average rating for user $userId: ${averageRating.toStringAsFixed(1)} ($totalReviews reviews)');
      }
    } catch (e) {
      print('❌ Error updating average rating: $e');
    }
  }

  /// Get user's ratings and reviews
  static Future<List<Map<String, dynamic>>> getUserRatings(
      String userId) async {
    try {
      print('📊 Getting ratings for user: $userId');

      final response = await _supabase
          .from('ratings')
          .select('''
            *,
            rater:rater_id(id, first_name, last_name, profile_image_url),
            job:job_id(id, title, scheduled_date)
          ''')
          .eq('rated_user_id', userId)
          .order('created_at', ascending: false);

      print('✅ Found ${response.length} ratings for user');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting user ratings: $e');
      return [];
    }
  }

  /// Get average rating for a user
  static Future<Map<String, dynamic>> getUserAverageRating(
      String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('rating')
          .eq('rated_user_id', userId);

      if (response.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
        };
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      return {
        'average_rating': averageRating,
        'total_reviews': ratings.length,
      };
    } catch (e) {
      print('❌ Error calculating average rating: $e');
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }

  /// Check if a job has been rated by a specific user
  static Future<bool> hasUserRatedJob({
    required String jobId,
    required String raterId,
    required String ratedUserId,
  }) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('id')
          .eq('job_id', jobId)
          .eq('rater_id', raterId)
          .eq('rated_user_id', ratedUserId);

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if user rated job: $e');
      return false;
    }
  }
}
