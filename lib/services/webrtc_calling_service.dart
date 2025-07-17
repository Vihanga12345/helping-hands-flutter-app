import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/localization_service.dart';
import '../services/messaging_service.dart';
import 'dart:async';
import 'dart:convert';

// WebRTC functionality is simulated for web compatibility

enum CallState { idle, calling, connecting, connected, ended, failed }

enum CallType { audio, video }

class WebRTCService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MessagingService _messagingService = MessagingService();

  // Use dynamic for web compatibility
  dynamic _peerConnection;
  dynamic _localStream;
  dynamic _remoteStream;

  // Call state management
  CallState _callState = CallState.idle;
  CallType _callType = CallType.audio;
  String? _currentCallId;
  String? _conversationId;
  String? _callerId;
  String? _receiverId;

  // Real-time signaling
  RealtimeChannel? _signalingChannel;

  // Stream controllers for UI updates
  final StreamController<CallState> _callStateController =
      StreamController<CallState>.broadcast();
  final StreamController<dynamic> _localStreamController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _remoteStreamController =
      StreamController<dynamic>.broadcast();

  // Getters for streams
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<dynamic> get localStreamStream => _localStreamController.stream;
  Stream<dynamic> get remoteStreamStream => _remoteStreamController.stream;

  // Getters for current state
  CallState get callState => _callState;
  CallType get callType => _callType;
  dynamic get localStream => _localStream;
  dynamic get remoteStream => _remoteStream;

  /// Initialize WebRTC service
  Future<void> initialize() async {
    try {
      print('🔥 Initializing WebRTCService');

      // Skip WebRTC initialization on web for now due to compatibility issues
      if (kIsWeb) {
        print('⚠️ WebRTC skipped on web platform');
        return;
      }

      // Request permissions
      await _requestPermissions();

      print('✅ WebRTCService initialized successfully');
    } catch (e) {
      print('❌ Error initializing WebRTCService: $e');
    }
  }

  /// Make an outgoing call
  Future<bool> makeCall({
    required String conversationId,
    required String receiverId,
    required CallType callType,
  }) async {
    try {
      print('🔥 Making $callType call to $receiverId');

      // Skip WebRTC on web for now
      if (kIsWeb) {
        print('⚠️ WebRTC calls not supported on web platform yet');
        return false;
      }

      if (_callState != CallState.idle) {
        print('❌ Cannot make call: already in call state $_callState');
        return false;
      }

      _conversationId = conversationId;
      _receiverId = receiverId;
      _callerId = _supabase.auth.currentUser?.id;
      _callType = callType;

      if (_callerId == null) {
        print('❌ Cannot make call: user not authenticated');
        return false;
      }

      // Update call state
      _updateCallState(CallState.calling);

      // Log the call
      _currentCallId = await _logCall();
      if (_currentCallId == null) {
        _updateCallState(CallState.failed);
        return false;
      }

      // For now, simulate call success on non-web platforms
      await Future.delayed(const Duration(seconds: 2));
      _updateCallState(CallState.connected);

      return true;
    } catch (e) {
      print('❌ Error making call: $e');
      _updateCallState(CallState.failed);
      return false;
    }
  }

  /// Answer an incoming call
  Future<bool> answerCall({
    required String callId,
    required String conversationId,
    required String callerId,
    required Map<String, dynamic> offer,
  }) async {
    try {
      print('🔥 Answering call from $callerId');

      if (_callState != CallState.idle) {
        print('❌ Cannot answer call: already in call state $_callState');
        return false;
      }

      _currentCallId = callId;
      _conversationId = conversationId;
      _callerId = callerId;
      _receiverId = _supabase.auth.currentUser?.id;

      if (_receiverId == null) {
        print('❌ Cannot answer call: user not authenticated');
        return false;
      }

      // Update call state
      _updateCallState(CallState.connecting);

      // Update call status in database
      await _updateCallStatus('answered');

      // Simulate connection
      await Future.delayed(const Duration(seconds: 1));
      _updateCallState(CallState.connected);

      return true;
    } catch (e) {
      print('❌ Error answering call: $e');
      _updateCallState(CallState.failed);
      return false;
    }
  }

  /// Reject an incoming call
  Future<bool> rejectCall(String callId) async {
    try {
      print('🔥 Rejecting call: $callId');

      // Update call status in database
      await _supabase
          .from('call_logs')
          .update({'call_status': 'missed'}).eq('id', callId);

      return true;
    } catch (e) {
      print('❌ Error rejecting call: $e');
      return false;
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      print('🔥 Ending call');

      // Update call status and duration
      if (_currentCallId != null) {
        await _updateCallStatus('ended');
      }

      // Clean up
      await _cleanup();

      _updateCallState(CallState.ended);
    } catch (e) {
      print('❌ Error ending call: $e');
      await _cleanup();
      _updateCallState(CallState.failed);
    }
  }

  /// Toggle mute/unmute
  Future<void> toggleMute() async {
    print('🔇 Toggle mute (simulated)');
  }

  /// Toggle video on/off
  Future<void> toggleVideo() async {
    print('📹 Toggle video (simulated)');
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    print('📷 Switch camera (simulated)');
  }

  /// Log call in database
  Future<String?> _logCall() async {
    try {
      final response = await _supabase.rpc('log_call', params: {
        'p_conversation_id': _conversationId,
        'p_caller_id': _callerId,
        'p_receiver_id': _receiverId,
        'p_call_type': _callType.name,
        'p_webrtc_session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      return response as String;
    } catch (e) {
      print('❌ Error logging call: $e');
      return null;
    }
  }

  /// Update call status in database
  Future<void> _updateCallStatus(String status) async {
    try {
      if (_currentCallId == null) return;

      final updateData = <String, dynamic>{
        'call_status': status,
      };

      if (status == 'ended') {
        updateData['end_time'] = DateTime.now().toIso8601String();
        updateData['duration_seconds'] = 30; // Simulate 30 second call
      }

      await _supabase
          .from('call_logs')
          .update(updateData)
          .eq('id', _currentCallId!);
    } catch (e) {
      print('❌ Error updating call status: $e');
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    try {
      print('🔥 Requesting permissions (simulated)');
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  /// Update call state and notify listeners
  void _updateCallState(CallState newState) {
    _callState = newState;
    _callStateController.add(_callState);
    print('📞 Call state updated: $_callState');
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    try {
      print('🔥 Cleaning up WebRTC resources');

      // Clear streams
      _localStream = null;
      _localStreamController.add(null);

      _remoteStream = null;
      _remoteStreamController.add(null);

      // Unsubscribe from signaling
      await _signalingChannel?.unsubscribe();
      _signalingChannel = null;

      // Reset state
      _currentCallId = null;
      _conversationId = null;
      _callerId = null;
      _receiverId = null;

      print('✅ WebRTC cleanup completed');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  /// Dispose service
  void dispose() {
    print('🔥 Disposing WebRTCService');

    _cleanup();
    _callStateController.close();
    _localStreamController.close();
    _remoteStreamController.close();
  }
}
