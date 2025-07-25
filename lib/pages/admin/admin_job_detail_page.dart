import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_data_service.dart';
import '../../utils/date_time_helpers.dart';

class AdminJobDetailPage extends StatefulWidget {
  final String jobId;

  const AdminJobDetailPage({
    super.key,
    required this.jobId,
  });

  @override
  State<AdminJobDetailPage> createState() => _AdminJobDetailPageState();
}

class _AdminJobDetailPageState extends State<AdminJobDetailPage> {
  final _adminDataService = AdminDataService();
  Map<String, dynamic>? _jobData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobDetail();
  }

  Future<void> _loadJobDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final jobData = await _adminDataService.getJobDetail(widget.jobId);

      if (mounted) {
        setState(() {
          _jobData = jobData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load job details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/admin/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildJobContent(isDesktop),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadJobDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobContent(bool isDesktop) {
    if (_jobData == null) {
      return const Center(
        child: Text(
          'No job data available',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildJobHeaderCard(),
          const SizedBox(height: 20),
          if (isDesktop) _buildDesktopLayout() else _buildMobileLayout(),
        ],
      ),
    );
  }

  Widget _buildJobHeaderCard() {
    final String title = _jobData!['title'] ?? 'Untitled Job';
    final String status = _jobData!['status'] ?? 'unknown';
    final String category = _jobData!['category_name'] ?? 'Unknown Category';
    final bool isPrivate = _jobData!['is_private'] ?? false;
    final double? fee = _jobData!['fee']?.toDouble();

    Color statusColor = AppColors.mediumGrey;
    IconData statusIcon = Icons.help;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_actions;
        break;
      case 'in_progress':
        statusColor = AppColors.primaryGreen;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'completed':
        statusColor = AppColors.primaryPurple;
        statusIcon = Icons.check_circle;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            spreadRadius: 2,
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
              Icon(
                statusIcon,
                color: AppColors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isPrivate) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PRIVATE',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (fee != null)
                Text(
                  'Rs. ${fee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            category,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildJobDetailsCard(),
              const SizedBox(height: 20),
              _buildTimelineCard(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _buildParticipantsCard(),
              const SizedBox(height: 20),
              _buildLocationCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildJobDetailsCard(),
        const SizedBox(height: 20),
        _buildParticipantsCard(),
        const SizedBox(height: 20),
        _buildLocationCard(),
        const SizedBox(height: 20),
        _buildTimelineCard(),
      ],
    );
  }

  Widget _buildJobDetailsCard() {
    final String description = _jobData!['description'] ?? '';
    final List<dynamic> questions = _jobData!['questions'] ?? [];
    final List<dynamic> answers = _jobData!['answers'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
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
              Icon(
                Icons.description,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Job Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (questions.isNotEmpty && answers.isNotEmpty) ...[
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              questions.length.clamp(0, answers.length),
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestionAnswer(
                  questions[index]['question_text'] ?? '',
                  answers[index]['answer_text'] ?? '',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.lightGrey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer.isNotEmpty ? answer : 'No answer provided',
            style: TextStyle(
              fontSize: 13,
              color: answer.isNotEmpty
                  ? AppColors.textSecondary
                  : AppColors.mediumGrey,
              fontStyle: answer.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard() {
    final String helpeeName = _jobData!['helpee_name'] ?? 'Unknown Helpee';
    final String helperName = _jobData!['helper_name'] ?? 'Not Assigned';
    final String helpeeId = _jobData!['helpee_id'] ?? '';
    final String helperId = _jobData!['assigned_helper_id'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
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
              Icon(
                Icons.people,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Participants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildParticipantRow(
            'Helpee',
            helpeeName,
            Icons.person,
            AppColors.primaryBlue,
            helpeeId.isNotEmpty
                ? () => context.go('/admin/users/helpee-profile/$helpeeId')
                : null,
          ),
          const SizedBox(height: 16),
          _buildParticipantRow(
            'Helper',
            helperName,
            Icons.person_pin,
            AppColors.primaryOrange,
            helperId.isNotEmpty
                ? () => context.go('/admin/users/helper-profile/$helperId')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
    String role,
    String name,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    Widget content = Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 20,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.mediumGrey,
          ),
      ],
    );

    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: content,
            ),
          )
        : content;
  }

  Widget _buildLocationCard() {
    final String location = _jobData!['location'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
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
              Icon(
                Icons.location_on,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            location.isNotEmpty ? location : 'No location specified',
            style: TextStyle(
              fontSize: 16,
              color: location.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontStyle: location.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final DateTime? createdAt = _jobData!['created_at'] != null
        ? DateTime.tryParse(_jobData!['created_at'].toString())
        : null;
    final DateTime? startedAt = _jobData!['started_at'] != null
        ? DateTime.tryParse(_jobData!['started_at'].toString())
        : null;
    final DateTime? completedAt = _jobData!['completed_at'] != null
        ? DateTime.tryParse(_jobData!['completed_at'].toString())
        : null;
    final int? durationMinutes = _jobData!['duration_minutes']?.toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
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
              Icon(
                Icons.timeline,
                color: AppColors.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (createdAt != null)
            _buildTimelineItem(
              'Created',
              DateTimeHelpers.getTimeAgo(createdAt),
              Icons.add_circle_outline,
              AppColors.primaryBlue,
              true,
            ),
          if (startedAt != null) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              'Started',
              DateTimeHelpers.getTimeAgo(startedAt),
              Icons.play_circle_outline,
              AppColors.primaryGreen,
              true,
            ),
          ],
          if (completedAt != null) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              'Completed',
              DateTimeHelpers.getTimeAgo(completedAt),
              Icons.check_circle_outline,
              AppColors.primaryPurple,
              true,
            ),
          ],
          if (durationMinutes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${durationMinutes} minutes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? color : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.mediumGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
