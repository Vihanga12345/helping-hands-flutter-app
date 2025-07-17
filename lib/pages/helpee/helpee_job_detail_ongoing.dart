import 'package:flutter/material.dart';
import '../../models/user_type.dart';
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
import '../../widgets/job_status_indicator.dart'; // Import the new status indicator
import '../common/report_page.dart';

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
  // Timer related fields are now handled by LiveTimerWidget
  // Timer? _timerUpdater;
  // int _elapsedSeconds = 0;
  // String _timerStatus = 'not_started';
  // Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  @override
  void dispose() {
    // _timerUpdater?.cancel(); // Handled by LiveTimerWidget
    super.dispose();
  }

  Future<void> _loadJobDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _jobDetails = null; // Clear previous data
      });
    }

    if (widget.jobId != null) {
      try {
        final jobDetails =
            await _jobDetailService.getCompleteJobDetails(widget.jobId!);

        if (jobDetails == null) {
          if (mounted) {
            setState(() {
              _error = 'Job not found or access denied';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _jobDetails = jobDetails;
            _isLoading = false;
          });
        }

        // Start timer if job is in progress
        // _initializeTimer(); // Removed
      } catch (e) {
        print('❌ Error loading job details: $e');
        if (mounted) {
          setState(() {
            _error = 'Failed to load job details. Please try again.';
            _isLoading = false;
          });
        }
      }
    } else if (widget.jobData != null) {
      // Validate widget.jobData has required fields
      final jobData = widget.jobData!;
      if (jobData['id'] == null) {
        if (mounted) {
          setState(() {
            _error = 'Invalid job data provided';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _jobDetails = jobData;
          _isLoading = false;
        });
      }
      // _initializeTimer(); // Removed
    } else {
      if (mounted) {
        setState(() {
          _error = 'No job ID or data provided';
          _isLoading = false;
        });
      }
    }
  }

  // All old timer logic can be removed:
  // _initializeTimer()
  // _startLiveTimer()
  // _stopLiveTimer()
  // _formatElapsedTime()
  // _calculateCurrentCost() - This might need to be adjusted based on the live data

  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _calculateCurrentCost() {
    if (_jobDetails == null) {
      print('⚠️ Cannot calculate cost: job details is null');
      return 'LKR 0.00';
    }

    final hourlyRateValue = _jobDetails!['hourly_rate'];
    double hourlyRate = 0.0;

    if (hourlyRateValue != null) {
      if (hourlyRateValue is num) {
        hourlyRate = hourlyRateValue.toDouble();
      } else if (hourlyRateValue is String) {
        hourlyRate = double.tryParse(hourlyRateValue) ?? 0.0;
      }
    }

    final elapsedHours = _jobDetails!['total_time_seconds'] /
        3600.0; // Changed to total_time_seconds
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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading job details...'),
                        ],
                      ),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _jobDetails == null
                          ? _buildNoDataState()
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
                                  JobStatusIndicator(
                                    jobTitle: _jobDetails!['title'] ?? 'Job',
                                    helperName:
                                        _jobDetails!['helper_first_name'] ??
                                            _jobDetails!['helper_username'] ??
                                            '',
                                    status: _jobDetails!['status'] ?? 'pending',
                                    jobDetails: _jobDetails,
                                  ),
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

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No job data available',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load job details. Please try again.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.pop();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainJobDetails() {
    // Null safety check
    if (_jobDetails == null) {
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
              'Loading Job Details...',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }

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
          // Public/Private Status Label
          Row(
            children: [
              Text(
                'Request Type: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _jobDetails!['is_private'] == true
                      ? AppColors.primaryGreen.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _jobDetails!['is_private'] == true
                          ? Icons.lock
                          : Icons.public,
                      size: 14,
                      color: _jobDetails!['is_private'] == true
                          ? AppColors.primaryGreen
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _jobDetails!['is_private'] == true ? 'PRIVATE' : 'PUBLIC',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _jobDetails!['is_private'] == true
                            ? AppColors.primaryGreen
                            : AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildJobStatusSection() {
    if (_jobDetails == null) return const SizedBox.shrink();

    final status = _jobDetails!['status']?.toLowerCase() ?? '';
    final helperFirstName = _jobDetails!['helper_first_name'] ?? '';
    final helperLastName = _jobDetails!['helper_last_name'] ?? '';
    final helperName = '$helperFirstName $helperLastName'.trim();
    final cleanHelperName = helperName.isEmpty ? 'Helper' : helperName;

    // Show different content based on job status
    if (status == 'completed') {
      return _buildCompletedJobInfo();
    } else if (['started', 'in_progress'].contains(status)) {
      return _buildJobInProgressStatus(cleanHelperName);
    } else if (status == 'accepted') {
      return _buildJobAcceptedStatus(cleanHelperName);
    }

    return const SizedBox.shrink();
  }

  Widget _buildJobInProgressStatus(String helperName) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Job Status',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Helper is Working',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '$helperName is currently working on your job',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Please wait for completion...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobAcceptedStatus(String helperName) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Job Status',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Helper Assigned',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '$helperName will start the job soon',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be notified when they begin',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobInfo() {
    final totalSeconds = (_jobDetails!['cumulative_time_seconds'] ?? 0) as int;
    final hourlyRate = (_jobDetails!['hourly_rate'] ?? 0.0) as double;
    final totalHours = totalSeconds / 3600.0;
    final totalCost = totalHours * hourlyRate;
    final finalCost = totalCost < hourlyRate ? hourlyRate : totalCost;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Job Completed',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Duration',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatElapsedTime(totalSeconds),
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.lightGrey,
              ),
              Column(
                children: [
                  Text(
                    'Total Cost',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'LKR ${finalCost.toStringAsFixed(2)}',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatusContent(String status, dynamic startTime,
      double hourlyRate, int totalElapsedSeconds, bool hasHelperAssigned) {
    // Always show waiting content - no timer for helpee
    return _buildWaitingForHelperContent(hasHelperAssigned, status);
  }

  Widget _buildWaitingForHelperContent(bool hasHelperAssigned,
      [String? status]) {
    String statusText = '';
    String statusDescription = '';
    Color statusColor = AppColors.warning;
    IconData statusIcon = Icons.schedule;

    if (status == 'accepted') {
      statusText = 'Helper Assigned';
      statusDescription = 'will start the job soon';
      statusColor = AppColors.warning;
      statusIcon = Icons.assignment_ind;
    } else if (['started', 'in_progress'].contains(status)) {
      statusText = 'Helper is Working';
      statusDescription = 'currently working on your job';
      statusColor = AppColors.primaryGreen;
      statusIcon = Icons.work;
    } else {
      statusText = hasHelperAssigned
          ? 'Waiting for Helper to Start'
          : 'Waiting for Helper Assignment';
      statusDescription = hasHelperAssigned
          ? 'will start the job soon'
          : 'We\'re still finding a helper for your job. Please wait for assignment.';
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          statusText.tr(),
          style: AppTextStyles.heading3.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          statusDescription.tr(),
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
        if (_jobDetails!['status']?.toLowerCase() == 'accepted') ...[
          // Changed to status
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportPage(userType: 'helpee'),
          ),
        );
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

              // Extract clean question text from the nested question object
              final questionText = qa['question']?['question'] ??
                  qa['question']?.toString() ??
                  'Question not available';

              // Use the processed answer that was set in JobDetailService
              final answerText = qa['processed_answer'] ??
                  qa['answer'] ??
                  'No answer provided';

              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  _buildQuestionAnswer(
                    'Q${index + 1}: $questionText'.tr(),
                    'A: $answerText'.tr(),
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
