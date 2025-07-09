import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/localization_service.dart';

class Helpee20AboutUsPage extends StatelessWidget {
  const Helpee20AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'About Us'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
          ),

          // Body Content
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.50, 0.00),
                  end: Alignment(0.50, 1.00),
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Logo and Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                              width: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Helping Hands',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Connecting Communities, One Task at a Time',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mission Section
                      _buildInfoCard(
                        title: 'Our Mission',
                        content:
                            'To create a trusted platform that connects people who need household assistance with skilled helpers in their community. We believe in empowering individuals through meaningful work opportunities while making life easier for busy families.',
                        icon: Icons.flag,
                      ),

                      const SizedBox(height: 16),

                      // Vision Section
                      _buildInfoCard(
                        title: 'Our Vision',
                        content:
                            'To be Sri Lanka\'s leading household services platform, fostering a community where everyone can access reliable help and create sustainable livelihoods through dignified work.',
                        icon: Icons.visibility,
                      ),

                      const SizedBox(height: 16),

                      // Values Section
                      _buildInfoCard(
                        title: 'Our Values',
                        content:
                            '• Trust & Safety: Verified helpers and secure payments\n• Quality Service: Skilled professionals you can rely on\n• Community: Supporting local workers and families\n• Transparency: Clear pricing and honest reviews\n• Respect: Treating everyone with dignity and fairness',
                        icon: Icons.favorite,
                      ),

                      const SizedBox(height: 16),

                      // How It Works
                      _buildInfoCard(
                        title: 'How It Works',
                        content:
                            '1. Post Your Request: Describe what help you need\n2. Get Matched: Browse qualified helpers in your area\n3. Chat & Hire: Connect directly with your chosen helper\n4. Service Delivered: Get the job done professionally\n5. Pay Securely: Cashless transactions through the app\n6. Rate & Review: Share your experience with the community',
                        icon: Icons.info_outline,
                      ),

                      const SizedBox(height: 16),

                      // Contact Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowColorLight,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.contact_mail,
                                    color: AppColors.primaryGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildContactItem(
                                Icons.email, 'support@helpinghands.lk'),
                            const SizedBox(height: 12),
                            _buildContactItem(Icons.phone, '+94 11 234 5678'),
                            const SizedBox(height: 12),
                            _buildContactItem(
                                Icons.location_on, 'Colombo, Sri Lanka'),
                            const SizedBox(height: 12),
                            _buildContactItem(
                                Icons.access_time, '24/7 Customer Support'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // App Version
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGrey),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Helping Hands v1.0.0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '© 2024 Helping Hands. All rights reserved.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
