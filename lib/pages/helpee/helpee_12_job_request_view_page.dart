import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/localization_service.dart';

class Helpee12JobRequestViewPage extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const Helpee12JobRequestViewPage({
    super.key,
    this.jobId,
    this.jobData,
  });

  @override
  State<Helpee12JobRequestViewPage> createState() =>
      _Helpee12JobRequestViewPageState();
}

class _Helpee12JobRequestViewPageState
    extends State<Helpee12JobRequestViewPage> {
  final JobDataService _jobDataService = JobDataService();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final String jobId = widget.jobId ?? widget.jobData?['id'] ?? 'JOB1001';

    return Scaffold(
      body: Column(
        children: [
          // Header with Edit button
          AppHeader(
            title: 'Job Request Details'.tr(),
            showBackButton: true,
            showMenuButton: false,
            showNotificationButton: false,
            rightWidget: GestureDetector(
              onTap: () => context.go('/helpee/job-request-edit', extra: jobId),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF8FD89F),
                  size: 18,
                ),
              ),
            ),
          ),

          // Body Content
          Expanded(
            child: Container(
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
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'House Cleaning Service',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Under Review',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Job ID: $jobId',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.primaryGreen, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Submitted: Dec 20, 2024',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.attach_money,
                                    color: AppColors.primaryGreen, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Budget: LKR 2,500',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job Details
                      _buildDetailSection(
                        title: 'Job Details',
                        children: [
                          _buildDetailItem('Service Type', 'Housekeeping'),
                          _buildDetailItem('Date', 'Dec 25, 2024'),
                          _buildDetailItem('Time', '10:00 AM - 2:00 PM'),
                          _buildDetailItem('Duration', '4 hours (estimated)'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Location Details
                      _buildDetailSection(
                        title: 'Location',
                        children: [
                          _buildDetailItem(
                              'Address', '123 Main Street, Colombo 07'),
                          _buildDetailItem(
                              'Nearest Landmark', 'Next to City Mall'),
                          _buildDetailItem(
                              'Access Instructions', 'Ring bell at main gate'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildDetailSection(
                        title: 'Description',
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: const Text(
                              'Deep cleaning of 3-bedroom apartment including kitchen and bathrooms. Need thorough cleaning of all rooms, mopping, dusting, and organizing. Special attention to kitchen appliances and bathroom tiles.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Requirements
                      _buildDetailSection(
                        title: 'Special Requirements',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildRequirementChip('Bring own supplies'),
                              _buildRequirementChip('Pet-friendly cleaner'),
                              _buildRequirementChip('Non-smoking'),
                              _buildRequirementChip('Experience required'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Images Section
                      _buildDetailSection(
                        title: 'Photos',
                        children: [
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primaryGreen),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _showCancelDialog(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Cancel Request',
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/helpee/job-request-edit',
                                    extra: jobId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Edit Request'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Navigation Bar
          const AppNavigationBar(
            currentTab: NavigationTab.home,
            userType: UserType.helpee,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementChip(String requirement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen),
      ),
      child: Text(
        requirement,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
              'Are you sure you want to cancel this job request? This action cannot be undone and the job will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Request'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelRequest();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRequest() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final jobId = widget.jobId ?? widget.jobData?['id'];
      if (jobId == null) {
        throw Exception('No job ID available');
      }

      final success = await _jobDataService.cancelJob(
          jobId.toString(), 'Cancelled by helpee');

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job request cancelled and deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate back to home
          context.go('/helpee/home');
        }
      } else {
        throw Exception('Failed to cancel job request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling job: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
