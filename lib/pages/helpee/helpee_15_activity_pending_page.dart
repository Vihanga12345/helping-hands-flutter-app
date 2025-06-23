import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';

class Helpee15ActivityPendingPage extends StatefulWidget {
  final int initialTabIndex;

  const Helpee15ActivityPendingPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<Helpee15ActivityPendingPage> createState() =>
      _Helpee15ActivityPendingPageState();
}

class _Helpee15ActivityPendingPageState
    extends State<Helpee15ActivityPendingPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      vsync: this,
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
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.primaryGreen,
                      indicator: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: AppTextStyles.buttonMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: AppTextStyles.buttonMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Ongoing'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Views
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
          const AppNavigationBar(
            currentTab: NavigationTab.activity,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildJobCard(
          title: index == 0 ? 'House Cleaning' : 'Gardening',
          pay: index == 0 ? '1500/Hr' : '1200/Hr',
          date: index == 0 ? 'Dec 25, 2024' : 'Dec 26, 2024',
          time: index == 0 ? '10:00 AM' : '2:00 PM',
          location: index == 0 ? 'Colombo 03' : 'Mount Lavinia',
          status: 'PENDING',
          helper: 'Waiting for Helper',
          jobType: 'pending',
        );
      },
    );
  }

  Widget _buildOngoingTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildJobCard(
          title: index == 0 ? 'House Cleaning' : 'Gardening',
          pay: index == 0 ? '1500/Hr' : '1200/Hr',
          date: index == 0 ? 'Dec 24, 2024' : 'Dec 25, 2024',
          time: index == 0 ? '9:00 AM' : '3:00 PM',
          location: index == 0 ? 'Colombo 07' : 'Nugegoda',
          status: index == 0 ? 'STARTED' : 'ACCEPTED',
          helper: index == 0 ? 'John Smith' : 'Sarah Wilson',
          jobType: 'ongoing',
          jobState: index == 0 ? 'started' : 'accepted',
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildJobCard(
          title: index == 0 ? 'House Cleaning' : 'Gardening',
          pay: index == 0 ? 'LKR 4,000' : 'LKR 2,400',
          date: index == 0 ? 'Dec 20, 2024' : 'Dec 18, 2024',
          time: index == 0 ? '9:00 AM' : '2:00 PM',
          location: index == 0 ? 'Colombo 03' : 'Kandy',
          status: 'COMPLETED',
          helper: index == 0 ? 'John Smith' : 'Sarah Wilson',
          jobType: 'completed',
        );
      },
    );
  }

  Widget _buildJobCard({
    required String title,
    required String pay,
    required String date,
    required String time,
    required String location,
    required String status,
    required String helper,
    required String jobType,
    String? jobState,
  }) {
    Color statusColor = status == 'PENDING'
        ? AppColors.warning
        : status == 'STARTED'
            ? AppColors.success
            : status == 'ACCEPTED'
                ? AppColors.primaryGreen
                : AppColors.success;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to appropriate job detail page based on job type
            if (jobType == 'pending') {
              context.push('/helpee/job-detail/pending');
            } else if (jobType == 'ongoing') {
              context.push('/helpee/job-detail/ongoing');
            } else if (jobType == 'completed') {
              context.push('/helpee/job-detail/completed');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pay rate
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pay,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info pills
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(date,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(time,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(location,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),

                // Clickable Helper Profile Bar
                GestureDetector(
                  onTap: () {
                    if (helper != 'Waiting for Helper') {
                      context.push('/helpee/helper-profile');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: helper == 'Waiting for Helper'
                              ? AppColors.textSecondary
                              : AppColors.primaryGreen,
                          child: Text(
                            helper == 'Waiting for Helper' ? '?' : helper[0],
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(helper,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        if (helper != 'Waiting for Helper')
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons based on job type - REDESIGNED per user requirements
                if (jobType == 'completed') ...[
                  // ONLY Report button for completed jobs
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showReportDialog(context, title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text('Report',
                          style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else if (jobType == 'ongoing') ...[
                  // Enhanced ongoing logic: Show different buttons for started vs accepted
                  if (jobState == 'started') ...[
                    // For started jobs: Track Progress and Message Helper
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text('Opening chat...'))),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: const BorderSide(
                                  color: AppColors.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text('Message',
                                style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text('Tracking job progress...'))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text('Track Progress',
                                style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // For accepted-but-not-started jobs: Wait for Helper to Start
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: AppColors.warning, width: 1),
                        ),
                        child: Text('Waiting for Helper to Start',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ] else ...[
                  // For pending jobs: Cancel and Edit options
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                                  SnackBar(content: Text('Cancelled $title'))),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text('Cancel',
                              style: AppTextStyles.buttonMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/helpee/job-edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text('Edit Request',
                              style: AppTextStyles.buttonMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showReportDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Issue'),
          content: Text('Report an issue with "$title"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report submitted for "$title"')),
                );
              },
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }
}
