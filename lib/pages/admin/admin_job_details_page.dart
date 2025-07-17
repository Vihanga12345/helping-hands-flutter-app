import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_auth_service.dart';
import '../../services/job_detail_service.dart';
import '../../utils/date_time_helpers.dart';

class AdminJobDetailsPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;

  const AdminJobDetailsPage({
    super.key,
    required this.jobId,
    this.jobData,
  });

  @override
  State<AdminJobDetailsPage> createState() => _AdminJobDetailsPageState();
}

class _AdminJobDetailsPageState extends State<AdminJobDetailsPage> {
  final _adminAuthService = AdminAuthService();
  final _jobDetailService = JobDetailService();

  Map<String, dynamic>? _jobDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _adminAuthService.initialize();

    // Check if admin is logged in
    if (!_adminAuthService.isLoggedIn) {
      if (mounted) {
        context.go('/admin/login');
      }
      return;
    }

    await _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final details =
          await _jobDetailService.getCompleteJobDetails(widget.jobId);

      if (mounted) {
        setState(() {
          _jobDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load job details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => context.go('/admin/manage-jobs'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadJobDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _jobDetails == null
                  ? _buildNotFoundState()
                  : _buildJobDetailsContent(),
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
            onPressed: _loadJobDetails,
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

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Job Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested job could not be found',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsContent() {
    final job = _jobDetails!;
    final statusColor = _getStatusColor(job['status']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
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
                // Title and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job['title'] ?? 'Untitled Job',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalizeStatus(job['status'] ?? ''),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Job ID
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Job ID: ${job['id']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                if (job['description'] != null) ...[
                  Text(
                    job['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Job Details Section
          _buildDetailSection(
            'Job Information',
            [
              _buildDetailItem(
                  'Category', job['category_name'] ?? 'Not specified'),
              _buildDetailItem('Date', job['date'] ?? 'Not scheduled'),
              _buildDetailItem('Time', job['time'] ?? 'Not specified'),
              _buildDetailItem(
                  'Duration', '${job['duration_hours'] ?? 0} hours'),
              _buildDetailItem('Hourly Rate', '\$${job['hourly_rate'] ?? 0}'),
              _buildDetailItem('Total Amount', '\$${job['total_amount'] ?? 0}'),
            ],
          ),

          const SizedBox(height: 20),

          // Participants Section
          _buildDetailSection(
            'Participants',
            [
              _buildDetailItem('Helpee', job['helpee_name'] ?? 'Unknown'),
              _buildDetailItem(
                  'Helpee Email', job['helpee_email'] ?? 'Not available'),
              _buildDetailItem('Helper', job['helper_name'] ?? 'Unassigned'),
              _buildDetailItem(
                  'Helper Email', job['helper_email'] ?? 'Not available'),
            ],
          ),

          const SizedBox(height: 20),

          // Location Section
          if (job['location'] != null || job['address'] != null) ...[
            _buildDetailSection(
              'Location',
              [
                if (job['location'] != null)
                  _buildDetailItem('Location', job['location']),
                if (job['address'] != null)
                  _buildDetailItem('Address', job['address']),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Questions and Answers Section
          if (job['parsed_questions'] != null &&
              job['parsed_questions'].isNotEmpty) ...[
            _buildQuestionsSection(job['parsed_questions']),
            const SizedBox(height: 20),
          ],

          // Timestamps Section
          _buildDetailSection(
            'Timestamps',
            [
              _buildDetailItem(
                'Created',
                job['created_at'] != null
                    ? DateTimeHelpers.formatDateWithTime(
                        DateTime.parse(job['created_at']))
                    : 'Unknown',
              ),
              _buildDetailItem(
                'Last Updated',
                job['updated_at'] != null
                    ? DateTimeHelpers.formatDateWithTime(
                        DateTime.parse(job['updated_at']))
                    : 'Unknown',
              ),
              if (job['started_at'] != null)
                _buildDetailItem(
                  'Started',
                  DateTimeHelpers.formatDateWithTime(
                      DateTime.parse(job['started_at'])),
                ),
              if (job['completed_at'] != null)
                _buildDetailItem(
                  'Completed',
                  DateTimeHelpers.formatDateWithTime(
                      DateTime.parse(job['completed_at'])),
                ),
            ],
          ),

          const SizedBox(height: 30),

          // Admin Actions
          _buildAdminActions(),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
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
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(List<dynamic> questions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          const Text(
            'Questions & Answers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final qa = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q: ${qa['question']?['question'] ?? qa['question']?.toString() ?? 'No question'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A: ${qa['processed_answer'] ?? qa['answer'] ?? 'No answer provided'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          const Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit job functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit functionality coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement delete job functionality
                    _showDeleteConfirmation();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Job'),
          content: const Text(
            'Are you sure you want to delete this job? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement delete functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete functionality coming soon'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.primaryOrange;
      case 'accepted':
        return AppColors.primaryBlue;
      case 'started':
        return AppColors.primaryPurple;
      case 'completed':
        return AppColors.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}
