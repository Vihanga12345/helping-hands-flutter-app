import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_auth_service.dart';

/// Comprehensive service for job detail pages
/// Fetches all necessary data including job info, questions/answers, user details, payment info
class JobDetailService {
  static final JobDetailService _instance = JobDetailService._internal();
  factory JobDetailService() => _instance;
  JobDetailService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();

  /// Get complete job details for any job status
  Future<Map<String, dynamic>?> getCompleteJobDetails(String jobId) async {
    try {
      print('🔍 Fetching complete job details for: $jobId');

      // Main job query with all related data
      final jobResponse = await _supabase.from('jobs').select('''
            *,
            helpee:users!jobs_helpee_id_fkey(
              id, first_name, last_name, phone, email, profile_image_url,
              location_address, user_type
            ),
            helper:users!jobs_assigned_helper_id_fkey(
              id, first_name, last_name, phone, email, profile_image_url,
              location_address, user_type
            ),
            category:job_categories!jobs_category_id_fkey(
              id, name, description, default_hourly_rate
            )
          ''').eq('id', jobId).single();

      if (jobResponse == null) {
        print('❌ Job not found: $jobId');
        return null;
      }

      final job = Map<String, dynamic>.from(jobResponse);

      // Get job questions and answers with proper join
      final questionsResponse =
          await _supabase.from('job_question_answers').select('''
            *,
            question:job_category_questions(
              id,
              question,
              question_type,
              options,
              placeholder_text,
              is_required
            )
          ''').eq('job_id', jobId).order('created_at');

      final questions = List<Map<String, dynamic>>.from(questionsResponse);

      // Process questions to get the correct answer based on question type
      for (var question in questions) {
        final questionType = question['question']?['question_type'] ?? 'text';
        String? answerValue;

        // Get the correct answer based on question type
        switch (questionType) {
            case 'text':
            answerValue = question['answer_text'] ?? question['answer'];
              break;
            case 'number':
            answerValue =
                question['answer_number']?.toString() ?? question['answer'];
            break;
          case 'yes_no':
            answerValue =
                question['answer_boolean']?.toString() ?? question['answer'];
              break;
            case 'date':
            answerValue =
                question['answer_date']?.toString() ?? question['answer'];
              break;
            case 'time':
            answerValue =
                question['answer_time']?.toString() ?? question['answer'];
              break;
            default:
            answerValue = question['answer'] ?? question['answer_text'];
        }

        // Set the processed answer
        question['processed_answer'] = answerValue ?? 'No answer provided';
      }

      // Get helper statistics if helper is assigned
      Map<String, dynamic>? helperStats;
      if (job['assigned_helper_id'] != null) {
        helperStats = await _getHelperStatistics(job['assigned_helper_id']);
      }

      // Get helpee statistics
      Map<String, dynamic>? helpeeStats;
      if (job['helpee_id'] != null) {
        helpeeStats = await _getHelpeeStatistics(job['helpee_id']);
      }

      // Get payment details if job is completed
      Map<String, dynamic>? paymentDetails;
      if (job['status']?.toLowerCase() == 'completed') {
        paymentDetails = await _getPaymentDetails(jobId);
      }

      // Get job timer status
      Map<String, dynamic>? timerStatus;
      if (['started', 'paused', 'ongoing']
          .contains(job['status']?.toLowerCase())) {
        timerStatus = await _getJobTimerStatus(jobId);
      }

      // Construct complete job details
      final completeJobDetails = {
        // Basic job info
        'id': job['id'],
        'title': job['title'],
        'description': job['description'],
        'status': job['status'],
        'pay': 'LKR ${job['hourly_rate']?.toString() ?? '0'}/Hr',
        'date': formatDate(job['scheduled_date']),
        'time': formatTime(job['scheduled_start_time']),
        'location': job['location_address'],
        'created_at': job['created_at'],
        'updated_at': job['updated_at'],
        'is_private': job['is_private'] ?? false,
        'priority': job['priority'] ?? 'standard',

        // Category info
        'category_id': job['category_id'],
        'category_name': job['category']?['name'] ?? 'Unknown',
        'category_description': job['category']?['description'] ?? '',
        'hourly_rate':
            (job['hourly_rate'] ?? job['category']?['default_hourly_rate'] ?? 0)
                .toString(),

        // Helpee details
        'helpee_id': job['helpee_id'],
        'helpee_first_name': job['helpee']?['first_name'] ?? '',
        'helpee_last_name': job['helpee']?['last_name'] ?? '',
        'helpee_full_name':
            '${job['helpee']?['first_name'] ?? ''} ${job['helpee']?['last_name'] ?? ''}'
              .trim(),
        'helpee_phone': job['helpee']?['phone'] ?? '',
        'helpee_email': job['helpee']?['email'] ?? '',
        'helpee_profile_pic': job['helpee']?['profile_image_url'] ?? '',
        'helpee_address': job['helpee']?['location_address'] ?? '',
        'helpee_stats': helpeeStats,

        // Helper details (if assigned)
        'assigned_helper_id': job['assigned_helper_id'],
        'helper_first_name': job['helper']?['first_name'] ?? '',
        'helper_last_name': job['helper']?['last_name'] ?? '',
        'helper_full_name':
            '${job['helper']?['first_name'] ?? ''} ${job['helper']?['last_name'] ?? ''}'
                        .trim(),
        'helper_phone': job['helper']?['phone'] ?? '',
        'helper_email': job['helper']?['email'] ?? '',
        'helper_profile_pic': job['helper']?['profile_image_url'] ?? '',
        'helper_address': job['helper']?['location_address'] ?? '',
        'helper_stats': helperStats,

        // Job questions and answers
        'questions': questions,
        'parsed_questions': questions,
        'has_questions': questions.isNotEmpty,

        // Payment details (for completed jobs)
        'payment_details': paymentDetails,

        // Timer status (for ongoing jobs)
        'timer_status': timerStatus,

        // Additional computed fields
        'has_helper': job['assigned_helper_id'] != null,
        'is_pending': job['status']?.toLowerCase() == 'pending',
        'is_ongoing': ['accepted', 'started', 'ongoing', 'paused']
            .contains(job['status']?.toLowerCase()),
        'is_completed': job['status']?.toLowerCase() == 'completed',
      };

      print('✅ Complete job details fetched successfully');
      return completeJobDetails;
    } catch (e) {
      print('❌ Error fetching complete job details: $e');
      return null;
    }
  }

  /// Get helper statistics
  Future<Map<String, dynamic>?> _getHelperStatistics(String helperId) async {
    try {
      // Try to get helper rating using job relationship (since helper_id column might not exist)
      final ratingResponse = await _supabase
          .from('ratings_reviews')
          .select('rating, jobs!inner(assigned_helper_id)')
          .eq('jobs.assigned_helper_id', helperId);

      final ratings = List<Map<String, dynamic>>.from(ratingResponse);
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings
                  .map((r) => (r['rating'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              ratings.length;

      // Get completed jobs count
      final completedJobsResponse = await _supabase
          .from('jobs')
          .select('id')
          .eq('assigned_helper_id', helperId)
          .eq('status', 'completed');

      final completedJobsCount = completedJobsResponse.length;

      return {
        'avg_rating': avgRating,
        'rating_count': ratings.length,
        'completed_jobs': completedJobsCount,
      };
    } catch (e) {
      print('❌ Error fetching helper statistics: $e');

      // Fallback: try to get basic job statistics without ratings
      try {
        final completedJobsResponse = await _supabase
            .from('jobs')
            .select('id')
            .eq('assigned_helper_id', helperId)
            .eq('status', 'completed');

        return {
          'avg_rating': 0.0,
          'rating_count': 0,
          'completed_jobs': completedJobsResponse.length,
        };
      } catch (fallbackError) {
        print('❌ Error in fallback helper statistics: $fallbackError');
        return {
          'avg_rating': 0.0,
          'rating_count': 0,
          'completed_jobs': 0,
        };
      }
    }
  }

  /// Get helpee statistics
  Future<Map<String, dynamic>?> _getHelpeeStatistics(String helpeeId) async {
    try {
      // Get helpee rating from helpers
      final ratingResponse = await _supabase
          .from('ratings_reviews')
          .select('rating')
          .eq('reviewee_id', helpeeId);

      final ratings = List<Map<String, dynamic>>.from(ratingResponse);
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings
                  .map((r) => (r['rating'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              ratings.length;

      // Get total jobs posted
      final totalJobsResponse =
          await _supabase.from('jobs').select('id').eq('helpee_id', helpeeId);

      final totalJobsCount = totalJobsResponse.length;

      return {
        'avg_rating': avgRating,
        'rating_count': ratings.length,
        'total_jobs': totalJobsCount,
      };
    } catch (e) {
      print('❌ Error fetching helpee statistics: $e');
      return null;
    }
  }

  /// Get payment details for completed jobs
  Future<Map<String, dynamic>?> _getPaymentDetails(String jobId) async {
    try {
      // Get payment record
      final paymentResponse = await _supabase
          .from('payments')
          .select('*')
          .eq('job_id', jobId)
          .maybeSingle();

      if (paymentResponse == null) {
        return null;
      }

      return {
        'amount': paymentResponse['amount'],
        'payment_method': paymentResponse['payment_method'],
        'status': paymentResponse['status'],
        'created_at': paymentResponse['created_at'],
        'duration_hours': paymentResponse['duration_hours'] ?? 0,
        'hourly_rate': paymentResponse['hourly_rate'] ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching payment details: $e');
      return null;
    }
  }

  /// Get job timer status for ongoing jobs
  Future<Map<String, dynamic>?> _getJobTimerStatus(String jobId) async {
    try {
      // Try to get timer records from job_timers table
      final timerResponse = await _supabase
          .from('job_timers')
          .select('*')
          .eq('job_id', jobId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (timerResponse == null) {
        return {
          'is_started': false,
          'is_paused': false,
          'start_time': null,
          'total_duration': 0,
        };
      }

      return {
        'is_started': timerResponse['is_started'] ?? false,
        'is_paused': timerResponse['is_paused'] ?? false,
        'start_time': timerResponse['start_time'],
        'pause_time': timerResponse['pause_time'],
        'total_duration': timerResponse['total_duration'] ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching timer status: $e');

      // Return default timer status when table doesn't exist
      return {
        'is_started': false,
        'is_paused': false,
        'start_time': null,
        'total_duration': 0,
      };
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(String jobId, String newStatus) async {
    try {
      await _supabase.from('jobs').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', jobId);

      print('✅ Job status updated to: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error updating job status: $e');
      return false;
    }
  }

  /// Accept job (for helpers)
  Future<bool> acceptJob(String jobId, String helperId) async {
    try {
      await _supabase.from('jobs').update({
        'assigned_helper_id': helperId,
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting job: $e');
      return false;
    }
  }

  /// Reject job (for helpers)
  Future<bool> rejectJob(String jobId, String reason) async {
    try {
      await _supabase.from('job_rejections').insert({
        'job_id': jobId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Job rejected successfully');
      return true;
    } catch (e) {
      print('❌ Error rejecting job: $e');
      return false;
    }
  }

  /// Format date for display
  String formatDate(String? dateString) {
    if (dateString == null) return 'Date not set';

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final day = date.day;
      final suffix = _getDaySuffix(day);

      return '${day}${suffix} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Format time for display
  String formatTime(String? timeString) {
    if (timeString == null) return 'Time not set';

    try {
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

          return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  /// Get formatted posting time
  String getPostingTime(String? createdAt) {
    if (createdAt == null) return 'Recently';

    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Cancel a job
  Future<bool> cancelJob(String jobId, String reason) async {
    try {
      print('❌ Cancelling job: $jobId');

      await _supabase.from('jobs').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
      }).eq('id', jobId);

      print('✅ Job cancelled successfully');
      return true;
    } catch (e) {
      print('❌ Error cancelling job: $e');
      return false;
    }
  }

  /// Get job status color
  String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'warning';
      case 'accepted':
      case 'started':
        return 'success';
      case 'completed':
        return 'success';
      case 'cancelled':
        return 'error';
      default:
        return 'textSecondary';
    }
  }

  /// Get formatted status text
  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'started':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  /// Check if job can be edited (only pending jobs can be edited)
  bool canEditJob(String status) {
    return status.toLowerCase() == 'pending';
  }

  /// Check if job can be cancelled (pending and accepted jobs can be cancelled)
  bool canCancelJob(String status) {
    return ['pending', 'accepted'].contains(status.toLowerCase());
  }
}
