import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';

enum OngoingJobState { acceptedNotStarted, inProgress, paused }

class HelpeeJobDetailOngoingPage extends StatelessWidget {
  final OngoingJobState jobState;

  const HelpeeJobDetailOngoingPage({
    super.key,
    this.jobState = OngoingJobState.acceptedNotStarted,
  });

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
                    _buildJobStatus(),
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
          _buildDetailRow('Job Type', 'General House Cleaning'),
          const SizedBox(height: 12),
          _buildDetailRow('Hourly Rate', 'LKR 2,500 / Hour'),
          const SizedBox(height: 12),
          _buildDetailRow('Date', '21st May 2024'),
          const SizedBox(height: 12),
          _buildDetailRow('Time', '2:00 PM - 5:00 PM'),
          const SizedBox(height: 12),
          _buildDetailRow('Location', 'Colombo 03'),
        ],
      ),
    );
  }

  Widget _buildJobStatus() {
    String statusText = '';
    Color statusColor = AppColors.success;
    IconData statusIcon = Icons.access_time;

    switch (jobState) {
      case OngoingJobState.acceptedNotStarted:
        statusText = 'Waiting for Helper to Start';
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case OngoingJobState.inProgress:
        statusText = 'Job in Progress';
        statusColor = AppColors.success;
        statusIcon = Icons.play_circle;
        break;
      case OngoingJobState.paused:
        statusText = 'Job Paused';
        statusColor = AppColors.warning;
        statusIcon = Icons.pause_circle;
        break;
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
            'Job Status',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (jobState == OngoingJobState.inProgress) ...[
            const SizedBox(height: 16),
            Text(
              'Time Elapsed: 02:30:15',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Cost: LKR 6,250.00',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            'Assigned Helper',
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
            'Actions',
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
    switch (jobState) {
      case OngoingJobState.acceptedNotStarted:
        return Column(
          children: [
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
                      'Your helper will start the job shortly. You will be notified when they begin.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
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
        );

      case OngoingJobState.inProgress:
      case OngoingJobState.paused:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.track_changes, size: 18),
                    label: const Text('Track Progress'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen),
                      foregroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message Helper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
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
                    _buildReportOption('Helper is late or not showing up',
                        selectedReason, setState),
                    _buildReportOption(
                        'Helper behavior issue', selectedReason, setState),
                    _buildReportOption('Helper not following instructions',
                        selectedReason, setState),
                    _buildReportOption(
                        'Quality of work concerns', selectedReason, setState),
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
                    TextFormField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue in detail...',
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
                            SnackBar(
                              content:
                                  Text('Report submitted: $selectedReason'),
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
}
