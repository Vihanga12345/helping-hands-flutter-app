import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/webrtc_calling_service.dart';

class CallInitiationPopup extends StatefulWidget {
  final String otherUserName;
  final String otherUserId;
  final String conversationId;
  final CallType callType;
  final VoidCallback? onClose;

  const CallInitiationPopup({
    Key? key,
    required this.otherUserName,
    required this.otherUserId,
    required this.conversationId,
    required this.callType,
    this.onClose,
  }) : super(key: key);

  @override
  State<CallInitiationPopup> createState() => _CallInitiationPopupState();
}

class _CallInitiationPopupState extends State<CallInitiationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isInitiatingCall = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initiateCall() async {
    if (_isInitiatingCall) return;

    setState(() {
      _isInitiatingCall = true;
    });

    try {
      final webrtcService = WebRTCService();

      // Initialize and make call
      await webrtcService.initialize();

      final success = await webrtcService.makeCall(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        callType: widget.callType,
      );

      if (!success) {
        throw Exception('Failed to initiate call');
      }

      // Close popup and navigate to call page
      await _animationController.reverse();
      if (widget.onClose != null) widget.onClose!();

      if (mounted) {
        context.go('/call', extra: {
          'callType': widget.callType == CallType.video ? 'video' : 'audio',
          'isIncoming': false,
          'otherUserName': widget.otherUserName,
          'conversationId': widget.conversationId,
          'otherUserId': widget.otherUserId,
        });
      }
    } catch (e) {
      print('❌ Error initiating call: $e');

      // Show error and close popup
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate call: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );

        await _animationController.reverse();
        if (widget.onClose != null) widget.onClose!();
      }
    }

    setState(() {
      _isInitiatingCall = false;
    });
  }

  void _closePopup() async {
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();
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
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 340,
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Call type icon
                      Container(
                        width: 80,
                        height: 80,
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
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.callType == CallType.video
                              ? Icons.videocam
                              : Icons.phone,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Start ${widget.callType == CallType.video ? 'Video' : 'Audio'} Call',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Other user name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'Calling: ${widget.otherUserName}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Call description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          widget.callType == CallType.video
                              ? 'Start a video call to see and talk with ${widget.otherUserName}'
                              : 'Start an audio call to talk with ${widget.otherUserName}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Cancel button
                          GestureDetector(
                            onTap: _isInitiatingCall ? null : _closePopup,
                            child: Container(
                              width: 120,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Call button
                          GestureDetector(
                            onTap: _isInitiatingCall ? null : _initiateCall,
                            child: Container(
                              width: 120,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _isInitiatingCall
                                    ? Colors.grey[400]
                                    : (widget.callType == CallType.video
                                        ? AppColors.primaryGreen
                                        : Colors.blue),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.callType == CallType.video
                                            ? AppColors.primaryGreen
                                            : Colors.blue)
                                        .withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isInitiatingCall
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
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            widget.callType == CallType.video
                                                ? Icons.videocam
                                                : Icons.phone,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Call',
                                            style: AppTextStyles.buttonMedium
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
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

  /// Static method to show call initiation popup
  static void show(
    BuildContext context, {
    required String otherUserName,
    required String otherUserId,
    required String conversationId,
    required CallType callType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => CallInitiationPopup(
        otherUserName: otherUserName,
        otherUserId: otherUserId,
        conversationId: conversationId,
        callType: callType,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
