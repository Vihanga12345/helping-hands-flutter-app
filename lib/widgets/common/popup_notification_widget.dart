import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class PopupNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String notificationType;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const PopupNotificationWidget({
    super.key,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<PopupNotificationWidget> createState() =>
      _PopupNotificationWidgetState();
}

class _PopupNotificationWidgetState extends State<PopupNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Auto-dismiss after 2 seconds (as per requirement)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  Color _getNotificationColor() {
    switch (widget.notificationType) {
      case 'job_accepted':
      case 'job_started':
      case 'job_resumed':
      case 'payment_received':
        return AppColors.success;
      case 'job_rejected':
        return AppColors.error;
      case 'job_completed':
        return AppColors.primaryGreen;
      case 'job_paused':
        return AppColors.warning;
      case 'new_job_available':
        return Colors.blue;
      case 'private_job_request':
        return Colors.purple;
      case 'job_created':
        return AppColors.primaryGreen;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getNotificationIcon() {
    switch (widget.notificationType) {
      case 'job_accepted':
        return Icons.check_circle;
      case 'job_rejected':
        return Icons.cancel;
      case 'job_started':
        return Icons.play_circle;
      case 'job_paused':
        return Icons.pause_circle;
      case 'job_resumed':
        return Icons.play_circle;
      case 'job_completed':
        return Icons.task_alt;
      case 'payment_received':
        return Icons.payment;
      case 'new_job_available':
        return Icons.work;
      case 'private_job_request':
        return Icons.work_outline;
      case 'job_created':
        return Icons.add_task;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 280,
                height: 200,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    _dismissWithAnimation();
                    widget.onTap();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Message (optional)
                      if (widget.message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
