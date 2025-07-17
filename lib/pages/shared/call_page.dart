import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/webrtc_calling_service.dart';
import '../../services/localization_service.dart';
import 'dart:async';

class CallPage extends StatefulWidget {
  final CallType callType;
  final bool isIncoming;
  final String? otherUserName;
  final String? callId;
  final String? conversationId;
  final String? callerId;
  final Map<String, dynamic>? offer;

  const CallPage({
    super.key,
    required this.callType,
    required this.isIncoming,
    this.otherUserName,
    this.callId,
    this.conversationId,
    this.callerId,
    this.offer,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final WebRTCService _webrtcService = WebRTCService();

  CallState _callState = CallState.idle;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _localStreamSubscription;
  StreamSubscription? _remoteStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _callStateSubscription?.cancel();
    _localStreamSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    try {
      // Subscribe to call state changes
      _callStateSubscription = _webrtcService.callStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _callState = state;
          });

          // Handle call end
          if (state == CallState.ended || state == CallState.failed) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) context.pop();
            });
          }
        }
      });

      // Handle incoming call
      if (widget.isIncoming && widget.callId != null) {
        setState(() {
          _callState = CallState.calling;
        });
      }

      print('✅ Call page initialized');
    } catch (e) {
      print('❌ Error initializing call: $e');
      if (mounted) context.pop();
    }
  }

  Future<void> _answerCall() async {
    if (widget.callId != null &&
        widget.conversationId != null &&
        widget.callerId != null &&
        widget.offer != null) {
      final success = await _webrtcService.answerCall(
        callId: widget.callId!,
        conversationId: widget.conversationId!,
        callerId: widget.callerId!,
        offer: widget.offer!,
      );

      if (!success && mounted) {
        context.pop();
      }
    }
  }

  Future<void> _rejectCall() async {
    if (widget.callId != null) {
      await _webrtcService.rejectCall(widget.callId!);
    }
    if (mounted) context.pop();
  }

  Future<void> _endCall() async {
    await _webrtcService.endCall();
  }

  Future<void> _toggleMute() async {
    await _webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleVideo() async {
    if (widget.callType == CallType.video) {
      await _webrtcService.toggleVideo();
      setState(() {
        _isVideoEnabled = !_isVideoEnabled;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.callType == CallType.video) {
      await _webrtcService.switchCamera();
    }
  }

  String _getCallStateText() {
    switch (_callState) {
      case CallState.calling:
        return widget.isIncoming ? 'Incoming call...'.tr() : 'Calling...'.tr();
      case CallState.connecting:
        return 'Connecting...'.tr();
      case CallState.connected:
        return 'Connected'.tr();
      case CallState.ended:
        return 'Call ended'.tr();
      case CallState.failed:
        return 'Call failed'.tr();
      default:
        return 'Call'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Call info and video area
            Expanded(
              child: _buildCallContent(),
            ),

            // Call controls
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallContent() {
    return _buildAudioCallContent(); // Always show audio call UI for now
  }

  Widget _buildAudioCallContent() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User avatar
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(75),
              border: Border.all(color: AppColors.white, width: 4),
            ),
            child: const Icon(
              Icons.person,
              size: 80,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 32),

          // User name
          Text(
            widget.otherUserName ?? 'Unknown User'.tr(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Call state
          Text(
            _getCallStateText(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Call type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.callType == CallType.video
                      ? Icons.videocam
                      : Icons.call,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.callType == CallType.video
                      ? 'Video Call'.tr()
                      : 'Audio Call'.tr(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    if (widget.isIncoming && _callState == CallState.calling) {
      return _buildIncomingCallControls();
    } else {
      return _buildActiveCallControls();
    }
  }

  Widget _buildIncomingCallControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject button
          _buildControlButton(
            icon: Icons.call_end,
            color: AppColors.error,
            onPressed: _rejectCall,
            label: 'Reject'.tr(),
          ),

          // Answer button
          _buildControlButton(
            icon: Icons.call,
            color: AppColors.success,
            onPressed: _answerCall,
            label: 'Answer'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? AppColors.error : AppColors.white,
            onPressed: _toggleMute,
            isSelected: _isMuted,
          ),

          // Video toggle (only for video calls)
          if (widget.callType == CallType.video)
            _buildControlButton(
              icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              color: _isVideoEnabled ? AppColors.white : AppColors.error,
              onPressed: _toggleVideo,
              isSelected: !_isVideoEnabled,
            ),

          // Switch camera (only for video calls)
          if (widget.callType == CallType.video)
            _buildControlButton(
              icon: Icons.switch_camera,
              color: AppColors.white,
              onPressed: _switchCamera,
            ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: AppColors.error,
            onPressed: _endCall,
            size: 65,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? label,
    bool isSelected = false,
    double size = 55,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: color,
              size: size * 0.4,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
