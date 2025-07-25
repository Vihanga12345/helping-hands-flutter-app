import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/common/job_action_buttons.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/common/realtime_app_wrapper.dart';
import 'dart:async';

class Helper10ActivityPendingPage extends StatefulWidget {
  final int initialTabIndex;

  const Helper10ActivityPendingPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<Helper10ActivityPendingPage> createState() =>
      _Helper10ActivityPendingPageState();
}

class _Helper10ActivityPendingPageState
    extends State<Helper10ActivityPendingPage>
    with TickerProviderStateMixin, RealTimePageMixin {
  late TabController _tabController;
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();

  // Real-time data streams
  Map<String, List<Map<String, dynamic>>> _jobsData = {
    'pending': [],
    'ongoing': [],
    'completed': [],
  };
  StreamSubscription? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      vsync: this,
    );

    // Initialize real-time updates
    _initializeRealTimeUpdates();
  }

  void _initializeRealTimeUpdates() {
    // Listen to real-time activity data updates
    _activitySubscription = liveDataService.activityStream.listen((activities) {
      print(
          '🔄 Helper Activity: Received ${activities.length} activities from stream');

      if (mounted) {
        setState(() {
          // Group activities by status for helper
          _jobsData['pending'] =
              activities.where((job) => job['status'] == 'pending').toList();
          _jobsData['ongoing'] = activities
              .where((job) => [
                    'accepted',
                    'ongoing',
                    'started',
                    'in_progress',
                    'paused',
                    'confirmed'
                  ].contains(job['status']))
              .toList();
          _jobsData['completed'] =
              activities.where((job) => job['status'] == 'completed').toList();
        });

        print('📊 Helper Activity Data:');
        print('   Pending: ${_jobsData['pending']?.length ?? 0}');
        print('   Ongoing: ${_jobsData['ongoing']?.length ?? 0}');
        print('   Completed: ${_jobsData['completed']?.length ?? 0}');
      }
    });

    // Initial data load
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      print('🔄 Helper Activity: Loading initial data...');

      // Ensure the live data service is initialized
      if (!liveDataService.isInitialized) {
        print('⚠️ LiveDataService not initialized, initializing now...');
        await liveDataService.initialize();
      }

      // Load all activities without status filter to get complete data
      await liveDataService.refreshActivity();

      print('✅ Helper Activity: Initial data load completed');
    } catch (e) {
      print('❌ Error loading initial helper activity data: $e');

      // Fallback: Try to load data directly from JobDataService
      print('🔄 Fallback: Loading data directly from JobDataService...');
      _loadDataDirectly();
    }
  }

  // Fallback method to load data directly if live service fails
  void _loadDataDirectly() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }

      final helperId = currentUser['user_id'];
      print('🔄 Loading helper data directly for: $helperId');

      // Load all job statuses in parallel
      final results = await Future.wait([
        _jobDataService.getHelperPendingJobs(helperId),
        _jobDataService.getJobsByHelperAndStatus(helperId, 'ongoing'),
        _jobDataService.getJobsByHelperAndStatus(helperId, 'completed'),
      ]);

      if (mounted) {
        setState(() {
          _jobsData['pending'] = results[0];
          _jobsData['ongoing'] = results[1];
          _jobsData['completed'] = results[2];
        });

        print('✅ Direct data load completed:');
        print('   Pending: ${_jobsData['pending']?.length ?? 0}');
        print('   Ongoing: ${_jobsData['ongoing']?.length ?? 0}');
        print('   Completed: ${_jobsData['completed']?.length ?? 0}');
      }
    } catch (e) {
      print('❌ Error in direct data loading: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Activities'.tr(),
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
                      tabs: [
                        Tab(text: 'Pending'.tr()),
                        Tab(text: 'Ongoing'.tr()),
                        Tab(text: 'Completed'.tr()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDynamicJobList('pending'),
                        _buildDynamicJobList('ongoing'),
                        _buildDynamicJobList('completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.activity,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicJobList(String status) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return _buildNotLoggedInState();
    }

    final jobs = _jobsData[status] ?? [];

    if (jobs.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    Color statusColor = _getStatusColor(job['status']);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to the comprehensive job detail page with the job ID
            final jobId = job['id'] as String;
            context.push('/helper/comprehensive-job-detail/$jobId');
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
                        job['title'] ?? 'Unknown Job'.tr(),
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
                        (job['status'] ?? 'UNKNOWN').toUpperCase(),
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
                        job['pay'] ?? 'Rate not set'.tr(),
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
                _buildInfoPill(job['date'] ?? 'Date not set'.tr()),
                const SizedBox(height: 8),
                _buildInfoPill(job['time'] ?? 'Time not set'.tr()),
                const SizedBox(height: 8),
                _buildInfoPill(job['location'] ?? 'Location not set'.tr()),
                const SizedBox(height: 16),

                // Dynamic action buttons with timer functionality
                JobActionButtons(
                  job: job,
                  userType: 'helper',
                  onJobUpdated: () => setState(() {}),
                  showTimer: ['started', 'paused']
                      .contains(job['status']?.toLowerCase()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(text,
          style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildHelperActionButtons(Map<String, dynamic> job) {
    String status = (job['status'] ?? 'pending').toLowerCase();
    bool isPrivate = job['is_private'] ?? false;

    if (status == 'completed') {
      // For completed jobs: Rate helpee
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/helper/rate-helpee'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text('Rate Helpee'.tr(),
              style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.white, fontWeight: FontWeight.w600)),
        ),
      );
    } else if (status == 'ongoing' ||
        status == 'started' ||
        status == 'accepted') {
      // For ongoing jobs: different buttons based on state
      if (status == 'started') {
        // For started jobs: Complete Job and Message Helpee
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Opening chat with helpee...'.tr()))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text('Message'.tr(),
                    style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    _showCompleteJobDialog(context, job['title'] ?? 'Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: Text('Complete Job'.tr(),
                    style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      } else {
        // For accepted jobs: Start Job button
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                _showStartJobDialog(context, job['title'] ?? 'Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            child: Text('Start Job'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        );
      }
    } else {
      // For pending jobs: Accept and Decline options
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  _showDeclineJobDialog(context, job['title'] ?? 'Job'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Decline'.tr(),
                  style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  _showAcceptJobDialog(context, job['title'] ?? 'Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Accept'.tr(),
                  style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'STARTED':
        return AppColors.success;
      case 'ACCEPTED':
        return AppColors.primaryGreen;
      case 'COMPLETED':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'No pending jobs\nNew job requests will appear here'.tr();
        icon = Icons.pending_actions;
        break;
      case 'ongoing':
        message = 'No ongoing jobs\nActive jobs will appear here'.tr();
        icon = Icons.work_outline;
        break;
      case 'completed':
        message = 'No completed jobs\nFinished jobs will appear here'.tr();
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No jobs found'.tr();
        icon = Icons.work_off;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load $status jobs'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Retry'.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your jobs'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptJobDialog(BuildContext context, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Accept Job'.tr()),
          content: Text('Accept "$jobTitle"?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Accepted $jobTitle'.tr())),
                );
              },
              child: Text('Accept'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showDeclineJobDialog(BuildContext context, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Decline Job'.tr()),
          content: Text('Decline "$jobTitle"?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Declined $jobTitle'.tr())),
                );
              },
              child: Text('Decline'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showStartJobDialog(BuildContext context, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Job'.tr()),
          content: Text('Start working on "$jobTitle"?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Started $jobTitle'.tr())),
                );
              },
              child: Text('Start'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showCompleteJobDialog(BuildContext context, String jobTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Job'.tr()),
          content: Text('Mark "$jobTitle" as completed?'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Completed $jobTitle'.tr())),
                );
              },
              child: Text('Complete'.tr()),
            ),
          ],
        );
      },
    );
  }
}
