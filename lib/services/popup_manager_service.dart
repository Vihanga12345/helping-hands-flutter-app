import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/popups/helpee_popups/helpee_popup_1_account_creation.dart';
import '../widgets/popups/helpee_popups/helpee_popup_2_request_submission.dart';
import '../widgets/popups/helpee_popups/helpee_popup_3_request_accepted.dart';
import '../widgets/popups/helpee_popups/helpee_popup_4_request_rejected.dart';
import '../widgets/popups/helpee_popups/helpee_popup_5_job_started.dart';
import '../widgets/popups/helpee_popups/helpee_popup_6_job_paused.dart';
import '../widgets/popups/helpee_popups/helpee_popup_7_job_resumed.dart';
import '../widgets/popups/helpee_popups/helpee_popup_8_job_completion.dart';
import '../widgets/popups/helpee_popups/helpee_popup_10_job_ending.dart';
import '../widgets/popups/helper_popups/helper_popup_1_account_creation.dart';
import '../widgets/popups/helper_popups/helper_popup_2_private_request.dart';
import '../widgets/popups/helper_popups/helper_popup_3_request_accepted.dart';
import '../widgets/popups/helper_popups/helper_popup_4_request_rejected.dart';
import '../widgets/popups/helper_popups/helper_popup_5_job_started.dart';
import '../widgets/popups/helper_popups/helper_popup_10_job_ending.dart';
import 'custom_auth_service.dart';
import 'popup_state_service.dart';
import 'payment_flow_service.dart';

class PopupManagerService {
  static final PopupManagerService _instance = PopupManagerService._internal();
  factory PopupManagerService() => _instance;
  PopupManagerService._internal();

  final CustomAuthService _authService = CustomAuthService();
  final PopupStateService _stateService = PopupStateService();

  // Track active popup to prevent overlapping
  bool _isPopupActive = false;
  Timer? _popupCleanupTimer;

  // Global navigator key for showing popups
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Show popup based on notification type and user type
  void showPopup({
    required String notificationType,
    required Map<String, dynamic> notificationData,
  }) {
    // Retry popup display if context is not available immediately
    _showPopupWithRetry(notificationType, notificationData, maxRetries: 3);
  }

  void _showPopupWithRetry(
      String notificationType, Map<String, dynamic> notificationData,
      {int maxRetries = 3}) {
    try {
      // Extract jobId for duplicate checking
      final jobId = _extractJobId(notificationData);

      // Check if this popup has already been shown for this job
      if (jobId != null &&
          _stateService.hasPopupBeenShown(jobId, notificationType)) {
        print(
            '⚠️ Popup already shown for job $jobId: $notificationType - skipping duplicate');
        return;
      }

      if (_navigatorKey?.currentContext == null) {
        if (maxRetries > 0) {
          print(
              '⚠️ No context available, retrying in 500ms... (${maxRetries} retries left)');
          Future.delayed(const Duration(milliseconds: 500), () {
            _showPopupWithRetry(notificationType, notificationData,
                maxRetries: maxRetries - 1);
          });
          return;
        } else {
          print('❌ Failed to show popup after retries: No context available');
          return;
        }
      }

      final context = _navigatorKey!.currentContext!;
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('⚠️ No current user found');
        return;
      }

      final userType = currentUser['user_type'];

      print('🔔 Showing popup: $notificationType for user type: $userType');

      // Mark popup as shown before displaying (prevent duplicate during display)
      if (jobId != null) {
        _stateService.markPopupAsShown(jobId, notificationType);
      }

      // Map notification types to appropriate popup widgets
      Widget? popupWidget;

      if (userType == 'helpee') {
        popupWidget = _getHelpeePopup(notificationType, notificationData);
      } else if (userType == 'helper') {
        popupWidget = _getHelperPopup(notificationType, notificationData);
      }

      if (popupWidget != null) {
        // Prevent multiple overlapping popups that can freeze the app
        if (_isPopupActive) {
          print('⚠️ Popup already active, skipping: $notificationType');
          return;
        }

        _isPopupActive = true;

        // Set cleanup timer to ensure popup doesn't block app indefinitely
        _popupCleanupTimer?.cancel();
        _popupCleanupTimer = Timer(const Duration(seconds: 5), () {
          _forceCleanupPopups();
        });

        showDialog(
          context: context,
          barrierDismissible: true, // Allow dismissing to prevent freezing
          barrierColor: Colors.black.withOpacity(0.5), // Standard overlay
          useRootNavigator: true, // Ensure proper positioning
          builder: (BuildContext context) => Material(
            color: Colors.transparent, // Transparent background
            child: Center(
              child: popupWidget!,
            ),
          ),
        ).then((_) {
          // Ensure cleanup when dialog closes
          _isPopupActive = false;
          _popupCleanupTimer?.cancel();
          print('✅ Popup closed and cleaned up: $notificationType');
        });

        print('✅ Popup displayed successfully: $notificationType');
      } else {
        print('⚠️ No popup widget found for: $notificationType');
      }
    } catch (e) {
      print('❌ Error showing popup: $e');
    }
  }

  /// Get appropriate helpee popup widget
  Widget? _getHelpeePopup(String notificationType, Map<String, dynamic> data) {
    switch (notificationType) {
      case 'account_created':
        return HelpeePopup1AccountCreation(
          onClose: () => _closeCurrentPopup(),
        );

      case 'job_created':
      case 'private_job_created':
      case 'public_job_created':
      case 'request_submitted':
        return HelpeePopup2RequestSubmission(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
          isPrivateJob: notificationType == 'private_job_created',
        );

      case 'job_accepted':
        return HelpeePopup3RequestAccepted(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_rejected':
        return HelpeePopup4RequestRejected(
          onClose: () => _closeCurrentPopup(),
        );

      case 'job_started':
        return HelpeePopup5JobStarted(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_paused':
        return HelpeePopup6JobPaused(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_resumed':
        return HelpeePopup7JobResumed(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_completed':
        // Extract jobId from various possible fields
        final jobId = _extractJobId(data);
        print('🔧 Job completion popup - jobId extracted: $jobId');
        print('🔧 Job completion popup - full data: $data');

        return HelpeePopup8JobCompletion(
          jobId: jobId,
          onClose: () {
            // Navigate to payment confirmation using PaymentFlowService (prevents duplicates)
            _closeCurrentPopup();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (jobId != null) {
                print(
                    '🚀 Triggering helpee payment navigation via PaymentFlowService: $jobId');
                PaymentFlowService().navigateToPaymentConfirmation(jobId);
              } else {
                final context = _navigatorKey?.currentContext;
                if (context != null) {
                  print(
                      '⚠️ No jobId found, navigating to helpee home. Data: $data');
                  context.go('/helpee/home');
                }
              }
            });
          },
        );

      case 'job_ending':
        return HelpeePopup10JobEnding(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      default:
        return null;
    }
  }

  /// Get appropriate helper popup widget
  Widget? _getHelperPopup(String notificationType, Map<String, dynamic> data) {
    switch (notificationType) {
      case 'account_created':
        return HelperPopup1AccountCreation(
          onClose: () => _closeCurrentPopup(),
        );

      case 'private_job_request':
      case 'new_job_available':
        return HelperPopup2PrivateRequest(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_created':
      case 'private_job_created':
      case 'public_job_created':
      case 'request_submitted':
        return HelperPopup2PrivateRequest(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_accepted':
        return HelperPopup3RequestAccepted(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_rejected':
        return HelperPopup4RequestRejected(
          onClose: () => _closeCurrentPopup(),
        );

      case 'job_started':
        return HelperPopup5JobStarted(
          onClose: () =>
              _closeCurrentPopupWithNavigation(notificationType, data),
        );

      case 'job_ending':
      case 'job_completed':
        // Extract jobId from various possible fields
        final jobId = _extractJobId(data);
        print('🔧 Helper job completion popup - jobId extracted: $jobId');
        print('🔧 Helper job completion popup - full data: $data');

        return HelperPopup10JobEnding(
          jobId: jobId,
          onClose: () {
            // Navigate to payment confirmation using PaymentFlowService (prevents duplicates)
            _closeCurrentPopup();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (jobId != null) {
                print(
                    '🚀 Triggering helper payment navigation via PaymentFlowService: $jobId');
                PaymentFlowService().navigateToPaymentConfirmation(jobId);
              } else {
                final context = _navigatorKey?.currentContext;
                if (context != null) {
                  print(
                      '⚠️ No jobId found for helper, navigating to home. Data: $data');
                  context.go('/helper/home');
                }
              }
            });
          },
        );

      default:
        return null;
    }
  }

  /// Extract job ID from various possible fields in the data
  String? _extractJobId(Map<String, dynamic> data) {
    // Try multiple possible field names for job ID
    final possibleFields = [
      'id',
      'job_id',
      'jobId',
      'related_job_id',
      'relatedJobId'
    ];

    for (final field in possibleFields) {
      final value = data[field];
      if (value != null) {
        return value.toString();
      }
    }

    print('⚠️ Could not extract jobId from data: $data');
    return null;
  }

  /// Close current popup
  void _closeCurrentPopup() {
    try {
      if (_navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).pop();
        _isPopupActive = false;
        _popupCleanupTimer?.cancel();
      }
    } catch (e) {
      print('⚠️ Error closing popup: $e');
    }
  }

  /// Close current popup and trigger auto-navigation
  void _closeCurrentPopupWithNavigation(
      String notificationType, Map<String, dynamic> data) {
    try {
      if (_navigatorKey?.currentContext != null) {
        Navigator.of(_navigatorKey!.currentContext!).pop();
        _isPopupActive = false;
        _popupCleanupTimer?.cancel();

        // Trigger auto-navigation after popup closes
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleAutoNavigation(notificationType, data);
        });
      }
    } catch (e) {
      print('⚠️ Error closing popup with navigation: $e');
    }
  }

  /// Handle auto-navigation based on job actions
  void _handleAutoNavigation(
      String notificationType, Map<String, dynamic> data) {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || _navigatorKey?.currentContext == null) {
        print('⚠️ Cannot navigate: No user or context available');
        return;
      }

      final userType = currentUser['user_type'];
      final context = _navigatorKey!.currentContext!;
      String? targetRoute;

      // Determine target route based on notification type
      switch (notificationType) {
        case 'job_created':
        case 'private_job_created':
        case 'public_job_created':
        case 'request_submitted':
          // Both helpee and helper should navigate to Activity Pending
          targetRoute = userType == 'helper'
              ? '/helper/activity/pending'
              : '/helpee/activity/pending';
          break;

        case 'job_accepted':
          // Helper accepts job -> Navigate to Activity Ongoing
          targetRoute = userType == 'helper'
              ? '/helper/activity/ongoing'
              : '/helpee/activity/ongoing';
          break;

        case 'job_started':
          // Helper starts job -> Navigate to Activity Ongoing
          targetRoute = userType == 'helper'
              ? '/helper/activity/ongoing'
              : '/helpee/activity/ongoing';
          break;

        case 'job_paused':
          // Helper pauses job -> Navigate to Activity Ongoing
          targetRoute = userType == 'helper'
              ? '/helper/activity/ongoing'
              : '/helpee/activity/ongoing';
          break;

        case 'job_resumed':
          // Helper resumes job -> Navigate to Activity Ongoing
          targetRoute = userType == 'helper'
              ? '/helper/activity/ongoing'
              : '/helpee/activity/ongoing';
          break;

        case 'job_completed':
        case 'job_ending':
          // Helper completes job -> Navigate to Activity Complete
          targetRoute = userType == 'helper'
              ? '/helper/activity/completed'
              : '/helpee/activity/completed';
          break;

        default:
          print('🔄 No auto-navigation defined for: $notificationType');
          return;
      }

      if (targetRoute != null) {
        print('🚀 Auto-navigating to: $targetRoute');
        context.go(targetRoute);
      }
    } catch (e) {
      print('❌ Error handling auto-navigation: $e');
    }
  }

  /// Force cleanup of stuck popups to prevent app freezing
  void _forceCleanupPopups() {
    try {
      print('🔧 Force cleaning up stuck popups...');
      _isPopupActive = false;
      _popupCleanupTimer?.cancel();

      // Try to close any lingering dialogs
      if (_navigatorKey?.currentContext != null) {
        final navigator = Navigator.of(_navigatorKey!.currentContext!);
        if (navigator.canPop()) {
          navigator.pop();
          print('✅ Force closed stuck popup');
        }
      }
    } catch (e) {
      print('⚠️ Error in force cleanup: $e');
      // Reset state even if cleanup fails
      _isPopupActive = false;
    }
  }

  /// Show account creation popup
  void showAccountCreationPopup() {
    showPopup(
      notificationType: 'account_created',
      notificationData: {},
    );
  }

  /// Show job acceptance popup
  void showJobAcceptedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_accepted',
      notificationData: jobData,
    );
  }

  /// Show job rejection popup
  void showJobRejectedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_rejected',
      notificationData: jobData,
    );
  }

  /// Show job started popup
  void showJobStartedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_started',
      notificationData: jobData,
    );
  }

  /// Show job paused popup
  void showJobPausedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_paused',
      notificationData: jobData,
    );
  }

  /// Show job resumed popup
  void showJobResumedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_resumed',
      notificationData: jobData,
    );
  }

  /// Show job completed popup
  void showJobCompletedPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'job_completed',
      notificationData: jobData,
    );
  }

  /// Show new job available popup (for helpers)
  void showNewJobAvailablePopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'new_job_available',
      notificationData: jobData,
    );
  }

  /// Show private job request popup (for helpers)
  void showPrivateJobRequestPopup(Map<String, dynamic> jobData) {
    showPopup(
      notificationType: 'private_job_request',
      notificationData: jobData,
    );
  }

  /// Show job creation popup (for helpees)
  void showJobCreatedPopup(Map<String, dynamic> jobData) {
    // Determine if it's public or private job
    final isPrivate = jobData['job_type'] == 'private' ||
        jobData['is_private'] == true ||
        jobData['invited_helper_email'] != null;

    showPopup(
      notificationType:
          isPrivate ? 'private_job_created' : 'public_job_created',
      notificationData: jobData,
    );
  }

  /// Dispose and cleanup resources
  void dispose() {
    _popupCleanupTimer?.cancel();
    _isPopupActive = false;
    print('🔄 PopupManagerService disposed and cleaned up');
  }
}
