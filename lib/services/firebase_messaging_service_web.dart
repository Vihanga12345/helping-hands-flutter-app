// Web-specific Firebase Messaging Service (No-op implementation)
// This prevents Firebase errors on web platform

import 'dart:async';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  bool _isInitialized = false;
  String? _fcmToken;
  final List<Function(Map<String, dynamic>)> _messageHandlers = [];

  // Web stub methods - do nothing
  Future<void> initialize() async {
    if (_isInitialized) return;
    print('⚠️ Firebase Messaging Service skipped on web platform');
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    print('⚠️ Firebase permissions skipped on web platform');
  }

  String? get fcmToken => null;

  Future<void> subscribeToJobCategory(String categoryId) async {
    print('⚠️ Firebase topic subscription skipped on web platform');
  }

  Future<void> unsubscribeFromJobCategory(String categoryId) async {
    print('⚠️ Firebase topic unsubscription skipped on web platform');
  }

  void addMessageHandler(Function(Map<String, dynamic>) handler) {
    // Do nothing on web
  }

  void removeMessageHandler(Function(Map<String, dynamic>) handler) {
    // Do nothing on web
  }

  Future<void> sendNotification(String token, String title, String body,
      {Map<String, dynamic>? data}) async {
    print('⚠️ Firebase notification sending skipped on web platform');
  }

  Future<void> sendBulkNotification(List<String> tokens, String title,
      String body, {Map<String, dynamic>? data}) async {
    print('⚠️ Firebase bulk notification sending skipped on web platform');
  }

  Future<void> sendTopicNotification(String topic, String title, String body,
      {Map<String, dynamic>? data}) async {
    print('⚠️ Firebase topic notification sending skipped on web platform');
  }

  Future<void> updateUserFCMToken(String userId, String? token) async {
    print('⚠️ Firebase token update skipped on web platform');
  }

  void dispose() {
    // Do nothing on web
  }
} 