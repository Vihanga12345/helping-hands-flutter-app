import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../models/user_type.dart';

class Helpee4HomePage extends StatefulWidget {
  const Helpee4HomePage({super.key});

  @override
  State<Helpee4HomePage> createState() => _Helpee4HomePageState();
}

class _Helpee4HomePageState extends State<Helpee4HomePage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Home'.tr(),
            showBackButton: false,
            showMenuButton: true,
            showNotificationButton: true,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section - Dynamic
                      _buildWelcomeSection(),

                      const SizedBox(height: 32),

                      // Quick Actions
                      Text(
                        'Quick Actions'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Request Help'.tr(),
                              Icons.add_circle,
                              () => context.go('/helpee/job-request'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Find Helpers'.tr(),
                              Icons.people,
                              () => context.go('/helpee/search-helper'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Additional Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Activity'.tr(),
                              Icons.work_history,
                              () => context.go('/helpee/activity/pending'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Calendar'.tr(),
                              Icons.calendar_today,
                              () => context.go('/helpee/calendar'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // AI Bot Assist Action (centered)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 160, // Half width for centered appearance
                            child: _buildQuickActionCard(
                              context,
                              'AI Bot Assist'.tr(),
                              Icons.smart_toy,
                              () => context.go('/helpee/ai-bot'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Help Information
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
                            Text(
                              'Need Help?'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Get started by creating your first job request or browse available helpers in your area.'
                                  .tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    context.go('/helpee/job-request'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Create Job Request'.tr(),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildWelcomeSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataService.getCurrentUserProfile(),
      builder: (context, snapshot) {
        String welcomeName = 'Welcome!'.tr();

        if (snapshot.hasData && snapshot.data != null) {
          final firstName = snapshot.data!['first_name'] ?? '';
          if (firstName.isNotEmpty) {
            welcomeName = '${'Welcome'.tr()}, $firstName!';
          }
        }

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
              Text(
                welcomeName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How can we help you today?'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
