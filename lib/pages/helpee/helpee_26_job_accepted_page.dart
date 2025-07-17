import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/localization_service.dart';

class Helpee26JobAcceptedPage extends StatefulWidget {
  const Helpee26JobAcceptedPage({super.key});

  @override
  State<Helpee26JobAcceptedPage> createState() =>
      _Helpee26JobAcceptedPageState();
}

class _Helpee26JobAcceptedPageState extends State<Helpee26JobAcceptedPage> {
  @override
  Widget build(BuildContext context) {
    final jobData = GoRouterState.of(context).extra as Map<String, dynamic>? ??
        {
          'jobId': 'JOB1001',
          'jobTitle': 'House Cleaning',
          'helperName': 'Saman Perera',
          'helperRating': '4.8',
          'helperImage': 'assets/images/helper_avatar.png',
          'scheduledDate': '15 Dec 2024',
          'scheduledTime': '10:00 AM',
          'duration': '3 hours',
          'address': '123 Galle Road, Colombo 03',
          'price': 'LKR 2,500',
          'helperPhone': '+94 77 123 4567',
          'acceptedAt': '13 Dec 2024, 4:45 PM',
        };

    return Scaffold(
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Accepted Job'.tr(),
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
                      // Success Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Great News!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your job request has been accepted',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.success,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Helper Information Card
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
                            const Text(
                              'Your Helper',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Helper Avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primaryGreen,
                                    size: 30,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Helper Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobData['helperName'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${jobData['helperRating']} rating',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Verified Helper',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job Details Card
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
                                    Icons.cleaning_services,
                                    color: AppColors.primaryGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobData['jobTitle'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Job ID: ${jobData['jobId']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  jobData['price'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Job Schedule
                            _buildDetailRow(Icons.calendar_today, 'Date',
                                jobData['scheduledDate']),
                            _buildDetailRow(Icons.access_time, 'Time',
                                jobData['scheduledTime']),
                            _buildDetailRow(
                                Icons.timer, 'Duration', jobData['duration']),
                            _buildDetailRow(Icons.location_on, 'Location',
                                jobData['address']),
                            _buildDetailRow(
                                Icons.done, 'Accepted', jobData['acceptedAt']),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Next Steps Card
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
                            const Text(
                              'What\'s Next?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildNextStepItem(
                              Icons.schedule,
                              'Prepare for the service',
                              'Make sure you\'re available at the scheduled time',
                              true,
                            ),
                            _buildNextStepItem(
                              Icons.location_on,
                              'Confirm your location',
                              'Ensure your address details are accurate',
                              false,
                            ),
                            _buildNextStepItem(
                              Icons.person,
                              'Meet your helper',
                              'Your helper will arrive at the scheduled time',
                              false,
                            ),
                            _buildNextStepItem(
                              Icons.payment,
                              'Payment after completion',
                              'Pay securely through the app after service completion',
                              false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rescheduleJob(context),
                              icon: const Icon(Icons.schedule),
                              label: const Text('Reschedule'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryGreen,
                                side: const BorderSide(
                                    color: AppColors.primaryGreen),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewHelperProfile(context),
                              icon: const Icon(Icons.person),
                              label: const Text('View Helper'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(
      IconData icon, String title, String description, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : AppColors.lightGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  isActive ? AppColors.primaryGreen : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callHelper(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling helper...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _messageHelper(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat with helper...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _rescheduleJob(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening reschedule options...'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _viewHelperProfile(BuildContext context) {
    context.go('/helpee/helper-profile');
  }
}
