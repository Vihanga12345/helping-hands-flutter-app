import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'localization_service.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  String? _currentToken;
  Timer? _tokenRefreshTimer;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Configure notification channels for Android
      await _configureAndroidChannel();

      // Get the token and store it
      await _updateToken();

      // Set up token refresh timer (every 6 hours)
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = Timer.periodic(
        const Duration(hours: 6),
        (_) => _updateToken(),
      );

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      print('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
      rethrow;
    }
  }

  // Configure Android notification channel
  Future<void> _configureAndroidChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'helping_hands_notifications',
      'Helping Hands Notifications',
      description: 'Notifications from Helping Hands app',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: AppColors.primaryGreen,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Update FCM token
  Future<void> _updateToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        print('❌ Failed to get FCM token');
        return;
      }

      if (token == _currentToken) return;
      _currentToken = token;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Store token in database
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'device_info': 'Flutter Web',
        'is_active': true,
        'last_used': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');

      print('✅ FCM token updated successfully');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Received foreground message: ${message.messageId}');

    try {
      // Get user's language preference
      final userLanguage = LocalizationService().currentLanguage;

      // Extract notification data
      final notification = message.notification;
      final data = message.data;

      if (notification == null) return;

      // Show local notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'helping_hands_notifications',
            'Helping Hands Notifications',
            channelDescription: 'Notifications from Helping Hands app',
            importance: Importance.max,
            priority: Priority.high,
            color: AppColors.primaryGreen,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(data),
      );

      // Update notification as read in database if it has an ID
      if (data.containsKey('notification_id')) {
        await _supabase.from('notification_history').update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('id', data['notification_id']);
      }
    } catch (e) {
      print('❌ Error handling foreground message: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload == null) return;

      final data = json.decode(response.payload!);
      _handleNotificationAction(data);
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  // Handle notification tap when app was in background
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      _handleNotificationAction(message.data);
    } catch (e) {
      print('❌ Error handling background message tap: $e');
    }
  }

  // Handle notification actions
  void _handleNotificationAction(Map<String, dynamic> data) {
    try {
      // Navigate based on notification type
      if (data.containsKey('job_id')) {
        // TODO: Navigate to job details page
        print('🔄 Navigate to job ${data['job_id']}');
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _isInitialized = false;
  }
}

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Received background message: ${message.messageId}');

  // Initialize Firebase if needed
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Show local notification
  final notification = message.notification;
  if (notification != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'helping_hands_notifications',
          'Helping Hands Notifications',
          channelDescription: 'Notifications from Helping Hands app',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.data),
    );
  }
}
