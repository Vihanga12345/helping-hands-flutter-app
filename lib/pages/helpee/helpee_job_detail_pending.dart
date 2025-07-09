import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helper_profile_bar.dart';
import '../../services/job_data_service.dart';
import '../../services/job_detail_service.dart';
import '../../services/custom_auth_service.dart';
import '../../services/localization_service.dart';

class HelpeeJobDetailPendingPage extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const HelpeeJobDetailPendingPage({
    super.key,
    this.jobId,
    this.jobData,
  });

  @override
  State<HelpeeJobDetailPendingPage> createState() =>
      _HelpeeJobDetailPendingPageState();
}

class _HelpeeJobDetailPendingPageState
    extends State<HelpeeJobDetailPendingPage> {
  final JobDataService _jobDataService = JobDataService();
  final JobDetailService _jobDetailService = JobDetailService();
  Map<String, dynamic>? _jobDetails;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobId =
          widget.jobId ?? widget.jobData?['jobId'] ?? widget.jobData?['id'];
      if (jobId == null) {
        throw Exception('No job ID provided');
      }

      final details = await _jobDetailService.getCompleteJobDetails(jobId);
      if (details == null) {
        throw Exception('Job not found');
      }

      setState(() {
        _jobDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Job Details'.tr(),
              showBackButton: true,
              showMenuButton: false,
              showNotificationButton: false,
            ),
            Expanded(
              child: _buildContent(),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_jobDetails == null) {
      return const Center(
        child: Text('No job details available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          const SizedBox(height: 16),
          _buildJobDetailSegment(),
          const SizedBox(height: 16),
          if (_jobDetails!['has_questions']) ...[
            _buildJobSpecificationSegment(),
            const SizedBox(height: 16),
          ],
          _buildJobAdditionalDetailsSegment(),
          const SizedBox(height: 16),
          _buildJobStatusSegment(),
          const SizedBox(height: 16),
          _buildActionButtonSegment(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Pending'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'re finding the best helpers for you. You\'ll be notified once someone accepts.'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailSegment() {
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
                  Icons.work_outline,
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
                      'Job Details'.tr(),
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _jobDetails!['pay'] ?? 'Rate not set'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.category,
            'Job Type'.tr(),
            _jobDetails!['category_name'] ?? 'Unknown',
          ),
          _buildDetailRow(
            Icons.calendar_today,
            'Job Date'.tr(),
            _jobDetails!['date'] ?? 'Date not set',
          ),
          _buildDetailRow(
            Icons.access_time,
            'Job Time'.tr(),
            _jobDetails!['time'] ?? 'Time not set',
          ),
          _buildDetailRow(
            Icons.location_on,
            'Job Location'.tr(),
            _jobDetails!['location'] ?? 'Location not set',
          ),
          const SizedBox(height: 16),
          Text(
            'Job Title'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _jobDetails!['title'] ?? 'Untitled Job'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSpecificationSegment() {
    final questions = _jobDetails!['parsed_questions'] as List? ?? [];

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
                  Icons.quiz,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Job Questions'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Questions and answers for this job'.tr(),
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
              final question = qa['question'] ?? 'Question not available'.tr();
              final answer = qa['answer'] ?? 'No answer provided'.tr();

              return Padding(
                padding: EdgeInsets.only(
                    bottom: index < questions.length - 1 ? 16 : 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}: $question',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A: $answer',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildJobAdditionalDetailsSegment() {
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
                'Job Additional Details'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_jobDetails!['description'] != null &&
              _jobDetails!['description'].isNotEmpty) ...[
            Text(
              'Job Description'.tr(),
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
                _jobDetails!['description'],
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

  Widget _buildJobStatusSegment() {
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Job Status'.tr(),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_jobDetails!['status'] ?? 'PENDING').toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Waiting for Helper'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusInfoRow(
              'Request Created'.tr(), _formatDateTime(_jobDetails!['created_at'])),
          _buildStatusInfoRow('Priority'.tr(),
              (_jobDetails!['priority'] ?? 'standard').toUpperCase()),
          _buildStatusInfoRow(
              'Visibility'.tr(), _jobDetails!['is_private'] ? 'Private'.tr() : 'Public'.tr()),
          _buildStatusInfoRow('Estimated Response'.tr(), 'Within 2 hours'.tr()),
        ],
      ),
    );
  }

  Widget _buildActionButtonSegment() {
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
            'Available Actions'.tr(),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _editRequest(),
              icon: const Icon(Icons.edit),
              label: Text('Edit Request'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _cancelRequest(),
              icon: const Icon(Icons.cancel),
              label: Text('Cancel Request'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown'.tr();
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
        'January'.tr(),
        'February'.tr(),
        'March'.tr(),
        'April'.tr(),
        'May'.tr(),
        'June'.tr(),
        'July'.tr(),
        'August'.tr(),
        'September'.tr(),
        'October'.tr(),
        'November'.tr(),
        'December'.tr()
      ];
      final day = dt.day;
      final suffix = _getDaySuffix(day);
      return '${day}${suffix} ${months[dt.month - 1]} ${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'.tr();
    } catch (e) {
      return dateTime;
    }
  }

  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM'.tr() : 'AM'.tr();
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute $period'.tr();
    } catch (e) {
      return timeString;
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January'.tr(),
        'February'.tr(),
        'March'.tr(),
        'April'.tr(),
        'May'.tr(),
        'June'.tr(),
        'July'.tr(),
        'August'.tr(),
        'September'.tr(),
        'October'.tr(),
        'November'.tr(),
        'December'.tr()
      ];

      final day = date.day;
      final suffix = _getDaySuffix(day);

      return '${day}${suffix} ${months[date.month - 1]} ${date.year}'.tr();
    } catch (e) {
      return dateString;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th'.tr();
    switch (day % 10) {
      case 1:
        return 'st'.tr();
      case 2:
        return 'nd'.tr();
      case 3:
        return 'rd'.tr();
      default:
        return 'th'.tr();
    }
  }

  void _editRequest() {
    context.push('/helpee/job-request-edit', extra: {
      'jobId': _jobDetails!['id'],
      'jobData': _jobDetails,
    });
  }

  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Request'.tr()),
          content: Text(
              'Are you sure you want to cancel "${_jobDetails!['title'] ?? 'this job'}"? This action cannot be undone and the job will be permanently deleted.'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Keep Request'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelJob();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text('Cancel Request'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelJob() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final jobId = widget.jobId ?? widget.jobData?['id'];
      if (jobId == null) {
        throw Exception('No job ID available'.tr());
      }

      final success = await _jobDataService.cancelJob(
          jobId.toString(), 'Cancelled by helpee'.tr());

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job cancelled and deleted successfully'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/helpee/activity/pending');
        }
      } else {
        throw Exception('Failed to cancel job'.tr());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling job: $e'.tr()),
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
