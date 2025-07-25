import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/webrtc_calling_service.dart';

class IncomingCallPopup extends StatefulWidget {
  final String callerName;
  final String callerId;
  final String conversationId;
  final CallType callType;
  final String callId;
  final Map<String, dynamic>? offer;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onClose;

  const IncomingCallPopup({
    Key? key,
    required this.callerName,
    required this.callerId,
    required this.conversationId,
    required this.callType,
    required this.callId,
    this.offer,
    this.onAccept,
    this.onDecline,
    this.onClose,
  }) : super(key: key);

  @override
  State<IncomingCallPopup> createState() => _IncomingCallPopupState();
}

class _IncomingCallPopupState extends State<IncomingCallPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _ringAnimation;
  bool _isHandlingCall = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    // Create a pulsing ring animation for the incoming call
    _ringAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();

    // Start the ring animation loop
    _startRingAnimation();
  }

  void _startRingAnimation() {
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    if (_isHandlingCall) return;

    setState(() {
      _isHandlingCall = true;
    });

    try {
      // Accept the call through WebRTC service
      final webrtcService = WebRTCService();
      await webrtcService.answerCall(
        callId: widget.callId,
        conversationId: widget.conversationId,
        callerId: widget.callerId,
        offer: widget.offer ?? {},
      );

      // Close popup
      await _animationController.reverse();
      if (widget.onClose != null) widget.onClose!();

      // Navigate to call page
      if (mounted) {
        context.go('/call', extra: {
          'callType': widget.callType == CallType.video ? 'video' : 'audio',
          'isIncoming': true,
          'otherUserName': widget.callerName,
          'conversationId': widget.conversationId,
          'callerId': widget.callerId,
          'callId': widget.callId,
        });
      }

      if (widget.onAccept != null) widget.onAccept!();
    } catch (e) {
      print('❌ Error accepting call: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() {
      _isHandlingCall = false;
    });
  }

  Future<void> _declineCall() async {
    if (_isHandlingCall) return;

    setState(() {
      _isHandlingCall = true;
    });

    try {
      // Decline the call through WebRTC service
      final webrtcService = WebRTCService();
      await webrtcService.rejectCall(widget.callId);

      if (widget.onDecline != null) widget.onDecline!();
    } catch (e) {
      print('❌ Error declining call: $e');
    }

    // Close popup
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();

    setState(() {
      _isHandlingCall = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 340,
                  height: 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Incoming call icon with ring animation
                      Transform.scale(
                        scale: _ringAnimation.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: widget.callType == CallType.video
                                ? AppColors.primaryGreen
                                : Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.callType == CallType.video
                                        ? AppColors.primaryGreen
                                        : Colors.blue)
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.callType == CallType.video
                                ? Icons.videocam
                                : Icons.phone,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Call type title
                      Text(
                        'Incoming ${widget.callType == CallType.video ? 'Video' : 'Audio'} Call',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Caller name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          widget.callerName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 20,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Call description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          widget.callType == CallType.video
                              ? 'wants to start a video call with you'
                              : 'is calling you',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button
                          GestureDetector(
                            onTap: _isHandlingCall ? null : _declineCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _isHandlingCall
                                    ? Colors.grey[400]
                                    : AppColors.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isHandlingCall
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.call_end,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ),
                          ),

                          // Accept button
                          GestureDetector(
                            onTap: _isHandlingCall ? null : _acceptCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _isHandlingCall
                                    ? Colors.grey[400]
                                    : AppColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _isHandlingCall
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Icon(
                                      widget.callType == CallType.video
                                          ? Icons.videocam
                                          : Icons.call,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Instruction text
                      Text(
                        'Tap to answer or decline',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Static method to show incoming call popup
  static void show(
    BuildContext context, {
    required String callerName,
    required String callerId,
    required String conversationId,
    required CallType callType,
    required String callId,
    Map<String, dynamic>? offer,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => IncomingCallPopup(
        callerName: callerName,
        callerId: callerId,
        conversationId: conversationId,
        callType: callType,
        callId: callId,
        offer: offer,
        onAccept: onAccept,
        onDecline: onDecline,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
