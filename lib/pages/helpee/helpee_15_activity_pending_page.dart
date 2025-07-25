import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../widgets/ui_elements/functional_job_card.dart';
import '../../services/localization_service.dart';
import '../common/report_page.dart';
import '../../widgets/common/realtime_app_wrapper.dart';
import 'dart:async';

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
    extends State<Helpee15ActivityPendingPage>
    with TickerProviderStateMixin, RealTimePageMixin {
  late TabController _tabController;
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();
  bool _isDeletingJobId = false;
  String? _deletingJobId;

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
      if (mounted) {
        print(
            '🔄 Helpee Activity: Received ${activities.length} activities from stream');
        print(
            '📱 Activity data received: ${activities.length} total activities');

        setState(() {
          // Group activities by status
          _jobsData['pending'] =
              activities.where((job) => job['status'] == 'pending').toList();
          _jobsData['ongoing'] = activities
              .where((job) => [
                    'accepted',
                    'ongoing',
                    'started',
                    'paused',
                    'confirmed'
                  ].contains(job['status']))
              .toList();
          _jobsData['completed'] =
              activities.where((job) => job['status'] == 'completed').toList();
        });

        print('📊 Helpee Activity Data:');
        print('   Pending: ${_jobsData['pending']?.length ?? 0}');
        print('   Ongoing: ${_jobsData['ongoing']?.length ?? 0}');
        print('   Completed: ${_jobsData['completed']?.length ?? 0}');

        print(
            '📱 Grouped jobs - Pending: ${_jobsData['pending']?.length}, Ongoing: ${_jobsData['ongoing']?.length}, Completed: ${_jobsData['completed']?.length}');

        // Log pending jobs details
        if (_jobsData['pending']?.isNotEmpty == true) {
          for (var job in _jobsData['pending']!) {
            print(
                '📱 Pending Job: ${job['title']} (${job['id']}) - Status: ${job['status']}');
          }
        }
      }
    });

    // Initial data load
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      print('🔄 Helpee Activity: Loading initial data...');

      // Ensure the live data service is initialized
      if (!liveDataService.isInitialized) {
        print('⚠️ LiveDataService not initialized, initializing now...');
        await liveDataService.initialize();
      }

      // Load all activities without status filter to get complete data
      await liveDataService.refreshActivity();

      print('✅ Helpee Activity: Initial data load completed');
    } catch (e) {
      print('❌ Error loading initial helpee activity data: $e');

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

      final helpeeId = currentUser['user_id'];
      print('🔄 Loading helpee data directly for: $helpeeId');

      // Load all job statuses in parallel
      final results = await Future.wait([
        _jobDataService.getJobsByUserAndStatus(helpeeId, 'pending'),
        _jobDataService.getJobsByUserAndStatus(helpeeId, 'ongoing'),
        _jobDataService.getJobsByUserAndStatus(helpeeId, 'completed'),
      ]);

      if (mounted) {
        setState(() {
          _jobsData['pending'] = results[0];
          _jobsData['ongoing'] = results[1];
          _jobsData['completed'] = results[2];
        });

        print('✅ Direct helpee data load completed:');
        print('   Pending: ${_jobsData['pending']?.length ?? 0}');
        print('   Ongoing: ${_jobsData['ongoing']?.length ?? 0}');
        print('   Completed: ${_jobsData['completed']?.length ?? 0}');
      }
    } catch (e) {
      print('❌ Error in direct helpee data loading: $e');
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
            title: 'Pending Jobs'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: true,
            onNotificationPressed: () {
              context.push('/helpee/notifications');
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
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicJobList(String status) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('📱 _buildDynamicJobList($status): No current user');
      return _buildNotLoggedInState();
    }

    final jobs = _jobsData[status] ?? [];
    print('📱 _buildDynamicJobList($status): ${jobs.length} jobs in data');

    if (jobs.isEmpty) {
      print('📱 _buildDynamicJobList($status): Showing empty state');
      return _buildEmptyState(status);
    }

    print(
        '📱 _buildDynamicJobList($status): Building list with ${jobs.length} items');
    for (var i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      print('📱 Job $i: ${job['title']} (${job['id']}) - ${job['status']}');
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
            // Navigate to appropriate job detail page based on job status - SAME AS CALENDAR AND FUNCTIONAL_JOB_CARD
            String jobId = job['id'] ?? '';
            String status = (job['status'] ?? 'pending').toLowerCase();

            String route;
            switch (status) {
              case 'pending':
                route = '/helpee/job-detail/pending';
                break;
              case 'accepted':
              case 'started':
              case 'paused':
              case 'confirmed':
              case 'ongoing':
                route = '/helpee/job-detail/ongoing';
                break;
              case 'completed':
                route = '/helpee/job-detail/completed';
                break;
              default:
                route = '/helpee/job-detail/pending';
            }

            context.push(route, extra: {
              'jobId': jobId,
              'jobData': job,
            });
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
                        job['title'] ?? 'Unknown Job',
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
                        job['status'] ?? 'UNKNOWN',
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
                        job['pay'] ?? 'Rate not set',
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
                _buildInfoPill(job['date'] ?? 'Date not set'),
                const SizedBox(height: 8),
                _buildInfoPill(job['time'] ?? 'Time not set'),
                const SizedBox(height: 8),
                _buildInfoPill(job['location'] ?? 'Location not set'),
                const SizedBox(height: 16),

                // Public/Private Status Label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: job['is_private'] == true
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        job['is_private'] == true ? Icons.lock : Icons.public,
                        size: 16,
                        color: job['is_private'] == true
                            ? AppColors.primaryGreen
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job['is_private'] == true ? 'PRIVATE' : 'PUBLIC',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: job['is_private'] == true
                              ? AppColors.primaryGreen
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons based on job type
                _buildActionButtons(job),
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

  Widget _buildActionButtons(Map<String, dynamic> job) {
    // Use JobDataService to get correct action buttons based on user specifications
    final actionButtons = _jobDataService.getJobActionButtons(job, 'helpee');

    if (actionButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle single button
    if (actionButtons.length == 1) {
      final button = actionButtons.first;
      return SizedBox(
        width: double.infinity,
        child: _buildSingleActionButton(button, job),
      );
    }

    // Handle multiple buttons (Edit Job + Cancel Job for pending)
    return Row(
      children: actionButtons.map((button) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: button == actionButtons.last ? 0 : 12,
            ),
            child: _buildSingleActionButton(button, job),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleActionButton(
      Map<String, dynamic> button, Map<String, dynamic> job) {
    final action = button['action'] as String;
    final text = button['text'] as String;
    final color = button['color'] as String;
    final isLoading = _deletingJobId == job['id'] && (action == 'cancel');

    // Handle button styling based on color
    final bool isPrimary = color == 'primary' || color == 'success';
    final Color buttonColor = _getButtonColor(color);
    final Color textColor = isPrimary ? AppColors.white : buttonColor;

    if (isPrimary) {
      return ElevatedButton(
        onPressed:
            isLoading ? null : () => _handleActionButtonPress(action, job),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: isLoading
            ? _buildLoadingButtonContent()
            : Text(
                text,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    } else {
      return OutlinedButton(
        onPressed:
            isLoading ? null : () => _handleActionButtonPress(action, job),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(
              color: isLoading ? AppColors.textSecondary : buttonColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: isLoading
            ? _buildLoadingButtonContent()
            : Text(
                text,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isLoading ? AppColors.textSecondary : textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }
  }

  Widget _buildLoadingButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading...',
          style: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getButtonColor(String colorName) {
    switch (colorName) {
      case 'primary':
        return AppColors.primaryGreen;
      case 'success':
        return AppColors.success;
      case 'error':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.primaryGreen;
    }
  }

  void _handleActionButtonPress(String action, Map<String, dynamic> job) {
    switch (action) {
      case 'edit':
        // Navigate to dedicated edit job page
        context.push('/helpee/job-request-edit', extra: {
          'jobId': job['id'],
          'jobData': job,
        });
        break;
      case 'cancel':
        _cancelJob(job);
        break;
      case 'report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportPage(userType: 'helpee'),
          ),
        );
        break;
      default:
        print('⚠️ Unhandled action: $action');
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
        message = 'No pending jobs\nCreate a job request to get started!'.tr();
        icon = Icons.pending_actions;
        break;
      case 'ongoing':
        message = 'No ongoing jobs\nYour active jobs will appear here'.tr();
        icon = Icons.work_outline;
        break;
      case 'completed':
        message = 'No completed jobs\nYour finished jobs will appear here'.tr();
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
              ),
              textAlign: TextAlign.center,
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/helpee/job-request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: Text(
                  'Create Job Request'.tr(),
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String status) {
    String? _error;
    switch (status) {
      case 'pending':
        _error = 'Failed to load pending jobs'.tr();
        break;
      case 'ongoing':
        _error = 'Failed to load ongoing jobs'.tr();
        break;
      case 'completed':
        _error = 'Failed to load completed jobs'.tr();
        break;
      default:
        _error = 'Unknown error'.tr();
    }

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
              'Unable to load pending jobs'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error'.tr(),
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

  Future<void> _cancelJob(Map<String, dynamic> job) async {
    final jobId = job['id'];
    if (jobId == null || _deletingJobId == jobId) return;

    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Job'.tr()),
          content: Text(
              'Are you sure you want to cancel "${job['title'] ?? 'this job'}"? This action cannot be undone and the job will be permanently deleted.'
                  .tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Keep Job'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text('Cancel Job'.tr()),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    setState(() {
      _deletingJobId = jobId.toString();
    });

    try {
      final success = await _jobDataService.cancelJob(
          jobId.toString(), 'Cancelled by helpee');

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${job['title'] ?? 'Job'} cancelled and deleted successfully'
                      .tr()),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh the list
          setState(() {});
        }
      } else {
        throw Exception('Failed to cancel job');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling job: $e'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingJobId = null;
        });
      }
    }
  }
}
