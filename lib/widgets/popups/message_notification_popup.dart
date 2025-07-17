import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/localization_service.dart';

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

  // Static show method for displaying the popup
  static void show(
    BuildContext context, {
    required String senderName,
    required String messageText,
    required String conversationId,
    String? senderImageUrl,
  }) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => MessageNotificationPopup(
        senderName: senderName,
        messageText: messageText,
        conversationId: conversationId,
        senderImageUrl: senderImageUrl,
        onClose: () {
          overlayEntry?.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

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
        duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    // Auto close after 4 seconds and navigate to chat
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _navigateToChat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closePopup() async {
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();
  }

  void _navigateToChat() async {
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();

    // Navigate to chat page
    if (mounted) {
      context.push('/chat', extra: {
        'conversationId': widget.conversationId,
        'otherUserName': widget.senderName,
      });
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
                  onTap: _navigateToChat,
                  child: Container(
                    width: 340,
                    height: 295,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 2)
                        ]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile image or message icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                    spreadRadius: 2)
                              ]),
                          child: widget.senderImageUrl != null &&
                                  widget.senderImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    widget.senderImageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.message,
                                                color: Colors.white, size: 40),
                                  ),
                                )
                              : const Icon(Icons.message,
                                  color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 20),

                        // Sender name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'New Message from'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            widget.senderName,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading3.copyWith(
                                fontSize: 20,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Message preview
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.messageText.length > 50
                                ? '${widget.messageText.substring(0, 47)}...'
                                : widget.messageText,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tap to open chat hint
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Tap to open chat'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Progress bar
                        Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _animationController.value,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(2))),
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
}
