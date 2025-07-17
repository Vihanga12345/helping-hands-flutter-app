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

class Helper7HomePage extends StatefulWidget {
  const Helper7HomePage({super.key});

  @override
  State<Helper7HomePage> createState() => _Helper7HomePageState();
}

class _Helper7HomePageState extends State<Helper7HomePage> {
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Helper Home'.tr(),
            showMenuButton: true,
            showNotificationButton: true,
            onMenuPressed: () {
              context.push('/helper/menu');
            },
            onNotificationPressed: () {
              context.push('/helper/notifications');
            },
          ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Welcome Section - Dynamic
                        _buildWelcomeSection(),

                        const SizedBox(height: 24),

                        // Quick Stats - Dynamic
                        _buildQuickStatsSection(),

                        const SizedBox(height: 24),

                        // Recent Opportunities
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
                                'Job Opportunities'.tr(),
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.push('/helper/home/requests',
                                            extra: {'initialTabIndex': 0});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: Text(
                                        'Private Requests'.tr(),
                                        style:
                                            AppTextStyles.buttonMedium.copyWith(
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push('/helper/home/requests',
                                            extra: {'initialTabIndex': 1});
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.primaryGreen),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: Text(
                                        'Public Requests'.tr(),
                                        style:
                                            AppTextStyles.buttonMedium.copyWith(
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
          AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDataService.getCurrentUserProfile(),
      builder: (context, snapshot) {
        String welcomeName = 'Welcome back!'.tr();

        if (snapshot.hasData && snapshot.data != null) {
          final firstName = snapshot.data!['first_name'] ?? '';
          if (firstName.isNotEmpty) {
            welcomeName = '${'Welcome back,'.tr()} $firstName!';
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
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.handyman,
                      color: AppColors.primaryGreen,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          welcomeName,
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to help today?'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsSection() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return _buildStaticStatsSection();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataService.getHelperStatistics(currentUser['user_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingStatsSection();
        }

        final stats = snapshot.data ??
            {
              'pending_jobs': 0,
              'ongoing_jobs': 0,
              'completed_jobs': 0,
            };

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to Activity page with Pending tab selected
                  context.push('/helper/activity/pending');
                },
                child: _buildStatCard(
                  '${stats['pending_jobs']}',
                  'Pending'.tr(),
                  AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to Activity page with Ongoing tab selected
                  context.push('/helper/activity/ongoing');
                },
                child: _buildStatCard(
                  '${stats['ongoing_jobs']}',
                  'Ongoing'.tr(),
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to Activity page with Completed tab selected
                  context.push('/helper/activity/completed');
                },
                child: _buildStatCard(
                  '${stats['completed_jobs']}',
                  'Completed'.tr(),
                  AppColors.success,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: AppTextStyles.heading1.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatsSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading...'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading...'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColorLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading...'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('0', 'Pending'.tr(), AppColors.primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('0', 'Ongoing'.tr(), AppColors.warning),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('0', 'Completed'.tr(), AppColors.success),
        ),
      ],
    );
  }
}
