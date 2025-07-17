import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helpee_profile_bar.dart';
import '../../widgets/common/job_action_buttons.dart';
import '../../services/job_detail_service.dart'; // Changed from JobDataService
import '../../services/job_data_service.dart'; // Added for safer job completion
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/cash_payment_service.dart'; // For payment calculations
import '../../widgets/job_status_indicator.dart'; // Job status indicator with hourglass
import '../../services/simple_time_tracking_service.dart'; // For simple time tracking
import '../../services/payment_flow_service.dart'; // For payment confirmation flow

class HelperComprehensiveJobDetailPage extends StatefulWidget {
  final String jobId;

  const HelperComprehensiveJobDetailPage({
    super.key,
    required this.jobId,
  });

  @override
  State<HelperComprehensiveJobDetailPage> createState() =>
      _HelperComprehensiveJobDetailPageState();
}

class _HelperComprehensiveJobDetailPageState
    extends State<HelperComprehensiveJobDetailPage> {
  final JobDetailService _jobDetailService =
      JobDetailService(); // Changed from JobDataService
  final JobDataService _jobDataService =
      JobDataService(); // Added for safer job completion
  final UserDataService _userDataService = UserDataService();
  final PaymentFlowService _paymentFlowService = PaymentFlowService();
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _jobDetails;
  Map<String, dynamic>? _helpeeProfile;
  Map<String, dynamic>? _helpeeStatistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Use the comprehensive service to get all details
      final jobDetails =
          await _jobDetailService.getCompleteJobDetails(widget.jobId);

      if (jobDetails == null) {
        if (mounted) {
          setState(() {
            _error = 'Job not found';
            _isLoading = false;
          });
        }
        return;
      }

      // Extract helpee profile and stats from the complete job details
      if (mounted) {
        setState(() {
          _jobDetails = jobDetails;
          _helpeeProfile = {
            'id': jobDetails['helpee_id'],
            'first_name': jobDetails['helpee_first_name'],
            'last_name': jobDetails['helpee_last_name'],
            'profile_image_url': jobDetails['helpee_profile_pic'],
            'phone': jobDetails['helpee_phone'],
            'email': jobDetails['helpee_email'],
            'location_address': jobDetails['helpee_address'],
          };
          _helpeeStatistics = jobDetails['helpee_stats'] ??
              {
                'rating': 0.0,
                'total_jobs': 0,
              };
          _isLoading = false;
        });

        // Removed automatic payment popup - now handled by coordinated flow
      }

      print('✅ Job details loaded successfully for helper');
    } catch (e) {
      print('❌ Error loading job details for helper: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load job details: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Removed _checkAndShowPaymentPopup() - payment confirmations now handled by coordinated flow

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Job Details',
              showBackButton: true,
              showMenuButton: true,
              showNotificationButton: true,
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Segment 1: Main Job Details
                              _buildMainJobDetails(),
                              const SizedBox(height: 24),

                              // Segment 2: Job Questions
                              _buildJobQuestions(),
                              const SizedBox(height: 24),

                              // Segment 3: Job Additional Details
                              _buildJobAdditionalDetails(),
                              const SizedBox(height: 24),

                              // Segment 4: Payment Details (for completed jobs)
                              if (_jobDetails!['status']?.toLowerCase() ==
                                      'completed' ||
                                  _jobDetails!['status']?.toLowerCase() ==
                                      'payment_confirmed')
                                _buildPaymentDetails(),
                              if (_jobDetails!['status']?.toLowerCase() ==
                                      'completed' ||
                                  _jobDetails!['status']?.toLowerCase() ==
                                      'payment_confirmed')
                                const SizedBox(height: 24),

                              // Segment 5: Posted By / Assigned To
                              _buildPostedBySection(),
                              const SizedBox(height: 24),

                              // Segment 5: Job Action Buttons
                              _buildJobActionButtons(context),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
            AppNavigationBar(
              currentTab: NavigationTab.activity,
              userType: UserType.helper,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Loading job details...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load job details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segment 1: Main Job Details
  Widget _buildMainJobDetails() {
    if (_jobDetails == null) return Container();

    // Get status color and text
    Color statusColor = _getStatusColor(_jobDetails!['status']);
    String statusText = _getStatusText(_jobDetails!['status']);

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
          // Header with Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job details',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Request Type Label
                  Row(
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
                        _jobDetails!['is_private'] == true
                            ? 'PRIVATE'
                            : 'PUBLIC',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _jobDetails!['is_private'] == true
                              ? AppColors.primaryGreen
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Job Type
          _buildDetailRow(
              'Job Type',
              _jobDetails!['job_category_name'] ??
                  _jobDetails!['category_name'] ??
                  _jobDetails!['category'] ??
                  'General Services'),
          const SizedBox(height: 12),

          // 2. Job Hourly Rate
          _buildDetailRow('Hourly Rate',
              'LKR ${_jobDetails!['hourly_rate'] ?? '2,500'} / Hour'),
          const SizedBox(height: 12),

          // 3. Job Date
          _buildDetailRow(
              'Date', _formatDate(_jobDetails!['date']) ?? 'Not specified'),
          const SizedBox(height: 12),

          // 4. Job Time
          _buildDetailRow(
              'Time', _formatTime(_jobDetails!['time']) ?? 'Not specified'),
          const SizedBox(height: 12),

          // 5. Job Location
          _buildDetailRow(
              'Location', _jobDetails!['location'] ?? 'Not specified'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'started':
        return AppColors.primaryGreen;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'started':
        return 'ONGOING';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final date = DateTime.parse(dateString);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${date.day}${_getDayOfMonthSuffix(date.day)} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getDayOfMonthSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  // Segment 2: Job Questions
  Widget _buildJobQuestions() {
    if (_jobDetails == null) return Container();

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
            'Job Questions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questions created by the admin and answered by the helpee',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
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
                    'Q${index + 1}: $questionText',
                    'A: $answerText',
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  // Segment 3: Job Additional Details
  Widget _buildJobAdditionalDetails() {
    if (_jobDetails == null) return Container();

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
            'Job Additional Details',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Job Description
          Text(
            'Job Description',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _jobDetails!['description'] ??
                'No description provided for this job.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          // Special Instructions (if available)
          if (_jobDetails!['special_instructions'] != null &&
              _jobDetails!['special_instructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Special Instructions',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _jobDetails!['special_instructions'],
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // Estimated Hours (if available)
          if (_jobDetails!['estimated_hours'] != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Estimated Duration',
                '${_jobDetails!['estimated_hours']} hours'),
          ],
        ],
      ),
    );
  }

  // Segment 4: Payment Details (for completed jobs)
  Widget _buildPaymentDetails() {
    if (_jobDetails == null) return Container();

    // Get calculated payment amount or calculate it
    final hourlyRateValue = _jobDetails?['hourly_rate'];
    final hourlyRate =
        (hourlyRateValue is num) ? hourlyRateValue.toDouble() : 1000.0;
    final totalSecondsValue = _jobDetails?['total_time_seconds'];
    final totalSeconds =
        (totalSecondsValue is num) ? totalSecondsValue.toInt() : 0;

    // Calculate payment amount
    final calculatedAmount =
        CashPaymentService.calculatePaymentAmount(totalSeconds, hourlyRate);
    final paymentAmountFromDb = _jobDetails?['payment_amount_calculated'];
    final paymentAmount = paymentAmountFromDb ?? calculatedAmount;

    // Get payment confirmation status
    final helpeeConfirmed =
        _jobDetails?['helpee_payment_confirmation'] ?? false;
    final helperConfirmed =
        _jobDetails?['helper_payment_confirmation'] ?? false;
    final disputed = _jobDetails?['payment_dispute_reported'] ?? false;

    // Determine payment status
    String paymentStatus;
    Color statusColor;
    String statusText;

    if (disputed) {
      paymentStatus = 'DISPUTED';
      statusColor = Colors.orange;
      statusText = 'Payment Disputed';
    } else if (helpeeConfirmed && helperConfirmed) {
      paymentStatus = 'COMPLETED';
      statusColor = AppColors.success;
      statusText = 'Payment Confirmed';
    } else if (helpeeConfirmed && !helperConfirmed) {
      paymentStatus = 'WAITING_HELPER';
      statusColor = Colors.blue;
      statusText = 'Waiting for Helper';
    } else {
      paymentStatus = 'PENDING';
      statusColor = AppColors.warning;
      statusText = 'Payment Required';
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
                'Payment Details',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  paymentStatus,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment calculation breakdown
          _buildPaymentDetailRow('Hours Worked',
              '${(totalSeconds / 3600.0).toStringAsFixed(2)} hours'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow(
              'Hourly Rate', 'LKR ${hourlyRate.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Payment Method', 'Cash Payment'),
          const Divider(height: 24, color: AppColors.borderLight),
          _buildPaymentDetailRow(
              'Total Amount', 'LKR ${paymentAmount.toStringAsFixed(2)}',
              isTotal: true),

          const SizedBox(height: 16),

          // Payment status information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  disputed
                      ? Icons.warning
                      : (helpeeConfirmed && helperConfirmed)
                          ? Icons.check_circle
                          : helperConfirmed
                              ? Icons.hourglass_empty
                              : Icons.payment,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disputed
                        ? 'Payment is under review due to a dispute.'
                        : (helpeeConfirmed && helperConfirmed)
                            ? 'Payment confirmed by both parties.'
                            : 'Payment confirmation will be handled automatically.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment confirmation status (read-only display)
          // Note: Payment confirmations are now handled automatically through the coordinated flow
          // when helper completes the job. No manual buttons needed here.
        ],
      ),
    );
  }

  // Segment 5: Posted By / Assigned To
  Widget _buildPostedBySection() {
    if (_helpeeProfile == null) {
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
              'Posted By',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Helpee information not available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
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
          Text(
            'Posted By',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Helpee Profile Bar with real data
          HelpeeProfileBar(
            name:
                '${_helpeeProfile!['first_name'] ?? ''} ${_helpeeProfile!['last_name'] ?? ''}'
                    .trim(),
            serviceType: null, // Remove service type display
            profileImageUrl: _helpeeProfile!['profile_image_url'],
            onTap: () {
              // Navigate to helpee profile page
              context.push('/helper/helpee-profile', extra: {
                'helpeeId': _helpeeProfile!['id'],
                'helpeeData': _helpeeProfile,
                'helpeeStats': _helpeeStatistics,
              });
            },
          ),

          // Contact buttons integrated into Posted By section
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Segment 5: Timer and Job Actions
  Widget _buildJobActionButtons(BuildContext context) {
    if (_jobDetails == null) return const SizedBox.shrink();

    final status = _jobDetails!['status']?.toLowerCase() ?? '';
    // Timer widget should show for jobs that are accepted or in progress
    final shouldShowTimer =
        ['accepted', 'started', 'in_progress', 'paused'].contains(status);
    final currentUser = _authService.currentUser;
    final helperId = currentUser?['user_id'];

    return Column(
      children: [
        // Job Status Indicator (shows loading hourglass for in-progress jobs)
        if (shouldShowTimer && helperId != null) ...[
          JobStatusIndicator(
            jobTitle: _jobDetails!['title'] ?? 'Job',
            helperName: _jobDetails!['helper_first_name'] ?? '',
            status: status,
            jobDetails: _jobDetails,
          ),
          const SizedBox(height: 24),
        ],

        // Action Buttons (shows Start Job button for accepted jobs, other actions for other statuses)
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
              Text(
                'Actions',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Use the dynamic JobActionButtons widget
              JobActionButtons(
                job: _jobDetails!,
                userType: 'helper',
                onJobUpdated: () {
                  _loadJobDetails(); // Reload job details when status changes
                },
                showTimer:
                    false, // Timer functionality handled by separate timer widget
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildPaymentDetailRow(String label, String value,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isTotal ? AppColors.primaryGreen : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

  Widget _buildAttachmentItem(String fileName, String fileSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attachment,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  fileSize,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Open attachment
            },
            icon: const Icon(
              Icons.download,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Accept Job Request'),
          content: const Text(
              'Are you sure you want to accept this job? You will be committed to completing this work on the specified date and time.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _acceptJob(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context) {
    final isPrivate = _jobDetails?['is_private'] == true;
    final actionTitle = isPrivate ? 'Reject Job Request' : 'Ignore Job Request';
    final actionMessage = isPrivate
        ? 'Are you sure you want to reject this job? This action cannot be undone.'
        : 'Are you sure you want to ignore this job? It will not appear in your job list again.';
    final actionButtonText = isPrivate ? 'Reject' : 'Ignore';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(actionTitle),
          content: Text(actionMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _rejectJob(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text(actionButtonText),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await _jobDetailService.acceptJob(widget.jobId, userId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted! Moving to ongoing jobs.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate to activity ongoing page
        context.go('/helper/activity/ongoing');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept job. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _rejectJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final isPrivate = _jobDetails?['is_private'] ?? false;

      if (isPrivate) {
        // Reject private job
        final success = await _jobDetailService.rejectJob(widget.jobId, userId);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job rejected.'),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject job. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      } else {
        // Ignore public job
        final success = await _jobDetailService.ignoreJob(widget.jobId, userId);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Job ignored. It won\'t appear in your list again.'),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to ignore job. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      // Navigate back to requests
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await _jobDetailService.startJob(widget.jobId);

      if (success) {
        // Start the timer when job is started
        try {
          await SimpleTimeTrackingService.startJob(widget.jobId);
          print('✅ Job timing started for job: ${widget.jobId}');
        } catch (timerError) {
          print('⚠️ Job timing start failed but job was started: $timerError');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started! Timer is now running.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload the job details to update the UI
        _loadJobDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start job. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _pauseJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final success = await _jobDetailService.pauseJob(widget.jobId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job paused.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadJobDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completeJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Complete the timer first
      try {
        final success =
            await SimpleTimeTrackingService.completeJob(widget.jobId);
        if (success) {
          print('✅ Job timing completed successfully for job: ${widget.jobId}');
        } else {
          print('⚠️ Job timing completion failed');
        }
      } catch (timerError) {
        print(
            '⚠️ Job timing completion failed but continuing with job completion: $timerError');
      }

      // Use JobDataService for safer completion (avoids database RPC issues)
      final success = await _jobDataService.completeJob(widget.jobId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed! Starting payment confirmation...'),
            backgroundColor: AppColors.success,
          ),
        );

        // Start the payment confirmation flow for both users
        await _paymentFlowService.startPaymentConfirmationFlow(widget.jobId);

        print('✅ Payment confirmation flow started for job: ${widget.jobId}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete job. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
