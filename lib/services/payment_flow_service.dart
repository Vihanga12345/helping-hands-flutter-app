import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cash_payment_service.dart';
import 'custom_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'popup_state_service.dart';

class PaymentFlowService {
  static final PaymentFlowService _instance = PaymentFlowService._internal();
  factory PaymentFlowService() => _instance;
  PaymentFlowService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();
  final PopupStateService _stateService = PopupStateService();

  // Track ongoing payment flows to prevent duplicates
  final Set<String> _activePaymentFlows = <String>{};

  // Track payment confirmation listeners
  final Map<String, StreamSubscription> _paymentListeners = {};

  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    print('✅ PaymentFlowService navigator key set');
  }

  /// Start the payment confirmation flow for both users
  Future<void> startPaymentConfirmationFlow(String jobId) async {
    try {
      if (_activePaymentFlows.contains(jobId)) {
        print('⚠️ Payment flow already active for job: $jobId');
        return;
      }

      print('💰 Starting payment confirmation flow for job: $jobId');
      _activePaymentFlows.add(jobId);

      // CRITICAL: Update job status to 'completed' FIRST to trigger database
      // notifications early, before we start the payment flow. This prevents
      // interference with payment confirmation dialogs.
      await _supabase.from('jobs').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Job status updated to completed for: $jobId');

      // Get job details to identify both users
      final jobDetails = await _supabase
          .from('jobs')
          .select('helpee_id, assigned_helper_id, title')
          .eq('id', jobId)
          .single();

      if (jobDetails == null) {
        print('❌ Job not found: $jobId');
        _activePaymentFlows.remove(jobId);
        return;
      }

      final helpeeId = jobDetails['helpee_id'];
      final helperId = jobDetails['assigned_helper_id'];

      if (helpeeId == null || helperId == null) {
        print('❌ Missing user IDs for job: $jobId');
        _activePaymentFlows.remove(jobId);
        return;
      }

      // Reset payment confirmations in database
      await _resetPaymentConfirmations(jobId);

      // Show payment confirmation popups to both users
      await _showPaymentConfirmationToBothUsers(jobId, helpeeId, helperId);

      // Start monitoring for both confirmations
      _startPaymentConfirmationMonitoring(jobId, helpeeId, helperId);
    } catch (e) {
      print('❌ Error starting payment confirmation flow: $e');
      _activePaymentFlows.remove(jobId);
    }
  }

  /// Reset payment confirmations for a job
  Future<void> _resetPaymentConfirmations(String jobId) async {
    try {
      await _supabase.from('jobs').update({
        'helper_payment_confirmation': false,
        'helpee_payment_confirmation': false,
        'payment_confirmation_completed_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      print('✅ Reset payment confirmations for job: $jobId');
    } catch (e) {
      print('❌ Error resetting payment confirmations: $e');
    }
  }

  /// Show payment confirmation popups to both users simultaneously
  Future<void> _showPaymentConfirmationToBothUsers(
      String jobId, String helpeeId, String helperId) async {
    try {
      // Get payment details
      final paymentDetails =
          await CashPaymentService.initiateCashPaymentConfirmation(jobId);

      if (paymentDetails == null || paymentDetails['success'] != true) {
        print('❌ Failed to get payment details for job: $jobId');
        return;
      }

      // Create notifications for both users to trigger payment popups
      // Even if we could not get detailed payment data we still need to notify
      // both parties so they can open the confirmation dialog.
      if (paymentDetails != null && paymentDetails['success'] == true) {
        await _createPaymentConfirmationNotifications(
            jobId, helpeeId, helperId, paymentDetails);
      } else {
        // Use minimal data fallback
        await _createPaymentConfirmationNotifications(
            jobId, helpeeId, helperId, {'payment_amount_calculated': 0.0});
      }

      print('✅ Payment confirmation popups triggered for both users');

      // Show dialog immediately for the current user (no need to wait for notification)
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final currentId = currentUser['user_id'];
        if (currentId == helpeeId) {
          await navigateToPaymentConfirmation(jobId);
        } else if (currentId == helperId) {
          await navigateToPaymentConfirmation(jobId);
        }
      }
    } catch (e) {
      print('❌ Error showing payment confirmation popups: $e');
    }
  }

  /// Create notifications that will trigger payment confirmation popups
  Future<void> _createPaymentConfirmationNotifications(
      String jobId,
      String helpeeId,
      String helperId,
      Map<String, dynamic> paymentDetails) async {
    try {
      final amount = paymentDetails['payment_amount_calculated'] ?? 0.0;
      final formattedAmount = CashPaymentService.formatCurrency(amount);

      // Create notification for helpee
      await _supabase.from('notifications').insert({
        'user_id': helpeeId,
        'title': 'Payment Confirmation Required 💰',
        'message':
            'Please confirm you have paid $formattedAmount in cash to your helper',
        'notification_type': 'payment_confirmation_required',
        'related_job_id': jobId,
        'related_user_id': helperId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create notification for helper
      await _supabase.from('notifications').insert({
        'user_id': helperId,
        'title': 'Payment Confirmation Required 💰',
        'message':
            'Please confirm you have received $formattedAmount in cash from your helpee',
        'notification_type': 'payment_confirmation_required',
        'related_job_id': jobId,
        'related_user_id': helpeeId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Payment confirmation notifications created for both users');
    } catch (e) {
      print('❌ Error creating payment confirmation notifications: $e');
    }
  }

  /// Start monitoring for both payment confirmations
  void _startPaymentConfirmationMonitoring(
      String jobId, String helpeeId, String helperId) {
    try {
      // Cancel any existing listener for this job
      _paymentListeners[jobId]?.cancel();

      // Listen for changes to the jobs table for this specific job
      _paymentListeners[jobId] = _supabase
          .from('jobs')
          .stream(primaryKey: ['id'])
          .eq('id', jobId)
          .listen((data) {
            if (data.isNotEmpty) {
              final jobData = data.first;
              _checkPaymentConfirmationStatus(jobId, jobData);
            }
          });

      print('✅ Started payment confirmation monitoring for job: $jobId');
    } catch (e) {
      print('❌ Error starting payment confirmation monitoring: $e');
    }
  }

  /// Check if both users have confirmed payment
  void _checkPaymentConfirmationStatus(
      String jobId, Map<String, dynamic> jobData) {
    try {
      final helperConfirmed = jobData['helper_payment_confirmation'] == true;
      final helpeeConfirmed = jobData['helpee_payment_confirmation'] == true;

      print(
          '🔍 Payment status for job $jobId: Helper=$helperConfirmed, Helpee=$helpeeConfirmed');

      if (helperConfirmed && helpeeConfirmed) {
        print('🎉 Both users confirmed payment for job: $jobId');
        _onBothUsersConfirmedPayment(jobId, jobData);
      }
    } catch (e) {
      print('❌ Error checking payment confirmation status: $e');
    }
  }

  /// Handle when both users have confirmed payment
  void _onBothUsersConfirmedPayment(
      String jobId, Map<String, dynamic> jobData) async {
    try {
      // Stop monitoring this job
      _paymentListeners[jobId]?.cancel();
      _paymentListeners.remove(jobId);
      _activePaymentFlows.remove(jobId);

      // Update job status to payment_confirmed
      await _supabase.from('jobs').update({
        'status': 'payment_confirmed',
        'payment_confirmation_completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

      // Show job completion popups to both users
      await _showJobCompletionPopupsToBothUsers(jobId, jobData);

      print('✅ Payment confirmation flow completed for job: $jobId');
    } catch (e) {
      print('❌ Error handling both users confirmed payment: $e');
    }
  }

  /// Show job completion popups to both users
  Future<void> _showJobCompletionPopupsToBothUsers(
      String jobId, Map<String, dynamic> jobData) async {
    try {
      final helpeeId = jobData['helpee_id'];
      final helperId = jobData['assigned_helper_id'];
      final jobTitle = jobData['title'] ?? 'Job';

      if (helpeeId != null) {
        // Create job completion notification for helpee
        await _supabase.from('notifications').insert({
          'user_id': helpeeId,
          'title': 'Job Completed Successfully! 🎉',
          'message':
              'Congratulations! You have successfully completed "$jobTitle" and payment has been confirmed.',
          'notification_type': 'job_completion_final',
          'related_job_id': jobId,
          'related_user_id': helperId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (helperId != null) {
        // Create job completion notification for helper
        await _supabase.from('notifications').insert({
          'user_id': helperId,
          'title': 'Job Completed Successfully! 🎉',
          'message':
              'Congratulations! You have successfully completed "$jobTitle" and payment has been confirmed.',
          'notification_type': 'job_completion_final',
          'related_job_id': jobId,
          'related_user_id': helpeeId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Job completion notifications sent to both users');
    } catch (e) {
      print('❌ Error showing job completion popups: $e');
    }
  }

  /// Navigate directly to payment confirmation page (NO POPUP)
  Future<void> navigateToPaymentConfirmation(String jobId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found for payment navigation');
        return;
      }

      final userId = currentUser['user_id'] as String;
      final userType = currentUser['user_type'] as String;

      // Check if user has already visited payment page for this job
      if (_stateService.hasPaymentPageBeenVisited(jobId, userId)) {
        print(
            '⚠️ User $userId has already visited payment page for job: $jobId - skipping navigation');
        return;
      }

      // Mark payment page as visited before navigation
      _stateService.markPaymentPageAsVisited(jobId, userId);

      final context = _navigatorKey?.currentContext;
      if (context == null) {
        print('❌ No context available for payment navigation');
        return;
      }

      print(
          '💳 Navigating to payment confirmation page: $userType for job: $jobId');

      // Navigate to appropriate payment confirmation page based on user type
      if (userType == 'helpee') {
        context.go('/helpee/payment-confirmation/$jobId');
      } else if (userType == 'helper') {
        context.go('/helper/payment-confirmation/$jobId');
      }

      print('✅ Successfully navigated to payment confirmation page');
    } catch (e) {
      print('❌ Error navigating to payment confirmation: $e');
    }
  }

  /// Clean up resources for a specific job
  void cleanupJob(String jobId) {
    _paymentListeners[jobId]?.cancel();
    _paymentListeners.remove(jobId);
    _activePaymentFlows.remove(jobId);
    print('🔄 Cleaned up payment flow for job: $jobId');
  }

  /// Dispose all resources
  void dispose() {
    for (final subscription in _paymentListeners.values) {
      subscription.cancel();
    }
    _paymentListeners.clear();
    _activePaymentFlows.clear();
    print('🔄 PaymentFlowService disposed');
  }

  /// Check if a payment flow is currently active for a specific job
  bool isPaymentFlowActive(String? jobId) {
    if (jobId == null) return false;
    return _activePaymentFlows.contains(jobId);
  }
}
