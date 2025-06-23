import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';

class HelpeeJobDetailPendingPage extends StatelessWidget {
  const HelpeeJobDetailPendingPage({super.key});

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
                    _buildJobDescription(),
                    const SizedBox(height: 24),
                    _buildJobRequirements(),
                    const SizedBox(height: 24),
                    _buildHelperApplications(context),
                    const SizedBox(height: 24),
                    _buildPendingJobActions(context),
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
                'Your Job Request',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PENDING',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
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
          const SizedBox(height: 12),
          _buildDetailRow('Posted', '2 hours ago'),
        ],
      ),
    );
  }

  Widget _buildJobDescription() {
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
            'Job Description',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'I need a thorough deep cleaning of my 3-bedroom house. This includes cleaning all bathrooms, kitchen, bedrooms, and common areas. Please pay special attention to the bathrooms and kitchen as they need deep cleaning.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Attachments',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildAttachmentItem('House_photos.jpg', '2.1 MB'),
          const SizedBox(height: 8),
          _buildAttachmentItem('Cleaning_requirements.pdf', '890 KB'),
        ],
      ),
    );
  }

  Widget _buildJobRequirements() {
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
            'Job Requirements',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequirementItem('Experience required: 2+ years'),
          _buildRequirementItem('Own cleaning supplies preferred'),
          _buildRequirementItem('Deep cleaning expertise'),
          _buildRequirementItem('Professional references available'),
        ],
      ),
    );
  }

  Widget _buildHelperApplications(BuildContext context) {
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
            'Helper Applications (3)',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Helper Application 1
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

          // Helper Application 2
          HelperProfileBar(
            name: 'Maria Garcia',
            rating: 4.8,
            jobCount: 98,
            profileImageUrl: 'assets/images/profile_placeholder.png',
            onTap: () {
              context.push('/helpee/helper-profile');
            },
          ),
          const SizedBox(height: 12),

          // Helper Application 3
          HelperProfileBar(
            name: 'David Chen',
            rating: 4.7,
            jobCount: 76,
            profileImageUrl: 'assets/images/profile_placeholder.png',
            onTap: () {
              context.push('/helpee/helper-profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingJobActions(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showCancelDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Cancel Job',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/helpee/job-request/edit');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Edit Request',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildAttachmentItem(String filename, String size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filename,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            size,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cancel Job Request',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this job request? This action cannot be undone.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Job',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job request cancelled'),
                    backgroundColor: AppColors.error,
                  ),
                );
                context.go('/helpee/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                'Cancel Job',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
 