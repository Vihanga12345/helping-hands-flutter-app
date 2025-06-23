import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';

class HelpeeJobDetailCompletedPage extends StatelessWidget {
  const HelpeeJobDetailCompletedPage({super.key});

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          _buildDetailRow('Job Type', 'General House Cleaning'),
          const SizedBox(height: 12),
          _buildDetailRow('Completed Date', '21st May 2024'),
          const SizedBox(height: 12),
          _buildDetailRow('Completion Time', '5:30 PM'),
          const SizedBox(height: 12),
          _buildDetailRow('Location', 'Colombo 03'),
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
          _buildDetailRow('Start Time', '2:00 PM'),
          const SizedBox(height: 12),
          _buildDetailRow('End Time', '5:30 PM'),
          const SizedBox(height: 12),
          _buildDetailRow('Total Time', '3 hours 30 minutes'),
          const SizedBox(height: 12),
          _buildDetailRow('Total Cost', 'LKR 8,750.00'),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PAID',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentDetailRow('Service Cost', 'LKR 8,750.00'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Platform Fee', 'LKR 875.00'),
          const SizedBox(height: 8),
          _buildPaymentDetailRow('Tax', 'LKR 192.50'),
          const Divider(height: 24, color: AppColors.borderLight),
          _buildPaymentDetailRow('Total Paid', 'LKR 9,817.50', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildHelperPerformance() {
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
                    index < 5 ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '5.0',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review given
          Text(
            'Your Review:',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excellent work! The house was cleaned thoroughly and professionally. Very satisfied with the service. Would definitely hire again!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
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
            name: 'John Smith',
            rating: 4.9,
            jobCount: 156,
            profileImageUrl: 'assets/images/profile_placeholder.png',
            onTap: () {
              context.push('/helpee/helper-profile');
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

  Widget _buildPaymentDetailRow(String label, String amount, {bool isTotal = false}) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    _buildReportOption('Helper did not complete job properly', selectedReason, setState),
                    _buildReportOption('Helper behavior issue', selectedReason, setState),
                    _buildReportOption('Quality of work unsatisfactory', selectedReason, setState),
                    _buildReportOption('Helper was late or unreliable', selectedReason, setState),
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
                        hintText: 'Please provide more details about the issue...',
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
                  onPressed: selectedReason != null ? () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  } : null,
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

  Widget _buildReportOption(String option, String? selectedReason, StateSetter setState) {
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