import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_type.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/cash_payment_service.dart';
import '../../services/job_data_service.dart';
import '../../services/simple_time_tracking_service.dart'; // Added for real duration data
import '../../services/custom_auth_service.dart';
import '../../services/popup_state_service.dart';
import '../../services/supabase_service.dart';
import '../common/report_page.dart';

class HelperPaymentConfirmationPage extends StatefulWidget {
  final String jobId;

  const HelperPaymentConfirmationPage({
    super.key,
    required this.jobId,
  });

  @override
  State<HelperPaymentConfirmationPage> createState() =>
      _HelperPaymentConfirmationPageState();
}

class _HelperPaymentConfirmationPageState
    extends State<HelperPaymentConfirmationPage> {
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _jobDetails;
  Map<String, dynamic>? _paymentDetails; // Added for real payment data
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load both job details and payment details
      final jobDetailsFuture =
          _jobDataService.getJobDetailsWithQuestions(widget.jobId);
      final paymentDetailsFuture =
          SimpleTimeTrackingService.getPaymentDetails(widget.jobId);

      final results =
          await Future.wait([jobDetailsFuture, paymentDetailsFuture]);
      final jobDetails = results[0] as Map<String, dynamic>?;
      final paymentDetails = results[1] as Map<String, dynamic>?;

      if (jobDetails != null) {
        setState(() {
          _jobDetails = jobDetails;
          _paymentDetails = paymentDetails;
          _isLoading = false;
        });

        // Log payment details for debugging
        if (paymentDetails != null) {
          print('✅ Payment details loaded:');
          print('   Duration: ${paymentDetails['duration_text']}');
          print('   Final Amount: LKR ${paymentDetails['final_amount']}');
        } else {
          print('⚠️ No payment details found - using estimated data');
        }
      } else {
        setState(() {
          _error = 'Job details not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load job details: $e';
        _isLoading = false;
      });
      print('❌ Error loading payment confirmation data: $e');
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes minutes';
      }
    }
  }

  // Get calculated total cost from real payment data
  double _calculateTotalCost() {
    // Use ONLY real calculated amount from database
    if (_paymentDetails != null && _paymentDetails!['final_amount'] != null) {
      return (_paymentDetails!['final_amount'] as num).toDouble();
    }

    // If no calculated data available, return 0 (should not happen for completed jobs)
    print('⚠️ No calculated payment data available for completed job');
    return 0.0;
  }

  // Get ONLY real calculated duration (no estimated text)
  String _getDurationText() {
    // Use ONLY real calculated duration from database
    if (_paymentDetails != null && _paymentDetails!['duration_text'] != null) {
      return _paymentDetails!['duration_text'];
    }

    // If no calculated duration, show warning (should not happen for completed jobs)
    print('⚠️ No calculated duration data available for completed job');
    return 'Duration not calculated';
  }

  Future<void> _handlePaymentReceived() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final success = await CashPaymentService.confirmHelperPaymentReceived(
        widget.jobId,
        currentUser['user_id'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment received confirmation sent! Waiting for helpee confirmation...'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to rating page
        context.go('/helper/rating/${widget.jobId}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to confirm payment received. Please try again.'),
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
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleReportIssue() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportPage(userType: 'helper'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Payment Confirmation',
            showBackButton: false,
            showMenuButton: true,
            showNotificationButton: true,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.backgroundGradient,
                ),
              ),
              child: _buildPaymentConfirmationContent(),
            ),
          ),
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helper,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: Center(
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
                'Error Loading Job Details',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
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
              ElevatedButton(
                onPressed: () => context.go('/helper/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentConfirmationContent() {
    final helpeeName = _jobDetails?['helpee'] != null
        ? '${_jobDetails!['helpee']['first_name']} ${_jobDetails!['helpee']['last_name']}'
        : 'the helpee';

    final workTimeMinutes =
        (_jobDetails!['total_work_time_minutes'] as num?)?.toInt() ?? 0;

    // Handle both string and numeric values for hourly_rate
    double hourlyRate = 0.0;
    final hourlyRateValue = _jobDetails!['hourly_rate'];
    if (hourlyRateValue is String) {
      hourlyRate = double.tryParse(hourlyRateValue) ?? 0.0;
    } else if (hourlyRateValue is num) {
      hourlyRate = hourlyRateValue.toDouble();
    }

    final totalCost = _calculateTotalCost();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Completion Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'Job Completed Successfully!',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have completed the job for $helpeeName',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Job Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Details',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Job Title
                Text(
                  _jobDetails!['title'] ?? 'Unknown Job',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Duration
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getDurationText(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Hourly Rate
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hourly Rate: ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'LKR ${hourlyRate.toStringAsFixed(2)}/Hr',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Cost
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount to Receive',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${totalCost.toStringAsFixed(2)}',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Please confirm if you receive this amount from your helpee',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handlePaymentReceived,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    'Yes Received',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleReportIssue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.report_problem),
                  label: Text(
                    'Report',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.error,
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
}
