import 'package:supabase_flutter/supabase_flutter.dart';

class CashPaymentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initiate cash payment confirmation process using TIMER-BASED calculation
  /// Returns payment details for the confirmation dialog
  static Future<Map<String, dynamic>?> initiateCashPaymentConfirmation(
      String jobId) async {
    try {
      print(
          '💰 Initiating timer-based cash payment confirmation for job: $jobId');

      // Use the NEW timer-based payment confirmation function
      final response = await _supabase.rpc(
        'initiate_timer_based_payment_confirmation',
        params: {'job_id_param': jobId},
      );

      print('🔍 Raw response: $response');
      print('🔍 Response type: ${response.runtimeType}');

      if (response == null) {
        print('❌ Null response from timer-based payment confirmation RPC');
        return await _getPaymentDataManually(jobId);
      }

      // Handle different response formats safely - database returns List with one element
      Map<String, dynamic> data;

      if (response is List && response.isNotEmpty) {
        // Database function returns a List with one element
        data = Map<String, dynamic>.from(response.first);
        print('🔍 Extracted data from List response: $data');
      } else if (response is Map<String, dynamic>) {
        data = response;
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response);
      } else {
        print('❌ Unexpected response type: ${response.runtimeType}');
        return await _getPaymentDataManually(jobId);
      }

      // Handle success field safely - can be boolean, int (0/1), or string
      final success = data['success'];
      bool isSuccess = false;

      if (success is bool) {
        isSuccess = success;
      } else if (success is int) {
        isSuccess = success == 1;
      } else if (success is String) {
        isSuccess = success.toLowerCase() == 'true' || success == '1';
      }

      print(
          '🔍 Success field: $success (type: ${success.runtimeType}) -> interpreted as: $isSuccess');

      if (isSuccess) {
        print('✅ Timer-based payment confirmation initiated successfully');
        print('   Duration: ${data['duration_text']}');
        print('   Amount: LKR ${data['payment_amount_calculated']}');

        // Return properly formatted data with timer information
        final safeData = <String, dynamic>{
          'success': true,
          'job_id': jobId, // Use the provided jobId
          'payment_amount': _safeDouble(data['payment_amount_calculated']),
          'payment_amount_calculated':
              _safeDouble(data['payment_amount_calculated']),
          'helpee_name':
              '${data['helpee_first_name'] ?? 'Helpee'} ${data['helpee_last_name'] ?? ''}',
          'helper_name':
              '${data['helper_first_name'] ?? 'Helper'} ${data['helper_last_name'] ?? ''}',
          'helpee_first_name':
              data['helpee_first_name']?.toString() ?? 'Helpee',
          'helpee_last_name': data['helpee_last_name']?.toString() ?? '',
          'helper_first_name':
              data['helper_first_name']?.toString() ?? 'Helper',
          'helper_last_name': data['helper_last_name']?.toString() ?? '',
          'duration_text':
              data['duration_text']?.toString() ?? 'Not calculated',
          'duration_minutes': data['duration_minutes'] ?? 0,
          'job_title': data['job_title']?.toString() ?? 'Job',
          'data_source': data['data_source']?.toString() ?? 'timer_based',
        };

        return safeData;
      } else {
        final errorMsg = data['error']?.toString() ??
            data['message']?.toString() ??
            'Timer calculation failed';
        print(
            '❌ Failed to initiate timer-based payment confirmation: $errorMsg');

        // Fallback to manual calculation
        print('🔄 Falling back to manual payment data collection...');
        return await _getPaymentDataManually(jobId);
      }
    } catch (e) {
      print('❌ Error with timer-based payment function: $e');
      print('🔄 Falling back to manual payment data collection...');
      return await _getPaymentDataManually(jobId);
    }
  }

  /// Manual payment data collection using timer-based service functions
  static Future<Map<String, dynamic>?> _getPaymentDataManually(
      String jobId) async {
    try {
      print('🔧 Manually collecting payment data for job: $jobId');

      // Use SimpleTimeTrackingService to get timer-based payment details
      final paymentDetails = await _getTimerBasedPaymentDetails(jobId);

      if (paymentDetails != null) {
        print('✅ Manually collected payment data successfully');
        print('💰 Payment amount: LKR ${paymentDetails['final_amount']}');

        return {
          'success': true,
          'job_id': jobId,
          'payment_amount': paymentDetails['final_amount'] ?? 0.0,
          'payment_amount_calculated': paymentDetails['final_amount'] ?? 0.0,
          'duration_text': paymentDetails['duration_text'] ?? 'Not calculated',
          'duration_minutes': paymentDetails['duration_minutes'] ?? 0,
          'helpee_name': 'Helpee', // Will be populated by UI
          'helper_name': 'Helper', // Will be populated by UI
          'job_title': paymentDetails['job_title'] ?? 'Job',
          'data_source': 'manual_timer_based',
        };
      }

      // Final fallback: Basic job data
      final jobResponse = await _supabase
          .from('jobs')
          .select('final_amount, total_fee, hourly_rate, total_duration')
          .eq('id', jobId)
          .maybeSingle();

      if (jobResponse != null) {
        final amount = jobResponse['final_amount'] ??
            jobResponse['total_fee'] ??
            jobResponse['hourly_rate'] ??
            1000.0;

        final durationMinutes = jobResponse['total_duration'] ?? 60;
        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;
        final durationText =
            hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

        return {
          'success': true,
          'job_id': jobId,
          'payment_amount': amount,
          'payment_amount_calculated': amount,
          'duration_text': durationText,
          'duration_minutes': durationMinutes,
          'helpee_name': 'Helpee',
          'helper_name': 'Helper',
          'job_title': 'Job',
          'data_source': 'basic_fallback',
        };
      }

      print('⚠️ No payment data available for job: $jobId');
      return null;
    } catch (e) {
      print('❌ Error collecting payment data manually: $e');
      return null;
    }
  }

  /// Get timer-based payment details using the new service function
  static Future<Map<String, dynamic>?> _getTimerBasedPaymentDetails(
      String jobId) async {
    try {
      // Call the timer-based payment details function directly
      final response = await _supabase
          .rpc('get_timer_based_payment_details', params: {'p_job_id': jobId});

      if (response != null && response['job_id'] != null) {
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

      return null;
    } catch (e) {
      print('❌ Error getting timer-based payment details: $e');
      return null;
    }
  }

  /// Safely convert various types to double
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get payment status for a job
  static Future<Map<String, dynamic>> getPaymentStatus(String jobId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select(
              'payment_status, helpee_payment_confirmation, helper_payment_confirmation, final_amount, total_fee')
          .eq('id', jobId)
          .single();

      return {
        'payment_status': response['payment_status'] ?? 'pending',
        'helpee_confirmed': response['helpee_payment_confirmation'] ?? false,
        'helper_confirmed': response['helper_payment_confirmation'] ?? false,
        'amount': response['final_amount'] ?? response['total_fee'] ?? 0.0,
      };
    } catch (e) {
      print('❌ Error getting payment status: $e');
      return {
        'payment_status': 'pending',
        'helpee_confirmed': false,
        'helper_confirmed': false,
        'amount': 0.0,
      };
    }
  }

  /// Confirm helpee payment (helpee says "I have paid")
  static Future<bool> confirmHelpeePayment(String jobId, String helpeeId,
      {String notes = ''}) async {
    try {
      print('💸 Helpee confirming cash payment for job: $jobId');

      // Get payment amount first before attempting confirmation
      double paymentAmount = 0.0;
      try {
        final paymentData = await initiateCashPaymentConfirmation(jobId);
        if (paymentData != null && paymentData['success'] == true) {
          paymentAmount = _safeDouble(paymentData['payment_amount']);
        }
      } catch (e) {
        print('⚠️ Could not get payment amount: $e');
        paymentAmount = 0.0;
      }

      // Try using the database function first
      try {
        final response = await _supabase.rpc(
          'confirm_helpee_payment',
          params: {
            'job_id_param': jobId,
            'helpee_id_param': helpeeId,
            'notes_param': notes,
          },
        );

        if (response != null && response['success'] == true) {
          print('✅ Helpee payment confirmed successfully');
          return true;
        }
      } catch (rpcError) {
        print('⚠️ RPC function failed, trying direct update: $rpcError');
      }

      // Fallback: Manual confirmation with proper amount using new columns
      try {
        // First insert payment confirmation with amount
        await _supabase.from('payment_confirmations').insert({
          'job_id': jobId,
          'user_id': helpeeId,
          'confirmation_type': 'payment_made',
          'amount': paymentAmount,
          'payment_method': 'cash',
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Check if helper has already confirmed payment
        final jobData = await _supabase
            .from('jobs')
            .select('helper_payment_confirmation')
            .eq('id', jobId)
            .single();

        final helperConfirmed = jobData['helper_payment_confirmation'] ?? false;

        // Update job status using new columns
        await _supabase.from('jobs').update({
          'helpee_payment_confirmation': true,
          'helpee_payment_confirmed': true, // Keep for backward compatibility
          'payment_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
          // CRITICAL: Do NOT update job status here - PaymentFlowService handles that
        }).eq('id', jobId);

        print('✅ Helpee payment confirmed successfully via manual update');
        if (helperConfirmed) {
          print(
              '✅ Both parties confirmed payment - job marked as payment_confirmed');
        }
        return true;
      } catch (manualError) {
        print('❌ Manual update also failed: $manualError');

        // Last resort: Just update the job status with new columns
        await _supabase.from('jobs').update({
          'helpee_payment_confirmation': true,
          'helpee_payment_confirmed': true, // Keep for backward compatibility
          'payment_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', jobId);

        print('✅ Helpee payment confirmed with minimal update');
        return true;
      }
    } catch (e) {
      print('❌ Error confirming helpee payment: $e');
      return false;
    }
  }

  /// Confirm that helper has received the cash payment
  static Future<bool> confirmHelperPaymentReceived(
      String jobId, String? helperId,
      {String notes = ''}) async {
    try {
      print('💰 Helper confirming payment received for job: $jobId');

      // Get payment amount first before attempting confirmation
      double paymentAmount = 0.0;
      try {
        final paymentData = await initiateCashPaymentConfirmation(jobId);
        if (paymentData != null && paymentData['success'] == true) {
          paymentAmount = _safeDouble(paymentData['payment_amount']);
        }
      } catch (e) {
        print('⚠️ Could not get payment amount: $e');
        paymentAmount = 0.0;
      }

      // Try using the database function first
      try {
        final response = await _supabase.rpc(
          'confirm_helper_payment_received',
          params: {
            'job_id_param': jobId,
            'helper_id_param': helperId,
            'notes_param': notes,
          },
        );

        if (response != null && response['success'] == true) {
          print('✅ Helper payment received confirmed successfully');
          return true;
        }
      } catch (rpcError) {
        print('⚠️ RPC function failed, trying direct update: $rpcError');
      }

      // Fallback: Manual confirmation with proper amount using new columns
      try {
        // First insert payment confirmation with amount
        await _supabase.from('payment_confirmations').insert({
          'job_id': jobId,
          'user_id': helperId,
          'confirmation_type': 'payment_received',
          'amount': paymentAmount,
          'payment_method': 'cash',
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Check if helpee has already confirmed payment
        final jobData = await _supabase
            .from('jobs')
            .select('helpee_payment_confirmation')
            .eq('id', jobId)
            .single();

        final helpeeConfirmed = jobData['helpee_payment_confirmation'] ?? false;

        // Update job status using new columns
        await _supabase.from('jobs').update({
          'helper_payment_confirmation': true,
          'helper_payment_received': true, // Keep for backward compatibility
          'payment_confirmed_at': DateTime.now().toIso8601String(),
          'payment_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
          // CRITICAL: Do NOT update job status here - PaymentFlowService handles that
        }).eq('id', jobId);

        print(
            '✅ Helper payment received confirmed successfully via manual update');
        if (helpeeConfirmed) {
          print(
              '✅ Both parties confirmed payment - job marked as payment_confirmed');
        }
        return true;
      } catch (manualError) {
        print('❌ Manual update also failed: $manualError');

        // Last resort: Just update the job status with new columns
        await _supabase.from('jobs').update({
          'helper_payment_confirmation': true,
          'helper_payment_received': true, // Keep for backward compatibility
          'payment_confirmed_at': DateTime.now().toIso8601String(),
          'payment_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
          // CRITICAL: Do NOT update job status here - PaymentFlowService handles that
        }).eq('id', jobId);

        print('✅ Helper payment received confirmed with minimal update');
        return true;
      }
    } catch (e) {
      print('❌ Error confirming helper payment received: $e');
      return false;
    }
  }

  /// Report a payment dispute
  static Future<bool> reportPaymentDispute({
    required String jobId,
    required String reporterId,
    required String disputeType,
    required String description,
    double? amountDisputed,
  }) async {
    try {
      print('⚠️ Reporting payment dispute for job: $jobId');

      final response = await _supabase.rpc(
        'report_payment_dispute',
        params: {
          'job_id_param': jobId,
          'reporter_id_param': reporterId,
          'dispute_type_param': disputeType,
          'description_param': description,
          'amount_disputed_param': amountDisputed,
        },
      );

      if (response != null && response['success'] == true) {
        print('✅ Payment dispute reported successfully');
        return true;
      } else {
        print('❌ Failed to report payment dispute: ${response?['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Error reporting payment dispute: $e');
      return false;
    }
  }

  /// Get payment confirmation history for a job
  static Future<List<Map<String, dynamic>>> getPaymentConfirmations(
      String jobId) async {
    try {
      final response = await _supabase
          .from('payment_confirmations')
          .select('*')
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting payment confirmations: $e');
      return [];
    }
  }

  /// Get payment disputes for a job
  static Future<List<Map<String, dynamic>>> getPaymentDisputes(
      String jobId) async {
    try {
      print('⚠️ Getting payment disputes for job: $jobId');

      final response = await _supabase.from('payment_disputes').select('''
            *,
            reporter:users!payment_disputes_reporter_id_fkey(id, first_name, last_name, user_type)
          ''').eq('job_id', jobId).order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} payment disputes');
      final disputes = List<Map<String, dynamic>>.from(response);

      // Add a 'full_name' field to each reporter object
      for (var dispute in disputes) {
        if (dispute['reporter'] != null) {
          dispute['reporter']['full_name'] =
              '${dispute['reporter']['first_name']} ${dispute['reporter']['last_name']}'
                  .trim();
        }
      }

      return disputes;
    } catch (e) {
      print('❌ Error getting payment disputes: $e');
      return [];
    }
  }

  /// Calculate payment amount manually (for display purposes)
  static double calculatePaymentAmount(int totalSeconds, double hourlyRate) {
    double hours = totalSeconds / 3600.0;
    double amount = hours * hourlyRate;

    // Minimum payment of 1 hour
    if (amount < hourlyRate) {
      amount = hourlyRate;
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  /// Format currency amount for display
  static String formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  /// Get payment status summary for a job
  static Map<String, dynamic> getPaymentStatusSummary(
      Map<String, dynamic> job) {
    bool helpeeConfirmed = job['helpee_payment_confirmed'] ?? false;
    bool helperConfirmed = job['helper_payment_received'] ?? false;
    bool disputed = job['payment_dispute_reported'] ?? false;

    String status;
    String statusDescription;

    if (disputed) {
      status = 'disputed';
      statusDescription = 'Payment disputed - under review';
    } else if (helpeeConfirmed && helperConfirmed) {
      status = 'completed';
      statusDescription = 'Payment confirmed by both parties';
    } else if (helpeeConfirmed && !helperConfirmed) {
      status = 'waiting_helper';
      statusDescription = 'Waiting for helper to confirm receipt';
    } else if (!helpeeConfirmed) {
      status = 'waiting_helpee';
      statusDescription = 'Waiting for payment confirmation';
    } else {
      status = 'pending';
      statusDescription = 'Payment confirmation pending';
    }

    return {
      'status': status,
      'description': statusDescription,
      'helpee_confirmed': helpeeConfirmed,
      'helper_confirmed': helperConfirmed,
      'disputed': disputed,
      'amount': job['payment_amount_calculated'] ?? 0.0,
    };
  }
}
