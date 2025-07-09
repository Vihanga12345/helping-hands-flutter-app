import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helpee_profile_bar.dart';
import '../../widgets/common/job_action_buttons.dart';
import '../../services/job_data_service.dart';
import '../../services/user_data_service.dart';
import '../../services/custom_auth_service.dart';

class HelperComprehensiveJobDetailPage extends StatefulWidget {
  final String jobId;

  const HelperComprehensiveJobDetailPage({
    super.key,
    required this.jobId,
  });

  @override
  State<HelperComprehensiveJobDetailPage> createState() =>
      _HelperComprehensiveJobDetailPageState();
}

class _HelperComprehensiveJobDetailPageState
    extends State<HelperComprehensiveJobDetailPage> {
  final JobDataService _jobDataService = JobDataService();
  final UserDataService _userDataService = UserDataService();
  final CustomAuthService _authService = CustomAuthService();

  Map<String, dynamic>? _jobDetails;
  Map<String, dynamic>? _helpeeProfile;
  Map<String, dynamic>? _helpeeStatistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Get job details with questions
      final jobDetails =
          await _jobDataService.getJobDetailsWithQuestions(widget.jobId);

      if (jobDetails == null) {
        if (mounted) {
          setState(() {
            _error = 'Job not found';
            _isLoading = false;
          });
        }
        return;
      }

      // Get helpee profile and statistics
      final helpeeId = jobDetails['helpee_id'];
      if (helpeeId != null) {
        // Get helpee profile directly from database
        final helpeeProfile = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('id', helpeeId)
            .maybeSingle();

        // Get helpee statistics (using user statistics method)
        final helpeeStats = await _userDataService.getUserStatistics(helpeeId);

        if (mounted) {
          setState(() {
            _jobDetails = jobDetails;
            _helpeeProfile = helpeeProfile;
            _helpeeStatistics = helpeeStats;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _jobDetails = jobDetails;
            _isLoading = false;
          });
        }
      }

      print('✅ Job details loaded successfully');
    } catch (e) {
      print('❌ Error loading job details: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load job details: $e';
          _isLoading = false;
        });
      }
    }
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
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Loading job details...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load job details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segment 1: Main Job Details
  Widget _buildMainJobDetails() {
    if (_jobDetails == null) return Container();

    // Get status color and text
    Color statusColor = _getStatusColor(_jobDetails!['status']);
    String statusText = _getStatusText(_jobDetails!['status']);

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
                'Job details',
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
                  statusText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Job Type
          _buildDetailRow(
              'Job Type',
              _jobDetails!['job_category_name'] ??
                  _jobDetails!['category_name'] ??
                  _jobDetails!['category'] ??
                  'General Services'),
          const SizedBox(height: 12),

          // 2. Job Hourly Rate
          _buildDetailRow('Hourly Rate',
              'LKR ${_jobDetails!['hourly_rate'] ?? '2,500'} / Hour'),
          const SizedBox(height: 12),

          // 3. Job Date
          _buildDetailRow(
              'Date', _formatDate(_jobDetails!['date']) ?? 'Not specified'),
          const SizedBox(height: 12),

          // 4. Job Time
          _buildDetailRow(
              'Time', _formatTime(_jobDetails!['time']) ?? 'Not specified'),
          const SizedBox(height: 12),

          // 5. Job Location
          _buildDetailRow(
              'Location', _jobDetails!['location'] ?? 'Not specified'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'started':
        return AppColors.primaryGreen;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'started':
        return 'ONGOING';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final date = DateTime.parse(dateString);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${date.day}${_getDayOfMonthSuffix(date.day)} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getDayOfMonthSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  // Segment 2: Job Questions
  Widget _buildJobQuestions() {
    if (_jobDetails == null) return Container();

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
            'Questions created by the admin and answered by the helpee',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
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
              final question = qa['question'] ?? 'Question not available';
              final answer = qa['answer'] ?? 'No answer provided';

              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  _buildQuestionAnswer(
                    'Q${index + 1}: $question',
                    'A: $answer',
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  // Segment 3: Job Additional Details
  Widget _buildJobAdditionalDetails() {
    if (_jobDetails == null) return Container();

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
            _jobDetails!['description'] ??
                'No description provided for this job.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          // Special Instructions (if available)
          if (_jobDetails!['special_instructions'] != null &&
              _jobDetails!['special_instructions'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Special Instructions',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _jobDetails!['special_instructions'],
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          // Estimated Hours (if available)
          if (_jobDetails!['estimated_hours'] != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Estimated Duration',
                '${_jobDetails!['estimated_hours']} hours'),
          ],
        ],
      ),
    );
  }

  // Segment 4: Posted By / Assigned To
  Widget _buildPostedBySection() {
    if (_helpeeProfile == null) {
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Helpee information not available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
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
          Text(
            'Posted By',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Helpee Profile Bar with real data
          HelpeeProfileBar(
            name:
                '${_helpeeProfile!['first_name'] ?? ''} ${_helpeeProfile!['last_name'] ?? ''}'
                    .trim(),
            rating: (_helpeeStatistics?['rating'] ?? 0.0).toDouble(),
            jobCount: _helpeeStatistics?['total_jobs'] ?? 0,
            serviceType: null, // Remove service type display
            profileImageUrl: _helpeeProfile!['profile_image_url'],
            onTap: () {
              // Navigate to helpee profile page
              context.push('/helper/helpee-profile', extra: {
                'helpeeId': _helpeeProfile!['id'],
                'helpeeData': _helpeeProfile,
                'helpeeStats': _helpeeStatistics,
              });
            },
          ),

          // Contact buttons integrated into Posted By section
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
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

  // Segment 5: Job Action Buttons
  Widget _buildJobActionButtons(BuildContext context) {
    if (_jobDetails == null) return const SizedBox.shrink();

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

          // Use the dynamic JobActionButtons widget with timer functionality
          JobActionButtons(
            job: _jobDetails!,
            userType: 'helper',
            onJobUpdated: () {
              _loadJobDetails(); // Reload job details when status changes
            },
            showTimer: ['started', 'paused']
                .contains(_jobDetails!['status']?.toLowerCase()),
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
    final isPrivate = _jobDetails?['is_private'] == true;
    final actionTitle = isPrivate ? 'Reject Job Request' : 'Ignore Job Request';
    final actionMessage = isPrivate
        ? 'Are you sure you want to reject this job? This action cannot be undone.'
        : 'Are you sure you want to ignore this job? It will not appear in your job list again.';
    final actionButtonText = isPrivate ? 'Reject' : 'Ignore';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(actionTitle),
          content: Text(actionMessage),
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
              child: Text(actionButtonText),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await _jobDataService.acceptJob(widget.jobId, userId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted! Moving to ongoing jobs.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate to activity ongoing page
        context.go('/helper/activity/ongoing');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept job. Please try again.'),
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
    }
  }

  void _rejectJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final isPrivate = _jobDetails?['is_private'] ?? false;

      if (isPrivate) {
        // Reject private job
        final success = await _jobDataService.rejectJob(widget.jobId, userId);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job rejected.'),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject job. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      } else {
        // Ignore public job
        final success = await _jobDataService.ignoreJob(widget.jobId, userId);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Job ignored. It won\'t appear in your list again.'),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to ignore job. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      // Navigate back to requests
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await _jobDataService.startJob(widget.jobId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started! Timer is now running.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload the job details to update the UI
        _loadJobDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start job. Please try again.'),
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
    }
  }

  void _pauseJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final success = await _jobDataService.pauseJob(widget.jobId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job paused.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadJobDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completeJob(BuildContext context) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final success = await _jobDataService.completeJob(widget.jobId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed! Moving to completed jobs.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/helper/activity/completed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
