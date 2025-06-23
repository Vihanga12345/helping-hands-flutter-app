import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helpee_profile_bar.dart';

class HelperComprehensiveJobDetailPage extends StatelessWidget {
  const HelperComprehensiveJobDetailPage({super.key});

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
                    // Segment 1: Main Job Details
                    _buildMainJobDetails(),
                    const SizedBox(height: 24),

                    // Segment 2: Job Questions
                    _buildJobQuestions(),
                    const SizedBox(height: 24),

                    // Segment 3: Job Additional Details
                    _buildJobAdditionalDetails(),
                    const SizedBox(height: 24),

                    // Segment 4: Posted By / Assigned To
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

  // Segment 1: Main Job Details
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
          // Header with Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Main Job Details',
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

          // 1. Job Type
          _buildDetailRow('Job Type', 'General House Cleaning'),
          const SizedBox(height: 12),

          // 2. Job Hourly Rate
          _buildDetailRow('Hourly Rate', 'LKR 2,500 / Hour'),
          const SizedBox(height: 12),

          // 3. Job Date
          _buildDetailRow('Date', '21st May 2024'),
          const SizedBox(height: 12),

          // 4. Job Time
          _buildDetailRow('Time', '2:00 PM - 5:00 PM'),
          const SizedBox(height: 12),

          // 5. Job Location
          _buildDetailRow('Location', 'Colombo 03, 1.5 km away'),
        ],
      ),
    );
  }

  // Segment 2: Job Questions
  Widget _buildJobQuestions() {
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
          _buildQuestionAnswer('Q1: How many rooms need to be cleaned?',
              'A: 3 bedrooms, 2 bathrooms, kitchen, and living room'),
          const SizedBox(height: 12),
          _buildQuestionAnswer('Q2: Do you have cleaning supplies available?',
              'A: Yes, all cleaning supplies are available at home'),
          const SizedBox(height: 12),
          _buildQuestionAnswer('Q3: Any specific cleaning requirements?',
              'A: Deep cleaning required, especially bathrooms and kitchen'),
          const SizedBox(height: 12),
          _buildQuestionAnswer('Q4: Pets in the house?', 'A: No pets'),
        ],
      ),
    );
  }

  // Segment 3: Job Additional Details
  Widget _buildJobAdditionalDetails() {
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
            'I need a thorough deep cleaning of my 3-bedroom house. This includes cleaning all bathrooms, kitchen, bedrooms, and common areas. Please pay special attention to the bathrooms and kitchen as they need deep cleaning. All cleaning supplies are available at home.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Attachments
          Text(
            'Attachments',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Attachment items
          _buildAttachmentItem('House_photos.jpg', '2.1 MB'),
          const SizedBox(height: 8),
          _buildAttachmentItem('Room_layout.pdf', '1.5 MB'),
          const SizedBox(height: 8),
          _buildAttachmentItem('Cleaning_requirements.pdf', '890 KB'),
        ],
      ),
    );
  }

  // Segment 4: Posted By / Assigned To
  Widget _buildPostedBySection() {
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

          // Helpee Profile Bar
          HelpeeProfileBar(
            name: 'Sarah Wilson',
            rating: 4.8,
            jobCount: 24,
            profileImageUrl: 'assets/images/profile_placeholder.png',
            onTap: () {
              // Navigate to helpee profile page
            },
          ),
          const SizedBox(height: 12),

          // Contact buttons
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

  // Segment 5: Job Action Buttons
  Widget _buildJobActionButtons(BuildContext context) {
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

          // For Pending Job requests - Accept/Reject buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showRejectDialog(context);
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
                    'Reject',
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
                    _showAcceptDialog(context);
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
                    'Accept Job',
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

  // Helper widgets
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reject Job Request'),
          content: const Text(
              'Are you sure you want to reject this job? This action cannot be undone.'),
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
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job accepted! Moving to ongoing jobs.'),
        backgroundColor: AppColors.success,
      ),
    );
    // Navigate to activity ongoing page
    context.go('/helper/activity/ongoing');
  }

  void _rejectJob(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job rejected.'),
        backgroundColor: AppColors.error,
      ),
    );
    // Navigate back to requests
    context.pop();
  }
}
