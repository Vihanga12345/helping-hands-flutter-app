import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/custom_auth_service.dart';

class MessageNotificationPopup extends StatefulWidget {
  final String senderName;
  final String messageText;
  final String conversationId;
  final String? senderImageUrl;
  final VoidCallback? onClose;

  const MessageNotificationPopup({
    Key? key,
    required this.senderName,
    required this.messageText,
    required this.conversationId,
    this.senderImageUrl,
    this.onClose,
  }) : super(key: key);

  @override
  State<MessageNotificationPopup> createState() =>
      _MessageNotificationPopupState();
}

class _MessageNotificationPopupState extends State<MessageNotificationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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

    // Auto-dismiss after 3 seconds and navigate to chat
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _closeAndNavigateToChat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeAndNavigateToChat() async {
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();

    // Navigate to chat page
    if (mounted) {
      _navigateToChat();
    }
  }

  void _navigateToChat() {
    try {
      final authService = CustomAuthService();
      final currentUser = authService.currentUser;

      if (currentUser != null && mounted) {
        // Navigate to chat with conversation data
        context.go('/chat', extra: {
          'conversationId': widget.conversationId,
          'otherUserName': widget.senderName,
        });

        print('✅ Navigated to chat from message notification');
      }
    } catch (e) {
      print('❌ Error navigating to chat from notification: $e');
    }
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
                child: GestureDetector(
                  onTap: _closeAndNavigateToChat,
                  child: Container(
                    width: 340,
                    height: 320,
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
                        // Message icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'New Message',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sender name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'From: ${widget.senderName}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Message preview
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.messageText.length > 60
                                  ? '${widget.messageText.substring(0, 60)}...'
                                  : widget.messageText,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tap to open indicator
                        Text(
                          'Tap to open chat',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Progress indicator
                        Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _animationController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Static method to show message popup
  static void show(
    BuildContext context, {
    required String senderName,
    required String messageText,
    required String conversationId,
    String? senderImageUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) => MessageNotificationPopup(
        senderName: senderName,
        messageText: messageText,
        conversationId: conversationId,
        senderImageUrl: senderImageUrl,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
