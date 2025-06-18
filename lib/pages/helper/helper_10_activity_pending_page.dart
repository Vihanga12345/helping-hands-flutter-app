import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helper10ActivityPendingPage extends StatefulWidget {
  final int initialTabIndex;

  const Helper10ActivityPendingPage({
    super.key,
    this.initialTabIndex = 0, // Default to pending tab
  });

  @override
  State<Helper10ActivityPendingPage> createState() =>
      _Helper10ActivityPendingPageState();
}

class _Helper10ActivityPendingPageState
    extends State<Helper10ActivityPendingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Activities',
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
                    // Tab Bar
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
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicator: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Ongoing'),
                          Tab(text: 'Completed'),
                        ],
                      ),
                    ),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingTab(),
                          _buildOngoingTab(),
                          _buildCompletedTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.activity,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final activities = [
          {
            'title': 'House Deep Cleaning',
            'location': 'Colombo 07',
            'date': 'Dec 25, 2024',
            'time': '9:00 AM',
            'pay': 'LKR 5,000',
            'status': 'Awaiting Confirmation',
          },
          {
            'title': 'Office Maintenance',
            'location': 'Bambalapitiya',
            'date': 'Dec 26, 2024',
            'time': '2:00 PM',
            'pay': 'LKR 3,500',
            'status': 'Under Review',
          },
          {
            'title': 'Garden Cleaning',
            'location': 'Dehiwala',
            'date': 'Dec 27, 2024',
            'time': '8:00 AM',
            'pay': 'LKR 2,500',
            'status': 'Document Required',
          },
        ];

        final activity = activities[index];
        return _buildJobCard(
          title: activity['title']!,
          location: activity['location']!,
          dateTime: '${activity['date']} at ${activity['time']}',
          pay: activity['pay']!,
          status: activity['status']!,
          statusColor: AppColors.warning,
          onViewDetails: () {
            // Navigate to job detail page
            context.push('/helper/job-detail');
          },
          onConfirm: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Confirmed ${activity['title']}')),
            );
          },
        );
      },
    );
  }

  Widget _buildOngoingTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 2,
      itemBuilder: (context, index) {
        final activities = [
          {
            'title': 'Gardening',
            'location': 'Yakkaduwa',
            'date': '21st May',
            'time': '2:00 pm',
            'pay': '500 / Hr',
            'progress': 'Starting',
          },
          {
            'title': 'Kitchen Cleaning',
            'location': 'Mount Lavinia',
            'date': '22nd May',
            'time': '10:00 am',
            'pay': '600 / Hr',
            'progress': 'Accepted',
          },
        ];

        final activity = activities[index];
        return _buildJobCardWithProgress(
          title: activity['title']!,
          location: activity['location']!,
          date: activity['date']!,
          time: activity['time']!,
          pay: activity['pay']!,
          progress: activity['progress']!,
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 2,
      itemBuilder: (context, index) {
        final activities = [
          {
            'title': 'House Cleaning',
            'location': 'Colombo 03',
            'date': 'Dec 20, 2024',
            'time': '9:00 AM',
            'pay': 'LKR 4,000',
            'rating': '5.0',
          },
          {
            'title': 'Garden Maintenance',
            'location': 'Kandy',
            'date': 'Dec 18, 2024',
            'time': '7:00 AM',
            'pay': 'LKR 3,000',
            'rating': '4.8',
          },
        ];

        final activity = activities[index];
        return _buildJobCard(
          title: activity['title']!,
          location: activity['location']!,
          dateTime: '${activity['date']} at ${activity['time']}',
          pay: activity['pay']!,
          status: 'Completed',
          statusColor: AppColors.success,
          showRating: true,
          rating: activity['rating']!,
          onViewDetails: () {
            // Navigate to simplified job detail page for completed jobs
            context.push('/helper/job-detail-simple/completed');
          },
          onReport: () {
            // Show report dialog
            _showReportDialog(context, activity);
          },
        );
      },
    );
  }

  Widget _buildJobCard({
    required String title,
    required String location,
    required String dateTime,
    required String pay,
    required String status,
    required Color statusColor,
    bool showRating = false,
    String? rating,
    VoidCallback? onViewDetails,
    VoidCallback? onConfirm,
    VoidCallback? onReport,
  }) {
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
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
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
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(location, style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(dateTime, style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pay,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showRating && rating != null) ...[
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (onViewDetails != null ||
                onConfirm != null ||
                onReport != null) ...[
              const SizedBox(height: 16),
              // For completed jobs, show View Details and Report buttons
              if (status == 'Completed' && onReport != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'View Job Details',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Report',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // For other job types, show normal buttons
                Row(
                  children: [
                    if (onViewDetails != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewDetails,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'View Details',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    if (onViewDetails != null && onConfirm != null)
                      const SizedBox(width: 12),
                    if (onConfirm != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Confirm',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardWithProgress({
    required String title,
    required String location,
    required String date,
    required String time,
    required String pay,
    required String progress,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to ongoing job detail page
        context.push('/helper/job-ongoing');
      },
      child: Container(
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
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pay,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and Time in rounded containers
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  date,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  time,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  location,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildProgressDot(true, 'Pending'),
                    _buildProgressLine(true),
                    _buildProgressDot(true, 'Accepted'),
                    _buildProgressLine(
                        progress == 'Starting' || progress == 'Completed'),
                    _buildProgressDot(
                        progress == 'Starting' || progress == 'Completed',
                        'Starting'),
                    _buildProgressLine(progress == 'Completed'),
                    _buildProgressDot(progress == 'Completed', 'Completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const Icon(Icons.check, color: AppColors.white, size: 12)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
      ),
    );
  }

  void _showReportDialog(BuildContext context, Map<String, String> jobData) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.report_problem, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Report Job Issue'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report an issue with job: "${jobData['title']}"'),
              const SizedBox(height: 16),
              Text(
                'What type of issue would you like to report?',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                'Payment not received',
                'Helpee behavior issue',
                'Job description mismatch',
                'Safety concern',
                'Other issue'
              ]
                  .map(
                    (issue) => ListTile(
                      dense: true,
                      leading: Radio(
                        value: issue,
                        groupValue: null,
                        onChanged: (value) {
                          Navigator.of(dialogContext).pop();
                          _submitReport(context, jobData, issue);
                        },
                      ),
                      title: Text(issue, style: AppTextStyles.bodyMedium),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _submitReport(context, jobData, issue);
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _submitReport(
      BuildContext context, Map<String, String> jobData, String issueType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Report submitted for "${jobData['title']}" - $issueType'),
        backgroundColor: AppColors.warning,
        action: SnackBarAction(
          label: 'View Details',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Report tracking page would open here')),
            );
          },
        ),
      ),
    );
  }
}
