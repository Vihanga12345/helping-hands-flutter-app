import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import 'dart:async';
import '../../widgets/common/universal_page_header.dart';
import '../../widgets/common/custom_button.dart';

class AdminStartPage extends StatefulWidget {
  const AdminStartPage({super.key});

  @override
  State<AdminStartPage> createState() => _AdminStartPageState();
}

class _AdminStartPageState extends State<AdminStartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animations
    _animationController.forward();

    // Set up automatic navigation after 5 seconds
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.go('/admin/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            // Universal Page Header
            UniversalPageHeader(
              title: 'Admin Portal',
              subtitle: 'System Administration',
              showBackButton: false,
            ),

            // Body Content
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo and Branding
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Admin Logo
                                    Container(
                                      width: 120,
                                      height: 120,
                                      padding: const EdgeInsets.all(10),
                                      child: Image.asset(
                                        'lib/Assets/LOGO (3).png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Helping Hands Title
                                    const Text(
                                      'Helping Hands',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkGreen,
                                        letterSpacing: 1.0,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Admin Subtitle
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'Admin Portal',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkGreen,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // Loading indicator and countdown
                                    Column(
                                      children: [
                                        // Loading Indicator
                                        Container(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryGreen,
                                            ),
                                            strokeWidth: 3,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Loading text
                                        Text(
                                          'Initializing Admin Portal...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Countdown timer
                                        StreamBuilder<int>(
                                          stream: _getCountdownStream(),
                                          builder: (context, snapshot) {
                                            final countdown =
                                                snapshot.data ?? 5;
                                            return Text(
                                              'Redirecting in ${countdown}s',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 32),

                                    // Manual navigation button
                                    _buildActionButton(
                                      text: 'Continue to Login',
                                      onTap: () => context.go('/admin/login'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 150,
          maxWidth: 250,
          minHeight: 60,
          maxHeight: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: AppColors.lightGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.darkGreen,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generate countdown stream from 5 to 0
  Stream<int> _getCountdownStream() {
    return Stream.periodic(
      const Duration(seconds: 1),
      (count) => 5 - count,
    ).take(6).where((count) => count >= 0);
  }
}
