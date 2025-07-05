import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/helper_data_service.dart';

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
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _jobDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    if (widget.jobId != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final jobDetails =
            await _jobDataService.getJobDetailsWithQuestions(widget.jobId!);
        setState(() {
          _jobDetails = jobDetails;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to load job details: $e';
          _isLoading = false;
        });
      }
    } else if (widget.jobData != null) {
      setState(() {
        _jobDetails = widget.jobData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'No job ID or data provided';
        _isLoading = false;
      });
    }
  }

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
              title: 'Job Details',
              showBackButton: true,
              showMenuButton: true,
              showNotificationButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainJobDetails(),
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
          _buildDetailRow(
              'Completed Date', _jobDetails?['scheduled_date'] ?? 'Not set'),
          const SizedBox(height: 12),
          _buildDetailRow('Completion Time',
              _jobDetails?['actual_end_time'] ?? 'Not recorded'),
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
    // Safely access payment details from the _jobDetails map
    final serviceCost =
        _jobDetails?['service_cost']?.toStringAsFixed(2) ?? '0.00';
    final platformFee =
        _jobDetails?['platform_fee']?.toStringAsFixed(2) ?? '0.00';
    final tax = _jobDetails?['tax']?.toStringAsFixed(2) ?? '0.00';
    final totalPaid = _jobDetails?['total_paid']?.toStringAsFixed(2) ?? '0.00';
    final paymentStatus = _jobDetails?['payment_status'] ?? 'UNPAID';

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
                  color: paymentStatus == 'paid'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  paymentStatus.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: paymentStatus == 'paid'
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentDetailRow('Service Cost', 'LKR $serviceCost'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Platform Fee', 'LKR $platformFee'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Tax', 'LKR $tax'),
          const Divider(height: 24, color: AppColors.borderLight),
          _buildPaymentDetailRow('Total Paid', 'LKR $totalPaid', isTotal: true),
        ],
      ),
    );
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
            rating: (_jobDetails?['helper_avg_rating'] is num)
                ? (_jobDetails!['helper_avg_rating'] as num).toDouble()
                : 0.0,
            jobCount: (_jobDetails?['helper_completed_jobs'] is num)
                ? (_jobDetails!['helper_completed_jobs'] as num).toInt()
                : 0,
            jobTypes: _jobDetails?['helper_job_types'] != null
                ? _jobDetails!['helper_job_types'].toString().split(' • ')
                : ['${_jobDetails?['category_name'] ?? 'General Service'}'],
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
              onPressed: () => _showReportDialog(context),
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
                'Report Issue',
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
                      'Select the type of issue:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Report reasons specific to helpee
                    _buildReportOption('Helper did not complete job properly',
                        selectedReason, setState),
                    _buildReportOption(
                        'Helper behavior issue', selectedReason, setState),
                    _buildReportOption('Quality of work unsatisfactory',
                        selectedReason, setState),
                    _buildReportOption('Helper was late or unreliable',
                        selectedReason, setState),
                    _buildReportOption('Other issue', selectedReason, setState),

                    const SizedBox(height: 16),
                    Text(
                      'Additional details:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Please provide more details about the issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
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
                            const SnackBar(
                              content: Text('Report submitted successfully'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(
                    'Submit Report',
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
    return RadioListTile<String>(
      title: Text(
        option,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      value: option,
      groupValue: selectedReason,
      onChanged: (value) {
        setState(() {
          selectedReason = value;
        });
      },
      activeColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
    );
  }
}
