import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'messaging_service.dart';

enum CallType { audio, video }

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final MessagingService _messagingService = MessagingService();
  bool _isInitialized = false;

  // Global navigator key for navigation
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      print('⚠️ WebRTC skipped on web platform');
      _isInitialized = false;
      return;
    }

    try {
      print('🔥 Initializing WebRTCService');
      _isInitialized = true;
      print('✅ WebRTC Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize WebRTC Service: $e');
      _isInitialized = false;
    }
  }

  Future<void> makeCall(String receiverId, CallType callType) async {
    print('🔥 Making ${callType.name} call to $receiverId');

    if (kIsWeb) {
      print('⚠️ WebRTC calls not supported on web platform yet');
      _showWebCallNotSupported();
      return;
    }

    if (!_isInitialized) {
      print('❌ WebRTC Service not initialized');
      return;
    }

    try {
      // Create conversation for the call with proper parameters
      final conversationId = await _messagingService.getOrCreateConversation(
        jobId: '00000000-0000-0000-0000-000000000000', // placeholder job id
        helperId: receiverId,
        helpeeId:
            receiverId, // This would need proper logic to determine helper/helpee
      );

      final context = _navigatorKey?.currentContext;
      if (context != null) {
        context.push('/call', extra: {
          'conversationId': conversationId,
          'receiverId': receiverId,
          'callType': callType.name,
          'isIncoming': false,
        });
      }
    } catch (e) {
      print('❌ Failed to make call: $e');
    }
  }

  void _showWebCallNotSupported() {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice calls are not available on web. Please use the mobile app for calling.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> answerCall(String callId) async {
    if (kIsWeb) {
      _showWebCallNotSupported();
      return;
    }

    if (!_isInitialized) {
      print('❌ WebRTC Service not initialized');
      return;
    }

    try {
      print('📞 Answering call: $callId');
      // Implementation for answering calls
    } catch (e) {
      print('❌ Failed to answer call: $e');
    }
  }

  Future<void> endCall(String callId) async {
    if (kIsWeb) {
      return;
    }

    try {
      print('📞 Ending call: $callId');
      // Implementation for ending calls
    } catch (e) {
      print('❌ Failed to end call: $e');
    }
  }

  void dispose() {
    print('🔥 Disposing WebRTC Service');
    _isInitialized = false;
  }
}
