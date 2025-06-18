import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helpee_profile_bar.dart';

class HelperJobDetailPage extends StatefulWidget {
  final String jobId;
  final String jobType; // 'private' or 'public'

  const HelperJobDetailPage({
    super.key,
    this.jobId = 'JOB001',
    this.jobType = 'private',
  });

  @override
  State<HelperJobDetailPage> createState() => _HelperJobDetailPageState();
}

class _HelperJobDetailPageState extends State<HelperJobDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Job Details',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                rightWidget: IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job saved')),
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Job Header with Status
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'HIGH PRIORITY',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: widget.jobType == 'private'
                                        ? AppColors.primaryGreen
                                            .withOpacity(0.1)
                                        : AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.jobType == 'private'
                                        ? 'PRIVATE REQUEST'
                                        : 'PUBLIC REQUEST',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: widget.jobType == 'private'
                                          ? AppColors.primaryGreen
                                          : AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'House Deep Cleaning',
                              style: AppTextStyles.heading2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Job ID: ${widget.jobId}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Basic Job Information
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
                              'Job Information',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(Icons.location_on, 'Location',
                                'Colombo 07, Horton Place'),
                            _buildDetailRow(Icons.schedule, 'Date & Time',
                                'Dec 25, 2024 at 9:00 AM'),
                            _buildDetailRow(
                                Icons.timer, 'Duration', '6 hours (estimated)'),
                            _buildDetailRow(Icons.payment, 'Payment',
                                'LKR 5,000 (Fixed Rate)'),
                            _buildDetailRow(
                                Icons.work, 'Job Type', 'House Cleaning'),
                            _buildDetailRow(Icons.person_outline,
                                'Experience Required', '2+ years'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Detailed Job Description
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
                              'Job Description',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Deep cleaning of 5-bedroom luxury villa including all rooms, bathrooms, kitchen, and pool area. Special attention needed for marble surfaces and expensive furnishings. Must bring own cleaning supplies and equipment.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Requirements:',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRequirement('3+ years cleaning experience'),
                            _buildRequirement('Own cleaning equipment'),
                            _buildRequirement('Available on weekends'),
                            _buildRequirement('References required'),
                            _buildRequirement(
                                'Able to work with expensive items'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Job Questions and Answers
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
                              'Questions & Answers',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            _buildQnA(
                              'Do you have experience with marble cleaning?',
                              'Yes, I have extensive experience with natural stone surfaces and use appropriate pH-neutral cleaners.',
                            ),
                            _buildQnA(
                              'Can you provide your own cleaning supplies?',
                              'Yes, I bring all professional-grade cleaning supplies and equipment.',
                            ),
                            _buildQnA(
                              'Are you available for weekend work?',
                              'Yes, I am available on weekends and can work flexible hours.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Job Attachments
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
                              'Attachments',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            _buildAttachment('House Layout Plan.pdf', 'PDF',
                                Icons.picture_as_pdf),
                            _buildAttachment(
                                'Room Photos.jpg', 'Image', Icons.image),
                            _buildAttachment('Cleaning Instructions.docx',
                                'Document', Icons.description),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Helpee Information
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
                              'Posted by',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            HelpeeProfileBar(
                              name: 'Sarah Johnson',
                              rating: 4.9,
                              jobCount: 42,
                              onMessage: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Opening chat with helpee')),
                                );
                              },
                              onCall: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Calling helpee')),
                                );
                              },
                              onTap: () {
                                context.push('/helper/helpee-profile');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons - Different for Private vs Public
                      _buildActionButtons(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.activity,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
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
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQnA(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A: $answer',
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(String fileName, String type, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening $fileName')),
              );
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.jobType == 'private') {
      // Private requests: Accept + Reject buttons
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Reject',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAcceptDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Accept',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sending message to helpee')),
                );
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message Helpee'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      // Public requests: Accept + Ignore buttons
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showIgnoreDialog(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Ignore',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAcceptDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Accept',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sending message to helpee')),
                );
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message Helpee'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Job Request'),
          content: const Text(
              'Are you sure you want to accept this job? You will be committed to completing this work.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptJob();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Job Request'),
          content:
              const Text('Are you sure you want to reject this job request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectJob();
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

  void _showIgnoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ignore Job Request'),
          content: const Text(
              'This job will be removed from your feed and you won\'t see it again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ignoreJob();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Ignore'),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job accepted! Moving to ongoing jobs.'),
        backgroundColor: AppColors.success,
      ),
    );

    // Navigate to ongoing tab in activity page
    context.go('/helper/activity/ongoing');
  }

  void _rejectJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job request rejected.'),
        backgroundColor: AppColors.error,
      ),
    );

    // Navigate back to pending tab
    context.go('/helper/activity/pending');
  }

  void _ignoreJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job request ignored.'),
        backgroundColor: AppColors.textSecondary,
      ),
    );

    // Navigate back to view requests
    if (widget.jobType == 'public') {
      context.go('/helper/view-requests/public');
    } else {
      context.go('/helper/view-requests/private');
    }
  }
}
