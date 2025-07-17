import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../widgets/popups/message_notification_popup.dart';
import 'custom_auth_service.dart';
import 'popup_manager_service.dart';
import 'payment_flow_service.dart';

class RealTimeNotificationService {
  static final RealTimeNotificationService _instance =
      RealTimeNotificationService._internal();
  factory RealTimeNotificationService() => _instance;
  RealTimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();
  final PopupManagerService _popupService = PopupManagerService();
  final PaymentFlowService _paymentFlowService = PaymentFlowService();

  // Current user state
  String? _currentUserId;
  String? _currentUserType;
  BuildContext? _context;
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Subscription channels
  RealtimeChannel? _jobStatusChannel;
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _messageChannel;

  // Add streams for backward compatibility with other services
  final StreamController<Map<String, dynamic>> _jobUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams for listening to real-time updates (for backward compatibility)
  Stream<Map<String, dynamic>> get jobUpdateStream =>
      _jobUpdateController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Set global navigator key for navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    print('✅ Navigator key set for RealTimeNotificationService');
  }

  /// Get current context from navigator key or stored context
  BuildContext? get _currentContext {
    if (_navigatorKey?.currentContext != null) {
      return _navigatorKey!.currentContext;
    }
    return _context;
  }

  /// Initialize notification service with user context
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      print('⚠️ Real-time notification service already initialized');
      return;
    }

    try {
      _context = context;

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('⚠️ Cannot initialize notifications - no user logged in');
        return;
      }

      _currentUserId = currentUser['user_id'];
      _currentUserType = currentUser['user_type'];

      print(
          '🔔 Initializing Real-Time Notification Service for user: $_currentUserId ($_currentUserType)');

      // Setup all subscriptions
      await _setupJobStatusSubscription();
      await _setupNotificationSubscription();
      await _setupMessageSubscription();

      _isInitialized = true;
      print('✅ Real-Time Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Real-Time Notification Service: $e');
    }
  }

  /// Setup job status subscription
  Future<void> _setupJobStatusSubscription() async {
    try {
      _jobStatusChannel = _supabase
          .channel('job_status_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'jobs',
            callback: (payload) => _handleJobStatusChange(payload),
          )
          .subscribe();

      print('✅ Job status subscription setup complete');
    } catch (e) {
      print('❌ Error setting up job subscription: $e');
    }
  }

  /// Setup general notification subscription
  Future<void> _setupNotificationSubscription() async {
    try {
      _notificationChannel = _supabase
          .channel('user_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) => _handleNewNotification(payload),
          )
          .subscribe();

      print('✅ Notification subscription setup complete');
    } catch (e) {
      print('❌ Error setting up notification subscription: $e');
    }
  }

  /// Setup message subscription for real-time message notifications
  Future<void> _setupMessageSubscription() async {
    try {
      print(
          '🔔 Setting up message notification subscription for user: $_currentUserId');

      _messageChannel = _supabase
          .channel('messages_realtime_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              print(
                  '🔔 MESSAGE SUBSCRIPTION TRIGGERED! Payload: ${payload.newRecord}');
              _handleNewMessage(payload);
            },
          )
          .subscribe();

      print('✅ Message notification subscription setup complete');
    } catch (e) {
      print('❌ Error setting up message subscription: $e');
    }
  }

  /// Handle new incoming messages and show notifications
  Future<void> _handleNewMessage(PostgresChangePayload payload) async {
    try {
      final messageData = payload.newRecord;
      final senderId = messageData['sender_id'] as String?;
      final conversationId = messageData['conversation_id'] as String?;
      final messageText = messageData['message_text'] as String?;

      print(
          '📩 Processing new message: senderId=$senderId, conversationId=$conversationId');

      // Don't show notification for our own messages
      if (senderId == _currentUserId) {
        print('🔔 Skipping notification for own message');
        return;
      }

      // Check if the current user is part of this conversation
      final isUserInConversation =
          await _checkUserInConversation(conversationId);
      if (!isUserInConversation) {
        print(
            '🔔 User not in conversation $conversationId, skipping notification');
        return;
      }

      // Get sender information for the popup
      final senderInfo = await _getSenderInfo(senderId);
      if (senderInfo == null) {
        print('🔔 Could not get sender info for message notification');
        return;
      }

      final senderName =
          '${senderInfo['first_name']} ${senderInfo['last_name']}';

      print('🔔 Showing message notification for: $senderName -> $messageText');

      // Show message popup notification
      final context = _currentContext;
      if (context != null && messageText != null) {
        _showMessagePopup(context, senderName, messageText, conversationId!,
            senderInfo['profile_image_url']);
      }
    } catch (e) {
      print('❌ Error handling new message: $e');
    }
  }

  /// Show a popup notification for new messages
  void _showMessagePopup(BuildContext context, String senderName,
      String messageText, String conversationId, String? senderImageUrl) {
    try {
      MessageNotificationPopup.show(
        context,
        senderName: senderName,
        messageText: messageText,
        conversationId: conversationId,
        senderImageUrl: senderImageUrl,
      );
      print('✅ Message popup shown for $senderName');
    } catch (e) {
      print('❌ Error showing message popup: $e');
    }
  }

  /// Check if current user is part of the conversation
  Future<bool> _checkUserInConversation(String? conversationId) async {
    if (conversationId == null || _currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .eq('user_id', _currentUserId!)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking user in conversation: $e');
      return false;
    }
  }

  /// Get sender information
  Future<Map<String, dynamic>?> _getSenderInfo(String? senderId) async {
    if (senderId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('first_name, last_name, profile_image_url')
          .eq('user_id', senderId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error getting sender info: $e');
      return null;
    }
  }

  /// Test method for debugging message notifications
  void triggerTestMessageNotification() {
    print('🧪 Test notification triggered from service');

    final context = _currentContext;
    if (context != null) {
      // Show a test popup notification
      _showMessagePopup(context, 'Test User',
          'This is a test message notification.', 'test-conversation', null);
      print('🧪 Test message notification popup shown');
    } else {
      print('🧪 No context available for test notification');
    }
  }

  /// Handle job status changes and show appropriate popups
  Future<void> _handleJobStatusChange(PostgresChangePayload payload) async {
    try {
      final oldRecord = payload.oldRecord;
      final newRecord = payload.newRecord;

      if (newRecord == null) return;

      // For new records (oldRecord is null), we need to check if it's a real status change
      // or just initial data load
      final oldStatus = oldRecord?['status'] as String?;
      final newStatus = newRecord['status'] as String?;
      final helpeeId = newRecord['helpee_id'] as String?;
      final helperId = newRecord['assigned_helper_id'] as String?;
      final jobId = newRecord['id'] as String?;

      // Only show notifications for jobs involving current user
      if (_currentUserId != helpeeId && _currentUserId != helperId) {
        return;
      }

      print(
          '🔔 Job status changed from $oldStatus to $newStatus for user $_currentUserId (job: $jobId)');

      // Broadcast job update for other services
      _jobUpdateController.add(newRecord);

      // Handle status changes - be more permissive about detecting transitions
      if (newStatus != null) {
        // If oldStatus is null, we still want to handle certain new statuses
        if (oldStatus == null) {
          // Handle new job states when oldStatus is null
          await _handleJobStatusTransition(null, newStatus, newRecord);
        } else if (oldStatus != newStatus) {
          // Handle normal status transitions
          await _handleJobStatusTransition(oldStatus, newStatus, newRecord);
        }
      }
    } catch (e) {
      print('❌ Error handling job status change: $e');
    }
  }

  /// Handle specific job status transitions
  Future<void> _handleJobStatusTransition(
      String? oldStatus, String newStatus, Map<String, dynamic> jobData) async {
    try {
      final jobId = jobData['id'] as String?;

      print(
          '🔄 Handling job status transition: $oldStatus -> $newStatus for job: $jobId');

      switch (newStatus) {
        case 'pending':
          if (oldStatus == null || oldStatus == 'draft') {
            // Job was just created/published
            print('📝 Job created/published - showing popup');
            _popupService.showJobCreatedPopup(jobData);
          }
        break;

          case 'accepted':
          if (oldStatus == 'pending' || oldStatus == null) {
            // Job was accepted by helper
            print('✅ Job accepted - showing popup');
            _popupService.showJobAcceptedPopup(jobData);
          }
          break;

        case 'rejected':
          if (oldStatus == 'pending' || oldStatus == null) {
            // Job was rejected by helper
            print('❌ Job rejected - showing popup');
            _popupService.showJobRejectedPopup(jobData);
          }
            break;

          case 'started':
        case 'ongoing':
          if (oldStatus == 'accepted' ||
              oldStatus == 'pending' ||
              oldStatus == null) {
            // Job was started by helper
            print('🚀 Job started - showing popup');
            _popupService.showJobStartedPopup(jobData);
          }
            break;

          case 'paused':
          if (oldStatus == 'started' || oldStatus == 'ongoing') {
            // Job was paused by helper
            print('⏸️ Job paused - showing popup');
            _popupService.showJobPausedPopup(jobData);
          }
            break;

          case 'resumed':
          if (oldStatus == 'paused') {
            // Job was resumed by helper
            print('▶️ Job resumed - showing popup');
            _popupService.showJobResumedPopup(jobData);
          }
            break;

          case 'completed':
          if (oldStatus == 'started' ||
              oldStatus == 'ongoing' ||
              oldStatus == 'resumed' ||
              oldStatus == null) {
            // Job was completed - start payment flow
            print(
                '🎉 Job completed - showing popup and starting payment flow...');
            _popupService.showJobCompletedPopup(jobData);

            // Start payment confirmation flow after a short delay
            if (jobId != null) {
              Future.delayed(const Duration(milliseconds: 3000), () {
                print('💰 Starting payment confirmation flow for job: $jobId');
                _paymentFlowService.startPaymentConfirmationFlow(jobId);
              });
            }
          }
            break;

        case 'payment_confirmed':
          // Both users confirmed payment - navigate to rating
          print('💳 Payment confirmed, navigating to rating...');
          await _navigateToRating(jobId);
            break;
        }
    } catch (e) {
      print('❌ Error handling job status transition: $e');
    }
  }

  /// Navigate user to rating page after payment confirmation
  Future<void> _navigateToRating(String? jobId) async {
    try {
      if (jobId == null ||
          _currentContext == null ||
          _currentUserType == null) {
        print('⚠️ Cannot navigate to rating: missing data');
        return;
      }

      // Navigate to appropriate rating page based on user type
      String ratingRoute;
      if (_currentUserType == 'helpee') {
        ratingRoute = '/helpee/rating/$jobId';
      } else if (_currentUserType == 'helper') {
        ratingRoute = '/helper/rating/$jobId';
      } else {
        print('⚠️ Unknown user type for rating navigation: $_currentUserType');
        return;
      }

      // Navigate after a short delay to allow popup to close
      Future.delayed(const Duration(milliseconds: 1000), () {
        final context = _currentContext;
        if (context != null && context.mounted) {
          print('🚀 Navigating to rating page: $ratingRoute');
          context.go(ratingRoute);
        }
      });
    } catch (e) {
      print('❌ Error navigating to rating: $e');
    }
  }

  /// Handle general notifications
  Future<void> _handleNewNotification(PostgresChangePayload payload) async {
    try {
      final notificationData = payload.newRecord;
      final userId = notificationData['user_id'] as String?;
      final notificationType = notificationData['notification_type'] as String?;

      // Only handle notifications for current user
      if (userId != _currentUserId) return;

      print('🔔 New notification: $notificationType for user $userId');

      // Broadcast notification for other services
      _notificationController.add(notificationData);

      // Handle specific notification types that should trigger popups
      if (notificationType != null) {
        await _handleSpecificNotification(notificationType, notificationData);
      }
    } catch (e) {
      print('❌ Error handling notification: $e');
    }
  }

  /// Handle specific notification types
  Future<void> _handleSpecificNotification(
      String notificationType, Map<String, dynamic> notificationData) async {
    try {
      switch (notificationType) {
        case 'payment_confirmation_required':
          // Navigate to payment confirmation page (no popup)
          final jobId = notificationData['related_job_id'] as String?;
          if (jobId != null) {
            await _paymentFlowService.navigateToPaymentConfirmation(jobId);
          }
          break;

        case 'job_completion_final':
          // Job fully completed with payment confirmed - show completion message
          print('🎉 Job completion final notification received');
          break;

        default:
          print('📝 Unhandled notification type: $notificationType');
          break;
      }
    } catch (e) {
      print('❌ Error handling specific notification: $e');
    }
  }

  /// Create notification in database (for backward compatibility)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String notificationType,
    String? relatedJobId,
    String? relatedUserId,
    String? actionUrl,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'notification_type': notificationType,
        'related_job_id': relatedJobId,
        'related_user_id': relatedUserId,
        'action_url': actionUrl,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Notification created in database');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Dispose of all subscriptions and clean up
  void dispose() {
    print('🔔 Disposing Real-Time Notification Service');

    _jobStatusChannel?.unsubscribe();
    _notificationChannel?.unsubscribe();
    _messageChannel?.unsubscribe();

    _jobUpdateController.close();
    _notificationController.close();

    _jobStatusChannel = null;
    _notificationChannel = null;
    _messageChannel = null;

    _currentUserId = null;
    _currentUserType = null;
    _context = null;
    _isInitialized = false;

    print('✅ Real-Time Notification Service disposed');
  }

  /// Reinitialize for new user (when user logs in/out)
  Future<void> reinitialize(BuildContext context) async {
    dispose();
    await initialize(context);
  }
}
