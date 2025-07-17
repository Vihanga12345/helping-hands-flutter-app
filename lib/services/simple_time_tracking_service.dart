import 'package:supabase_flutter/supabase_flutter.dart';
import 'popup_manager_service.dart';
import 'payment_flow_service.dart';
import 'custom_auth_service.dart';

class SimpleTimeTrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final PopupManagerService _popupManager = PopupManagerService();
  static final PaymentFlowService _paymentFlow = PaymentFlowService();
  static final CustomAuthService _authService = CustomAuthService();

  /// Accept a job - both users go to ongoing tab with accept popup
  static Future<bool> acceptJob(String jobId) async {
    try {
      print('✅ Helper accepting job: $jobId');

      // Update job status to accepted and set acceptance time
      await _supabase.from('jobs').update({
        'status': 'accepted',
        'assigned_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Show accept popup for both users
      _popupManager.showJobAcceptedPopup({
        'id': jobId,
        'status': 'accepted',
      });

      print('✅ Job accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting job: $e');
      return false;
    }
  }

  /// Start a job - record start time, both users stay on ongoing tab with start popup
  static Future<bool> startJob(String jobId) async {
    try {
      final now = DateTime.now();
      print('✅ Helper starting job: $jobId at ${now.toIso8601String()}');

      // Update job with start time and status
      await _supabase.from('jobs').update({
        'actual_start_time': now.toIso8601String(),
        'status': 'started',
        'timer_status': 'running',
        'is_timer_running': true,
        'session_start_time': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', jobId);

      // Show start popup for both users
      _popupManager.showJobStartedPopup({
        'id': jobId,
        'status': 'started',
      });

      print('✅ Job started successfully with timer');
      return true;
    } catch (e) {
      print('❌ Error starting job: $e');
      return false;
    }
  }

  /// Complete a job - USE TIMER DATA for duration/fee calculation
  static Future<bool> completeJob(String jobId) async {
    try {
      final now = DateTime.now();
      print('🎉 Helper completing job: $jobId at ${now.toIso8601String()}');

      // First, update job with end time and completed status
      await _supabase.from('jobs').update({
        'actual_end_time': now.toIso8601String(),
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'timer_status': 'completed',
        'is_timer_running': false,
        'updated_at': now.toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job marked as completed');

      // Duration and fee calculation is now handled automatically by database AFTER trigger
      // No need for manual RPC call - this prevents trigger conflicts

      // Show job completed popup for both users
      _popupManager.showJobCompletedPopup({
        'id': jobId,
        'status': 'completed',
      });

      // Start payment confirmation flow after popup delay
      Future.delayed(const Duration(milliseconds: 3000), () {
        print('💰 Starting payment confirmation flow for job: $jobId');
        _paymentFlow.startPaymentConfirmationFlow(jobId);
      });

      print('🎉 Job completion flow started successfully');
      return true;
    } catch (e) {
      print('❌ Error completing job: $e');
      return false;
    }
  }

  /// Get job duration and fee details from TIMER DATA (REAL calculated data)
  static Future<Map<String, dynamic>?> getJobDurationDetails(
      String jobId) async {
    try {
      // Use timer-based calculation function
      final response = await _supabase
          .rpc('get_timer_based_payment_details', params: {'p_job_id': jobId});

      if (response != null && response['job_id'] != null) {
        print('✅ Timer-based duration details retrieved successfully');
        return {
          'duration_minutes': response['duration_minutes'] ?? 0,
          'duration_text': response['duration_text'] ?? 'Not calculated',
          'total_fee': response['total_fee'] ?? 0,
          'final_amount': response['final_amount'] ?? 0,
          'hourly_rate': response['hourly_rate'] ?? 1000.0,
          'job_id': response['job_id'],
          'status': response['status'],
          'is_completed': response['status'] == 'completed',
          'is_calculated': response['is_calculated'] ?? true,
          'data_source': 'timer_based', // Mark as timer-based data
        };
      }

      // Fallback: Try to get basic job details
      final fallbackResponse = await _supabase
          .from('jobs')
          .select(
              'id, status, total_duration, total_fee, final_amount, hourly_rate')
          .eq('id', jobId)
          .maybeSingle();

      if (fallbackResponse != null) {
        final durationMinutes = fallbackResponse['total_duration'] ?? 0;
        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;

        return {
          'duration_minutes': durationMinutes,
          'duration_text': hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
          'total_fee': fallbackResponse['total_fee'] ?? 0,
          'final_amount': fallbackResponse['final_amount'] ?? 0,
          'hourly_rate': fallbackResponse['hourly_rate'] ?? 1000.0,
          'job_id': jobId,
          'status': fallbackResponse['status'],
          'is_completed': fallbackResponse['status'] == 'completed',
          'is_calculated': false, // Mark as fallback data
          'data_source': 'fallback',
        };
      }

      return null;
    } catch (e) {
      print('❌ Error getting timer-based duration details: $e');
      return null;
    }
  }

  /// Get payment details for payment confirmation pages (TIMER-based data)
  static Future<Map<String, dynamic>?> getPaymentDetails(String jobId) async {
    try {
      // Use the new timer-based payment function
      final response = await _supabase
          .rpc('get_timer_based_payment_details', params: {'p_job_id': jobId});

      if (response != null && response['job_id'] != null) {
        print('✅ Timer-based payment details retrieved successfully');
        print('   Duration: ${response['duration_text']}');
        print('   Amount: LKR ${response['final_amount']}');

        return {
          'job_id': response['job_id'],
          'job_title': response['job_title'] ?? 'Job',
          'status': response['status'],
          'duration_minutes': response['duration_minutes'] ?? 0,
          'duration_text': response['duration_text'] ?? 'Not calculated',
          'hourly_rate': response['hourly_rate'] ?? 1000.0,
          'total_fee': response['total_fee'] ?? 0,
          'final_amount': response['final_amount'] ?? 0,
          'helpee_id': response['helpee_id'],
          'helper_id': response['helper_id'],
          'category': response['category'] ?? 'General',
          'is_calculated': response['is_calculated'] ?? true,
          'data_source': response['data_source'] ?? 'timer_based',
        };
      }

      print('⚠️ Timer-based payment details not available');
      return null;
    } catch (e) {
      print('❌ Error getting timer-based payment details: $e');
      return null;
    }
  }

  /// Calculate fee for a given duration in minutes
  static double calculateFee(int durationMinutes, double hourlyRate) {
    final feePerMinute = hourlyRate / 60;
    return durationMinutes * feePerMinute;
  }

  /// Format duration from minutes to readable text
  static String formatDuration(int durationMinutes) {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
