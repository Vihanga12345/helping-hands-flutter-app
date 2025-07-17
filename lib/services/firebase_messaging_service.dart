import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'custom_auth_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;
  final List<Function(RemoteMessage)> _messageHandlers = [];

  /// Initialize Firebase Messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing Firebase Messaging Service...');

      // Skip Firebase initialization on web platform
      if (kIsWeb) {
        print('! Firebase Messaging skipped on web platform');
        _isInitialized = true;
        return;
      }

      // Initialize Firebase Messaging instance for non-web platforms
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getAndStoreFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ Firebase Messaging Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Firebase Messaging Service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      if (_firebaseMessaging == null) return;

      // Request Firebase Messaging permissions
      NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          '📱 Notification permission status: ${settings.authorizationStatus}');

      // Request system notification permissions
      if (!kIsWeb) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  /// Get and store FCM token
  Future<void> _getAndStoreFCMToken() async {
    try {
      if (_firebaseMessaging == null) return;

      _fcmToken = await _firebaseMessaging!.getToken();

      if (_fcmToken != null) {
        print('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');

        // Store token in local storage
        await _storeFCMToken(_fcmToken!);

        // Update token in database for current user
        await _updateUserFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed');
        _fcmToken = newToken;
        _storeFCMToken(newToken);
        _updateUserFCMToken(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Store FCM token locally
  Future<void> _storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('❌ Error storing FCM token locally: $e');
    }
  }

  /// Update user's FCM token in database
  Future<void> _updateUserFCMToken(String token) async {
    try {
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        await SupabaseService().updateUserFCMToken(
          userId: currentUser['user_id'],
          fcmToken: token,
        );
        print('✅ FCM token updated in database');
      }
    } catch (e) {
      print('❌ Error updating FCM token in database: $e');
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    if (_firebaseMessaging == null) return;

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      _handleMessage(message, true);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Background message opened: ${message.messageId}');
      _handleMessage(message, false);
    });

    // Handle messages when app is opened from terminated state
    _firebaseMessaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📨 Terminated state message: ${message.messageId}');
        _handleMessage(message, false);
      }
    });
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message, bool showLocalNotification) {
    try {
      print('📋 Message data: ${message.data}');
      print(
          '📋 Message notification: ${message.notification?.title} - ${message.notification?.body}');

      // Show local notification if app is in foreground
      if (showLocalNotification && message.notification != null) {
        _showLocalNotification(message);
      }

      // Parse notification data
      final notificationData = _parseNotificationData(message);

      // Handle different notification types
      _handleNotificationByType(notificationData);

      // Notify registered handlers
      for (final handler in _messageHandlers) {
        handler(message);
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'helping_hands_high_importance',
        'Helping Hands Notifications',
        channelDescription: 'Important notifications for job activities',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Helping Hands',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Parse notification data from message
  Map<String, dynamic> _parseNotificationData(RemoteMessage message) {
    return {
      'type': message.data['type'] ?? 'general',
      'job_id': message.data['job_id'],
      'user_id': message.data['user_id'],
      'title': message.notification?.title ?? message.data['title'],
      'body': message.notification?.body ?? message.data['body'],
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Handle notifications by type
  void _handleNotificationByType(Map<String, dynamic> notificationData) {
    final type = notificationData['type'];

    switch (type) {
      case 'job_request':
        _handleJobRequestNotification(notificationData);
        break;
      case 'job_accepted':
        _handleJobAcceptedNotification(notificationData);
        break;
      case 'job_rejected':
        _handleJobRejectedNotification(notificationData);
        break;
      case 'job_started':
        _handleJobStartedNotification(notificationData);
        break;
      case 'job_completed':
        _handleJobCompletedNotification(notificationData);
        break;
      case 'payment_received':
        _handlePaymentReceivedNotification(notificationData);
        break;
      case 'rating_received':
        _handleRatingReceivedNotification(notificationData);
        break;
      default:
        print('🔔 General notification: ${notificationData['title']}');
    }
  }

  /// Handle job request notifications
  void _handleJobRequestNotification(Map<String, dynamic> data) {
    print('💼 Job request notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle job accepted notifications
  void _handleJobAcceptedNotification(Map<String, dynamic> data) {
    print('✅ Job accepted notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle job rejected notifications
  void _handleJobRejectedNotification(Map<String, dynamic> data) {
    print('❌ Job rejected notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle job started notifications
  void _handleJobStartedNotification(Map<String, dynamic> data) {
    print('🚀 Job started notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle job completed notifications
  void _handleJobCompletedNotification(Map<String, dynamic> data) {
    print('🎉 Job completed notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle payment received notifications
  void _handlePaymentReceivedNotification(Map<String, dynamic> data) {
    print('💰 Payment received notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle rating received notifications
  void _handleRatingReceivedNotification(Map<String, dynamic> data) {
    print('⭐ Rating received notification for job: ${data['job_id']}');
    // Additional handling logic here
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        print('🔔 Notification tapped with data: $data');

        // Navigate to appropriate screen based on notification type
        _navigateBasedOnNotification(data);
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  /// Navigate to appropriate screen based on notification
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final jobId = data['job_id'];

    // Navigation logic would go here
    // This would typically use a navigation service or global navigator
    print('🧭 Would navigate to: $type screen for job: $jobId');
  }

  /// Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from database
      final userToken = await SupabaseService().getUserFCMToken(userId);

      if (userToken == null) {
        print('❌ No FCM token found for user: $userId');
        return false;
      }

      // Send notification via your backend API or FCM admin SDK
      // This would typically be done through your backend server
      print('📤 Would send notification to user $userId: $title');

      return true;
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      return false;
    }
  }

  /// Subscribe to topic for job category notifications
  Future<void> subscribeToJobCategory(String categoryId) async {
    try {
      if (_firebaseMessaging == null) return;
      await _firebaseMessaging!.subscribeToTopic('job_category_$categoryId');
      print('✅ Subscribed to job category: $categoryId');
    } catch (e) {
      print('❌ Error subscribing to job category: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromJobCategory(String categoryId) async {
    try {
      if (_firebaseMessaging == null) return;
      await _firebaseMessaging!
          .unsubscribeFromTopic('job_category_$categoryId');
      print('✅ Unsubscribed from job category: $categoryId');
    } catch (e) {
      print('❌ Error unsubscribing from job category: $e');
    }
  }

  /// Add message handler
  void addMessageHandler(Function(RemoteMessage) handler) {
    _messageHandlers.add(handler);
  }

  /// Remove message handler
  void removeMessageHandler(Function(RemoteMessage) handler) {
    _messageHandlers.remove(handler);
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Background message handler (must be top-level function)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print('📨 Background message: ${message.messageId}');
    // Handle background message
  }
}
