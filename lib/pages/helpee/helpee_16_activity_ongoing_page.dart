import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helpee16ActivityOngoingPage extends StatelessWidget {
  const Helpee16ActivityOngoingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          const AppHeader(
            title: 'Activity',
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
                child: Column(
                  children: [
                    // Status Tabs
                    Container(
                      margin: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  context.go('/helpee/activity/pending'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: const Text(
                                  'Pending',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Ongoing',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  context.go('/helpee/activity/completed'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: const Text(
                                  'Completed',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ongoing Jobs List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 2, // Demo ongoing jobs
                        itemBuilder: (context, index) {
                          return _buildOngoingJobCard(
                            context,
                            jobId: 'JOB${1005 + index}',
                            title: 'House Cleaning ${index + 1}',
                            helper: 'Saman Perera',
                            startedDate: 'Dec ${22 + index}, 2024',
                            estimatedCompletion: 'Dec ${23 + index}, 2024',
                            status: index == 0 ? 'In Progress' : 'Paused',
                            price: 'LKR ${(index + 20) * 100}',
                            progress: index == 0 ? 0.6 : 0.3,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar - Activity tab active
          const AppNavigationBar(
            currentTab: NavigationTab.activity,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingJobCard(
    BuildContext context, {
    required String jobId,
    required String title,
    required String helper,
    required String startedDate,
    required String estimatedCompletion,
    required String status,
    required String price,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jobId,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'In Progress'
                      ? AppColors.success
                      : AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Job Details
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                'Helper: $helper',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress: ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.lightGrey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.success),
                minHeight: 6,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Started',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      startedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Est. Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      estimatedCompletion,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Message helper feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to job detail page using SAME LOGIC as calendar and activity - determine route by status
                    String normalizedStatus =
                        status.toLowerCase().replaceAll(' ', '');

                    String route;
                    switch (normalizedStatus) {
                      case 'pending':
                        route = '/helpee/job-detail/pending';
                        break;
                      case 'inprogress':
                      case 'ongoing':
                      case 'started':
                      case 'paused':
                      case 'accepted':
                      case 'confirmed':
                        route = '/helpee/job-detail/ongoing';
                        break;
                      case 'completed':
                        route = '/helpee/job-detail/completed';
                        break;
                      default:
                        route =
                            '/helpee/job-detail/ongoing'; // Default for ongoing page
                    }

                    context.push(route, extra: {
                      'jobId': jobId,
                      'jobData': {
                        'id': jobId,
                        'title': title,
                        'helper': helper,
                        'status': status,
                        'price': price,
                        'startedDate': startedDate,
                        'estimatedCompletion': estimatedCompletion,
                        'progress': progress,
                      }
                    });
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
