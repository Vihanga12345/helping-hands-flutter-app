import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';

class Helper9ViewRequestsPublicPage extends StatelessWidget {
  const Helper9ViewRequestsPublicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Public Requests',
            showBackButton: true,
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
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.public,
                                color: AppColors.primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Open requests available to all helpers',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          final requests = [
                            {
                              'title': 'General House Cleaning',
                              'location': 'Colombo 03, 1.5 km away',
                              'pay': 'LKR 2,500',
                              'applicants': '5 applied',
                            },
                            {
                              'title': 'Office Maintenance',
                              'location': 'Bambalapitiya, 2.0 km away',
                              'pay': 'LKR 4,000',
                              'applicants': '8 applied',
                            },
                          ];

                          final request = requests[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          request['title']!,
                                          style:
                                              AppTextStyles.heading3.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          request['applicants']!,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(request['location']!,
                                          style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          request['pay']!,
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: AppColors.warning,
                                              size: 16),
                                          Text(' 4.5',
                                              style: AppTextStyles.bodyMedium),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            // Show ignore confirmation dialog
                                            _showIgnoreDialog(context, request);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: AppColors.textSecondary),
                                          ),
                                          child: Text(
                                            'Ignore',
                                            style: AppTextStyles.buttonMedium
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            // Navigate to job detail page to view full details
                                            context.push('/helper/job-detail');
                                          },
                                          child: const Text('View Details'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Show accept confirmation dialog
                                            _showAcceptDialog(context, request);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                          ),
                                          child: const Text('Accept'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, Map<String, String> request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Accept Job Request'),
          content: Text(
              'Are you sure you want to accept "${request['title']}"? You will be committed to completing this work.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _acceptJob(context, request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _showIgnoreDialog(BuildContext context, Map<String, String> request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ignore Job Request'),
          content: Text(
              'This job "${request['title']}" will be removed from your feed and you won\'t see it again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _ignoreJob(context, request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Ignore'),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob(BuildContext context, Map<String, String> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Job "${request['title']}" accepted! Moving to ongoing jobs.'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: In a real app, update the job status in the database
    // Navigate to activity page with ongoing tab
    context.go('/helper/activity/ongoing');
  }

  void _ignoreJob(BuildContext context, Map<String, String> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job "${request['title']}" ignored.'),
        backgroundColor: AppColors.textSecondary,
      ),
    );
    // TODO: In a real app, mark this job as ignored for this helper
  }
}
