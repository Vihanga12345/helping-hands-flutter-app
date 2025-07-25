import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

enum NotificationStyle {
  success,
  error,
  warning,
  info,
}

class CenterNotificationPopup extends StatefulWidget {
  final String message;
  final NotificationStyle style;
  final Duration duration;
  final VoidCallback? onClose;
  final IconData? customIcon;

  const CenterNotificationPopup({
    Key? key,
    required this.message,
    this.style = NotificationStyle.info,
    this.duration = const Duration(seconds: 2),
    this.onClose,
    this.customIcon,
  }) : super(key: key);

  @override
  State<CenterNotificationPopup> createState() =>
      _CenterNotificationPopupState();

  /// Show notification popup
  static void show(
    BuildContext context, {
    required String message,
    NotificationStyle style = NotificationStyle.info,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onClose,
    IconData? customIcon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) => CenterNotificationPopup(
        message: message,
        style: style,
        duration: duration,
        onClose: onClose ?? () => Navigator.of(context).pop(),
        customIcon: customIcon,
      ),
    );
  }
}

class _CenterNotificationPopupState extends State<CenterNotificationPopup>
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

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start animation
    _animationController.forward();

    // Auto-close after specified duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _closeWithAnimation();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeWithAnimation() {
    _animationController.reverse().then((_) {
      if (mounted && widget.onClose != null) {
        widget.onClose!();
      }
    });
  }

  Color _getBackgroundColor() {
    switch (widget.style) {
      case NotificationStyle.success:
        return AppColors.success;
      case NotificationStyle.error:
        return AppColors.error;
      case NotificationStyle.warning:
        return AppColors.warning;
      case NotificationStyle.info:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    if (widget.customIcon != null) {
      return widget.customIcon!;
    }

    switch (widget.style) {
      case NotificationStyle.success:
        return Icons.check_circle;
      case NotificationStyle.error:
        return Icons.error;
      case NotificationStyle.warning:
        return Icons.warning;
      case NotificationStyle.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 340,
                    minWidth: 280,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with colored background
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getBackgroundColor().withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(),
                          color: _getBackgroundColor(),
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message text
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Close button
                      GestureDetector(
                        onTap: _closeWithAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: _getBackgroundColor().withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }
}
