import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/helper_data_service.dart';
import '../../services/job_detail_service.dart';
import '../../services/localization_service.dart';

enum OngoingJobState { acceptedNotStarted, inProgress, paused }

class HelpeeJobDetailOngoingPage extends StatefulWidget {
  final OngoingJobState jobState;
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const HelpeeJobDetailOngoingPage({
    super.key,
    this.jobState = OngoingJobState.acceptedNotStarted,
    this.jobId,
    this.jobData,
  });

  @override
  State<HelpeeJobDetailOngoingPage> createState() =>
      _HelpeeJobDetailOngoingPageState();
}

class _HelpeeJobDetailOngoingPageState
    extends State<HelpeeJobDetailOngoingPage> {
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();
  final JobDetailService _jobDetailService = JobDetailService();

  Map<String, dynamic>? _jobDetails;
  bool _isLoading = true;
  String? _error;
  Timer? _timerUpdater;
  int _elapsedSeconds = 0;
  String _timerStatus = 'not_started';
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  @override
  void dispose() {
    _timerUpdater?.cancel();
    super.dispose();
  }

  Future<void> _loadJobDetails() async {
    if (widget.jobId != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      try {
        final jobDetails =
            await _jobDetailService.getCompleteJobDetails(widget.jobId!);
        if (mounted) {
          setState(() {
            _jobDetails = jobDetails;
            _isLoading = false;
          });
        }

        // Start timer if job is in progress
        _initializeTimer();
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load job details: $e';
            _isLoading = false;
          });
        }
      }
    } else if (widget.jobData != null) {
      if (mounted) {
        setState(() {
          _jobDetails = widget.jobData;
          _isLoading = false;
        });
      }
      _initializeTimer();
    } else {
      if (mounted) {
        setState(() {
          _error = 'No job ID or data provided';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeTimer() {
    if (_jobDetails == null) return;

    final status = _jobDetails!['status']?.toLowerCase() ?? '';
    _timerStatus = _jobDetails!['timer_status']?.toLowerCase() ?? 'not_started';

    // Calculate elapsed time from database
    final totalSeconds = _jobDetails!['total_time_seconds'] ?? 0;
    _elapsedSeconds = totalSeconds;

    // If timer is running, start live updates
    if (_timerStatus == 'running') {
      _startLiveTimer();
    }
  }

  void _startLiveTimer() {
    _timerUpdater?.cancel();
    _timerUpdater = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timerStatus == 'running') {
        setState(() {
          _elapsedSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLiveTimer() {
    _timerUpdater?.cancel();
  }

  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _calculateCurrentCost() {
    if (_jobDetails == null) return 'LKR 0.00';

    final hourlyRateValue = _jobDetails!['hourly_rate'];
    final hourlyRate =
        (hourlyRateValue is num) ? hourlyRateValue.toDouble() : 0.0;
    final elapsedHours = _elapsedSeconds / 3600.0;
    final currentCost = (hourlyRate * elapsedHours).toStringAsFixed(2);
    return 'LKR $currentCost';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Ongoing Job'.tr(),
              showBackButton: true,
              showMenuButton: false,
              showNotificationButton: false,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainJobDetails(),
                              const SizedBox(height: 24),
                              _buildJobQuestions(),
                              const SizedBox(height: 24),
                              _buildJobAdditionalDetailsSegment(),
                              const SizedBox(height: 24),
                              _buildTimerSection(),
                              const SizedBox(height: 24),
                              _buildAssignedHelperSection(context),
                              const SizedBox(height: 24),
                              _buildOngoingJobActions(context),
                              const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Job Details',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadJobDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainJobDetails() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job Details',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ONGOING',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Job Type', _jobDetails?['category_name'] ?? 'General Service'),
          const SizedBox(height: 12),
          _buildDetailRow(
              'Hourly Rate', 'LKR ${_jobDetails?['hourly_rate'] ?? 0} / Hour'),
          const SizedBox(height: 12),
          _buildDetailRow('Date', _jobDetails?['date'] ?? 'Not set'),
          const SizedBox(height: 12),
          _buildDetailRow('Time', _jobDetails?['time'] ?? 'Not set'),
          const SizedBox(height: 12),
          _buildDetailRow('Location',
              _jobDetails?['location_address'] ?? 'Location not provided'),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    if (_jobDetails == null) return const SizedBox.shrink();

    final status = _jobDetails!['status']?.toLowerCase() ?? '';
    final startTime = _jobDetails!['start_time'];
    final endTime = _jobDetails!['end_time'];
    final totalElapsedSeconds = _jobDetails!['total_elapsed_seconds'] ?? 0;
    final hourlyRate = (_jobDetails!['hourly_rate'] is num)
        ? (_jobDetails!['hourly_rate'] as num).toDouble()
        : 0.0;

    // Check if helper is assigned
    final assignedHelperId = _jobDetails!['assigned_helper_id'];
    final helperFirstName = _jobDetails!['helper_first_name'] ?? '';
    final helperLastName = _jobDetails!['helper_last_name'] ?? '';

    bool hasHelperAssigned = assignedHelperId != null &&
        helperFirstName.isNotEmpty &&
        !helperFirstName.toLowerCase().contains('dummy') &&
        !helperFirstName.toLowerCase().contains('waiting');

    return Column(
      children: [
        // Timer/Status Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
          child: _buildJobStatusContent(status, startTime, hourlyRate,
              totalElapsedSeconds, hasHelperAssigned),
        ),
      ],
    );
  }

  Widget _buildJobStatusContent(String status, dynamic startTime,
      double hourlyRate, int totalElapsedSeconds, bool hasHelperAssigned) {
    // Job not started yet - waiting for helper
    if (startTime == null || startTime.toString().isEmpty) {
      return _buildWaitingForHelperContent(hasHelperAssigned);
    }

    // Job started - show live timer
    if (status == 'started' || status == 'ongoing') {
      return _buildLiveTimerContent(startTime, hourlyRate, totalElapsedSeconds);
    }

    // Job paused
    if (status == 'paused') {
      return _buildPausedTimerContent(totalElapsedSeconds, hourlyRate);
    }

    // Default fallback
    return _buildWaitingForHelperContent(hasHelperAssigned);
  }

  Widget _buildWaitingForHelperContent(bool hasHelperAssigned) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.schedule,
            color: AppColors.warning,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          hasHelperAssigned
              ? 'Waiting for Helper to Start'.tr()
              : 'Waiting for Helper Assignment'.tr(),
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          hasHelperAssigned
              ? 'Your assigned helper will start the job soon. You\'ll see the live timer once they begin.'
                  .tr()
              : 'We\'re still finding a helper for your job. Please wait for assignment.'
                  .tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Animated waiting indicator
        TweenAnimationBuilder(
          duration: const Duration(seconds: 2),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildLiveTimerContent(
      dynamic startTime, double hourlyRate, int totalElapsedSeconds) {
    return Column(
      children: [
        // Live timer icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.play_circle_fill,
            color: AppColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Job in Progress'.tr(),
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),

        // Live Timer Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Time Elapsed'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatElapsedTime(_elapsedSeconds),
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.success.withOpacity(0.3)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Cost:'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _calculateCurrentCost(),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1000),
                tween: Tween<double>(begin: 0.3, end: 1.0),
                builder: (context, double value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onEnd: () {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVE'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPausedTimerContent(int totalElapsedSeconds, double hourlyRate) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.pause_circle_filled,
            color: AppColors.warning,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Job Paused'.tr(),
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),

        // Paused Timer Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Time Elapsed (Paused)'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatElapsedTime(totalElapsedSeconds),
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.warning.withOpacity(0.3)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Cost:'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _calculateCurrentCost(),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Paused indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause,
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'PAUSED'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelperProfileBar() {
    if (_jobDetails == null) return const SizedBox.shrink();

    final helperFirstName = _jobDetails!['helper_first_name'] ?? '';
    final helperLastName = _jobDetails!['helper_last_name'] ?? '';
    final helperProfilePic = _jobDetails!['helper_profile_pic'];
    final helperRating = _jobDetails!['helper_avg_rating'];
    final helperJobCount = _jobDetails!['helper_completed_jobs'] ?? 0;
    final helperJobTypes = _jobDetails!['helper_job_types'] ?? 'General Helper';
    final helperId = _jobDetails!['assigned_helper_id'];

    if (helperFirstName.isEmpty ||
        helperFirstName.toLowerCase().contains('dummy')) {
      return const SizedBox.shrink();
    }

    double rating = 0.0;
    if (helperRating is num) {
      rating = helperRating.toDouble();
    }

    int jobCount = 0;
    if (helperJobCount is num) {
      jobCount = helperJobCount.toInt();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Helper profile picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.lightGrey,
            ),
            child: helperProfilePic != null && helperProfilePic.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      helperProfilePic,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.textSecondary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: 12),

          // Helper details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$helperFirstName $helperLastName',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.warning,
                        );
                      }),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $jobCount jobs'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow button
          GestureDetector(
            onTap: () async {
              if (helperId != null) {
                // Navigate with helperId; detailed page will fetch full data
                context.push('/helpee/helper-profile-detailed', extra: {
                  'helperId': helperId,
                });
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedHelperSection(BuildContext context) {
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
          Text(
            'Assigned Helper'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          HelperProfileBar(
            name: _jobDetails?['helper_first_name'] != null &&
                    _jobDetails?['helper_last_name'] != null
                ? '${_jobDetails!['helper_first_name']} ${_jobDetails!['helper_last_name']}'
                : 'Helper Name'.tr(),
            rating: (_jobDetails?['helper_avg_rating'] is num)
                ? (_jobDetails!['helper_avg_rating'] as num).toDouble()
                : 0.0,
            jobCount: (_jobDetails?['helper_completed_jobs'] is num)
                ? (_jobDetails!['helper_completed_jobs'] as num).toInt()
                : 0,
            jobTypes: [], // Remove job types display
            profileImageUrl: _jobDetails?['helper_profile_pic'],
            helperId: _jobDetails?['assigned_helper_id'],
            onTap: () async {
              final helperId = _jobDetails?['assigned_helper_id'];
              if (helperId != null && helperId.isNotEmpty) {
                // Navigate with helperId; detailed page will fetch full data
                context.push('/helpee/helper-profile-detailed', extra: {
                  'helperId': helperId,
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen),
                    foregroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingJobActions(BuildContext context) {
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
          Text(
            'Actions'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionsForState(context),
        ],
      ),
    );
  }

  Widget _buildActionsForState(BuildContext context) {
    if (_jobDetails == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get dynamic action buttons from JobDataService
    final actionButtons =
        _jobDataService.getJobActionButtons(_jobDetails!, 'helpee');

    if (actionButtons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No actions available at this time.'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Helper status message for waiting states
        if (_timerStatus == 'not_started' ||
            _jobDetails!['status']?.toLowerCase() == 'accepted') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your helper will start the job shortly. You will be notified when they begin.'
                        .tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Dynamic action buttons
        ...actionButtons
            .map((button) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(context, button),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> button) {
    final String text = button['text'] ?? '';
    final String action = button['action'] ?? '';
    final String colorType = button['color'] ?? 'primary';
    final String? icon = button['icon'];

    Color buttonColor;
    Color textColor;
    bool isOutlined = false;

    switch (colorType) {
      case 'primary':
        buttonColor = AppColors.primaryGreen;
        textColor = AppColors.white;
        break;
      case 'error':
        buttonColor = AppColors.error;
        textColor = AppColors.white;
        isOutlined = true;
        break;
      case 'warning':
        buttonColor = AppColors.warning;
        textColor = AppColors.white;
        break;
      default:
        buttonColor = AppColors.primaryGreen;
        textColor = AppColors.white;
    }

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: () => _handleActionButton(action),
        icon: Icon(_getIconData(icon), size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _handleActionButton(action),
        icon: Icon(_getIconData(icon), size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      );
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'report_problem':
        return Icons.report_problem;
      case 'message':
        return Icons.message;
      case 'track_changes':
        return Icons.track_changes;
      default:
        return Icons.touch_app;
    }
  }

  Future<void> _handleActionButton(String action) async {
    if (widget.jobId == null) return;

    try {
      if (action == 'report') {
        _showReportDialog(context);
      } else {
        await _jobDataService.executeJobAction(action, widget.jobId!, null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${action.toUpperCase()} action completed successfully'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        _loadJobDetails(); // Refresh job details
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to perform action: $e'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Report Issue'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the type of issue:'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildReportOption('Helper is late or not showing up'.tr(),
                        selectedReason, setState),
                    _buildReportOption(
                        'Helper behavior issue'.tr(), selectedReason, setState),
                    _buildReportOption('Helper not following instructions'.tr(),
                        selectedReason, setState),
                    _buildReportOption('Quality of work concerns'.tr(),
                        selectedReason, setState),
                    _buildReportOption(
                        'Other issue'.tr(), selectedReason, setState),
                    const SizedBox(height: 16),
                    Text(
                      'Additional details:'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue in detail...'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel'.tr(),
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Report submitted: $selectedReason'.tr()),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(
                    'Submit Report'.tr(),
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReportOption(
      String option, String? selectedReason, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => selectedReason = option),
        child: Row(
          children: [
            Radio<String>(
              value: option,
              groupValue: selectedReason,
              onChanged: (value) => setState(() => selectedReason = value),
              activeColor: AppColors.primaryGreen,
            ),
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Job Questions Section
  Widget _buildJobQuestions() {
    if (_jobDetails == null) return const SizedBox.shrink();

    final questions = _jobDetails!['parsed_questions'] as List? ?? [];

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
          Text(
            'Job Questions'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questions and answers for this job'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No questions available for this job',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final qa = entry.value;
              final question = qa['question'] ?? 'Question not available';
              final answer = qa['answer'] ?? 'No answer provided';

              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  _buildQuestionAnswer(
                    'Q${index + 1}: $question'.tr(),
                    'A: $answer'.tr(),
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobAdditionalDetailsSegment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Job Additional Details'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_jobDetails!['description'] != null &&
              _jobDetails!['description'].isNotEmpty) ...[
            Text(
              'Job Description'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Text(
                _jobDetails!['description'],
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No additional details provided for this job',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
