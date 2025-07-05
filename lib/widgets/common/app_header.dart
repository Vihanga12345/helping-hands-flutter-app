import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/custom_auth_service.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final bool showMenuButton;
  final bool showNotificationButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final Widget? rightWidget;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showMenuButton = true,
    this.showNotificationButton = true,
    this.onBackPressed,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFF8FD89F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Left Button (Back or Menu)
              if (showBackButton)
                GestureDetector(
                  onTap: onBackPressed ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // If there's nothing to pop, go to the appropriate home page
                          _navigateToHome(context);
                        }
                      },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF8FD89F),
                      size: 18,
                    ),
                  ),
                )
              else if (showMenuButton)
                GestureDetector(
                  onTap: onMenuPressed ?? () => _navigateToMenu(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Color(0xFF8FD89F),
                      size: 18,
                    ),
                  ),
                )
              else
                const SizedBox(width: 30),

              // Title
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),

              // Right Button (Notification or Custom)
              if (showNotificationButton && rightWidget == null)
                GestureDetector(
                  onTap: onNotificationPressed ??
                      () => _navigateToNotifications(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Color(0xFF8FD89F),
                      size: 18,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 30,
                  height: 30,
                  child: rightWidget,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMenu(BuildContext context) {
    final currentUser = CustomAuthService().currentUser;
    if (currentUser != null && currentUser['user_type'] == 'helper') {
      context.go('/helper/menu');
    } else {
      context.go('/helpee/menu');
    }
  }

  void _navigateToNotifications(BuildContext context) {
    final currentUser = CustomAuthService().currentUser;
    if (currentUser != null && currentUser['user_type'] == 'helper') {
      context.go('/helper/notifications');
    } else {
      context.go('/helpee/notifications');
    }
  }

  void _navigateToHome(BuildContext context) {
    final currentUser = CustomAuthService().currentUser;
    if (currentUser != null && currentUser['user_type'] == 'helper') {
      context.go('/helper/home');
    } else {
      context.go('/helpee/home');
    }
  }
}
