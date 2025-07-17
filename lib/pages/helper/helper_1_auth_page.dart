import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/universal_page_header.dart';
import '../../widgets/common/custom_button.dart';

class Helper1AuthPage extends StatelessWidget {
  const Helper1AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Universal Page Header
          UniversalPageHeader(
            title: 'Helper Portal',
            subtitle: 'Choose your action',
            showBackButton: false,
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo and App Info
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.handyman,
                            size: 50,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Helping Hands',
                          style: TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "I'm a Helper",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ready to help others and earn money?',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Login Button
                        CustomButton(
                          text: 'Login',
                          onPressed: () => context.go('/helper-login'),
                          icon: Icons.login,
                        ),

                        // Register Button
                        CustomButton(
                          text: 'Register',
                          onPressed: () => context.go('/helper-register'),
                          icon: Icons.person_add,
                          isSecondary: true,
                        ),

                        const SizedBox(height: 24),

                        // Information Button
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Information page coming soon!'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Information',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
