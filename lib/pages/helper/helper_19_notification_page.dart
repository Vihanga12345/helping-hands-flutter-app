import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/user_data_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper19NotificationPage extends StatefulWidget {
  const Helper19NotificationPage({super.key});

  @override
  State<Helper19NotificationPage> createState() =>
      _Helper19NotificationPageState();
}

class _Helper19NotificationPageState extends State<Helper19NotificationPage> {
  final UserDataService _userDataService = UserDataService();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _userDataService.getNotifications();
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('helper_home');
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Notifications',
                showBackButton: true,
                onBackPressed: _handleBackNavigation,
                rightWidget: IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () async {
                    await _userDataService.markAllNotificationsAsRead();
                    setState(() {
                      _notificationsFuture =
                          _userDataService.getNotifications();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All notifications marked as read')),
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading notifications: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    final notifications = snapshot.data;

                    if (notifications == null || notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text('No notifications yet',
                                style: AppTextStyles.heading3),
                            SizedBox(height: 8),
                            Text(
                              'We\'ll let you know when something important happens.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification['is_read'] as bool;
                        final createdAt =
                            DateTime.parse(notification['created_at']);
                        final timeAgo = timeago.format(createdAt);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.white
                                : AppColors.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: isRead
                                ? null
                                : Border.all(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.3)),
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
                                color: _getIconColor(
                                        notification['notification_type']
                                            as String)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIcon(notification['notification_type']
                                    as String),
                                color: _getIconColor(
                                    notification['notification_type']
                                        as String),
                              ),
                            ),
                            title: Text(
                              notification['title'] as String,
                              style: TextStyle().copyWith(
                                fontWeight: isRead
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
                                  timeAgo,
                                  style: TextStyle().copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () async {
                              // Mark notification as read
                              await _userDataService
                                  .markNotificationAsRead(notification['id']);

                              // Handle navigation based on notification type
                              final notificationType =
                                  notification['notification_type'] as String;
                              final jobId = notification['related_job_id'];

                              if (jobId != null) {
                                switch (notificationType) {
                                  case 'job_accepted':
                                  case 'job_started':
                                    context.push('/helper/job-detail/ongoing',
                                        extra: {'jobId': jobId});
                                    break;
                                  case 'job_completed':
                                    context.push('/helper/job-detail/completed',
                                        extra: {'jobId': jobId});
                                    break;
                                  case 'job_cancelled':
                                    context.push('/helper/activity/pending');
                                    break;
                                  default:
                                    context.push('/helper/home');
                                }
                              }

                              // Refresh notifications
                              setState(() {
                                _notificationsFuture =
                                    _userDataService.getNotifications();
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Navigation Bar
              AppNavigationBar(
                currentTab: NavigationTab.home, // This might need to be dynamic
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
      case 'job_application':
      case 'job_accepted':
      case 'job_completed':
        return Icons.work;
      case 'payment':
        return Icons.payment;
      case 'system':
      case 'profile':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'job_application':
        return AppColors.primaryGreen;
      case 'job_accepted':
        return AppColors.success;
      case 'job_completed':
        return AppColors.info;
      case 'payment':
        return AppColors.success;
      case 'system':
      case 'profile':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
