import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper19NotificationPage extends StatelessWidget {
  const Helper19NotificationPage({super.key});

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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Notifications',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All notifications marked as read')),
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final notifications = [
                      {
                        'title': 'New Job Request',
                        'message':
                            'You received a private cleaning request in Colombo 07',
                        'time': '5 minutes ago',
                        'isRead': false,
                        'type': 'job',
                      },
                      {
                        'title': 'Payment Received',
                        'message':
                            'LKR 5,000 has been credited to your account',
                        'time': '2 hours ago',
                        'isRead': false,
                        'type': 'payment',
                      },
                      {
                        'title': 'Job Completed',
                        'message':
                            'Your house cleaning job has been marked as completed',
                        'time': '1 day ago',
                        'isRead': true,
                        'type': 'job',
                      },
                      {
                        'title': 'Profile Updated',
                        'message':
                            'Your helper profile has been successfully updated',
                        'time': '2 days ago',
                        'isRead': true,
                        'type': 'profile',
                      },
                      {
                        'title': 'Weekly Summary',
                        'message':
                            'You completed 3 jobs this week and earned LKR 12,500',
                        'time': '3 days ago',
                        'isRead': true,
                        'type': 'summary',
                      },
                    ];

                    final notification = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: notification['isRead'] as bool
                            ? AppColors.white
                            : AppColors.primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: notification['isRead'] as bool
                            ? null
                            : Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3)),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColorLight,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getIconColor(notification['type'] as String)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIcon(notification['type'] as String),
                            color:
                                _getIconColor(notification['type'] as String),
                          ),
                        ),
                        title: Text(
                          notification['title'] as String,
                          style: TextStyle().copyWith(
                            fontWeight: notification['isRead'] as bool
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification['message'] as String,
                              style: TextStyle().copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification['time'] as String,
                              style: TextStyle().copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: notification['isRead'] as bool
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Opening ${notification['title']}')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Navigation Bar
              AppNavigationBar(
                currentTab: NavigationTab.home,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'job':
        return Icons.work;
      case 'payment':
        return Icons.payment;
      case 'profile':
        return Icons.person;
      case 'summary':
        return Icons.analytics;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'job':
        return AppColors.primaryGreen;
      case 'payment':
        return AppColors.success;
      case 'profile':
        return AppColors.info;
      case 'summary':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
