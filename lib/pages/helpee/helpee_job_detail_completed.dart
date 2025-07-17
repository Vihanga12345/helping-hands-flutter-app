import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/job_detail_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/helper_data_service.dart';
import '../../services/localization_service.dart';
import '../common/report_page.dart';
import '../../services/cash_payment_service.dart';
import '../../services/user_data_service.dart';
// Removed cash_payment_confirmation_dialog import - handled by coordinated flow

class HelpeeJobDetailCompletedPage extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const HelpeeJobDetailCompletedPage({
    super.key,
    this.jobId,
    this.jobData,
  });

  @override
  State<HelpeeJobDetailCompletedPage> createState() =>
      _HelpeeJobDetailCompletedPageState();
}

class _HelpeeJobDetailCompletedPageState
    extends State<HelpeeJobDetailCompletedPage> {
  final JobDataService _jobDataService = JobDataService();
  final JobDetailService _jobDetailService = JobDetailService();
  final CustomAuthService _authService = CustomAuthService();
  final UserDataService _userDataService = UserDataService();

  Map<String, dynamic>? _jobDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
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
          // Removed automatic payment popup - now handled by coordinated flow
        }
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
        // Removed automatic payment popup - now handled by coordinated flow
      }
    } else {
      if (mounted) {
        setState(() {
          _error = 'No job ID or data provided';
          _isLoading = false;
        });
      }
    }
  }

  // Removed _checkAndShowPaymentPopup() - payment confirmations now handled by coordinated flow

  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours} hours ${minutes} minutes';
  }

  String _calculateTotalCost() {
    if (_jobDetails == null) return 'LKR 0.00';

    final hourlyRateValue = _jobDetails!['hourly_rate'];
    final hourlyRate =
        (hourlyRateValue is num) ? hourlyRateValue.toDouble() : 0.0;
    final totalSecondsValue = _jobDetails!['total_time_seconds'];
    final totalSeconds =
        (totalSecondsValue is num) ? totalSecondsValue.toInt() : 0;
    final elapsedHours = totalSeconds / 3600.0;
    final totalCost = (hourlyRate * elapsedHours).toStringAsFixed(2);
    return 'LKR $totalCost';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Completed Job'.tr(),
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
                                  _buildJobSummary(),
                                  const SizedBox(height: 24),
                                  _buildPaymentDetails(),
                                  const SizedBox(height: 24),
                                  _buildHelperPerformance(),
                                  const SizedBox(height: 24),
                                  _buildHelperSection(context),
                                  const SizedBox(height: 24),
                                  _buildCompletedJobActions(context),
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
                  'COMPLETED',
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
          _buildDetailRow('Completed Date', _jobDetails?['date'] ?? 'Not set'),
          const SizedBox(height: 12),
          _buildDetailRow(
              'Completion Time', _jobDetails?['time'] ?? 'Not recorded'),
          const SizedBox(height: 12),
          _buildDetailRow('Location',
              _jobDetails?['location_address'] ?? 'Location not provided'),
        ],
      ),
    );
  }

  Widget _buildJobSummary() {
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
            'Job Summary',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Start Time',
              _jobDetails?['actual_start_time'] ?? 'Not recorded'),
          const SizedBox(height: 12),
          _buildDetailRow(
              'End Time', _jobDetails?['actual_end_time'] ?? 'Not recorded'),
          const SizedBox(height: 12),
          _buildDetailRow('Total Time',
              _formatElapsedTime(_jobDetails?['total_time_seconds'] ?? 0)),
          const SizedBox(height: 12),
          _buildDetailRow('Total Cost', _calculateTotalCost()),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
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
    final helpeeConfirmed = _jobDetails?['helpee_payment_confirmed'] ?? false;
    final helperConfirmed = _jobDetails?['helper_payment_received'] ?? false;
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
                'Payment Details'.tr(),
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
          _buildPaymentDetailRow('Hours Worked'.tr(),
              '${(totalSeconds / 3600.0).toStringAsFixed(2)} hours'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow(
              'Hourly Rate'.tr(), 'LKR ${hourlyRate.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Payment Method'.tr(), 'Cash Payment'.tr()),
          const Divider(height: 24, color: AppColors.borderLight),
          _buildPaymentDetailRow(
              'Total Amount'.tr(), 'LKR ${paymentAmount.toStringAsFixed(2)}',
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
                          : helpeeConfirmed
                              ? Icons.hourglass_empty
                              : Icons.payment,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disputed
                        ? 'Payment is under review due to a dispute.'.tr()
                        : (helpeeConfirmed && helperConfirmed)
                            ? 'Payment confirmed by both parties.'.tr()
                            : 'Payment confirmation will be handled automatically.'
                                .tr(),
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

  Future<void> _initiatePaymentConfirmation() async {
    if (_jobDetails == null || widget.jobId == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Initiate payment confirmation process
      final paymentData =
          await CashPaymentService.initiateCashPaymentConfirmation(
              widget.jobId!);

      // Close loading dialog
      Navigator.of(context).pop();

      if (paymentData != null && paymentData['success'] == true) {
        // Get current user ID
        final currentUser = await _userDataService.getCurrentUserProfile();
        final currentUserId = currentUser?['id'];

        if (currentUserId != null) {
          // Payment confirmation now handled by coordinated flow - no manual trigger needed
          print('Payment confirmation handled by coordinated flow');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate payment confirmation.'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHelperPerformance() {
    // Safely access rating and review from the _jobDetails map
    final ratingData = _jobDetails?['helpee_rating_review'];
    final rating = (ratingData?['rating'] as num?)?.toDouble() ?? 0.0;
    final review = ratingData?['review_text'] as String?;

    // If there is no rating, don't show this card
    if (ratingData == null) {
      return const SizedBox.shrink();
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
            'Your Rating & Review',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Rating given
          Row(
            children: [
              Text(
                'Your Rating: ',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (review != null && review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Your Review:',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelperSection(BuildContext context) {
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
            'Helper Details',
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
                : 'Helper Name',
            jobTypes: [], // Remove job types display
            profileImageUrl: _jobDetails?['helper_profile_pic'],
            helperId: _jobDetails?['assigned_helper_id'],
            onTap: () {
              final helperId = _jobDetails?['assigned_helper_id'];
              if (helperId != null && helperId.isNotEmpty) {
                context.push('/helpee/helper-profile-detailed', extra: {
                  'helperId': helperId,
                });
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/helpee/job-request');
              },
              icon: const Icon(Icons.repeat, size: 18),
              label: const Text('Book Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobActions(BuildContext context) {
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
            'Actions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportPage(userType: 'helpee'),
                ),
              ),
              icon: const Icon(Icons.report_problem, size: 18),
              label: const Text('Report Issue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildPaymentDetailRow(String label, String amount,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppColors.primaryGreen : AppColors.textPrimary,
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
            'Job Questions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questions and answers for this job',
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
    // Null safety check
    if (_jobDetails == null) {
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
            Text(
              'Loading Additional Details...',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w600,
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
                'Job Additional Details',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_jobDetails!['description'] != null &&
              _jobDetails!['description'].toString().isNotEmpty) ...[
            Text(
              'Job Description',
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
                _jobDetails!['description'].toString(),
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

  Widget _buildErrorState() {
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
            'Error loading job details',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred.',
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
}
