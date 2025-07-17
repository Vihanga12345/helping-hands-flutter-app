import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/job_data_service.dart';
import '../common/job_action_buttons.dart';
import '../../pages/common/report_page.dart';

class FunctionalJobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final String userType; // 'helper' or 'helpee'
  final VoidCallback? onStatusChanged;

  const FunctionalJobCard({
    Key? key,
    required this.jobData,
    required this.userType,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<FunctionalJobCard> createState() => _FunctionalJobCardState();
}

class _FunctionalJobCardState extends State<FunctionalJobCard> {
  final JobDataService _jobService = JobDataService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final status = job['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final actionButtons = _jobService.getJobActionButtons(job, widget.userType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _navigateToJobDetail(job['id'], status),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with job title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? 'Unknown Job',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['pay'] ?? 'Rate not set',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 16),

              // Job details
              _buildJobDetail(Icons.schedule, job['date'] ?? 'Date TBD'),
              const SizedBox(height: 8),
              _buildJobDetail(Icons.access_time, job['time'] ?? 'Time TBD'),
              const SizedBox(height: 8),
              _buildJobDetail(
                  Icons.location_on, job['location'] ?? 'Location TBD'),

              // Helper/Helpee info
              if (widget.userType == 'helpee' && job['helper'] != null) ...[
                const SizedBox(height: 8),
                _buildJobDetail(Icons.person, job['helper']),
              ] else if (widget.userType == 'helper' &&
                  job['helpee'] != null) ...[
                const SizedBox(height: 8),
                _buildJobDetail(Icons.person, job['helpee']),
              ],

              // Action buttons with timer
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              JobActionButtons(
                job: job,
                userType: widget.userType,
                onJobUpdated: widget.onStatusChanged,
                showTimer: ['started', 'paused']
                    .contains(job['status']?.toLowerCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 'accepted':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        break;
      case 'started':
        backgroundColor = AppColors.primaryGreen.withOpacity(0.1);
        textColor = AppColors.primaryGreen;
        break;
      case 'paused':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 'completed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 'cancelled':
      case 'rejected':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      default:
        backgroundColor = AppColors.lightGrey.withOpacity(0.1);
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildJobDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(List<Map<String, dynamic>> buttons, String jobId) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons.map((button) {
        return _buildActionButton(
          text: button['text'],
          action: button['action'],
          color: button['color'],
          icon: button['icon'],
          jobId: jobId,
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required String text,
    required String action,
    required String color,
    required String icon,
    required String jobId,
  }) {
    Color buttonColor;
    switch (color) {
      case 'success':
        buttonColor = AppColors.success;
        break;
      case 'error':
        buttonColor = AppColors.error;
        break;
      case 'warning':
        buttonColor = AppColors.warning;
        break;
      case 'primary':
      default:
        buttonColor = AppColors.primaryGreen;
    }

    IconData iconData;
    switch (icon) {
      case 'check':
        iconData = Icons.check;
        break;
      case 'close':
        iconData = Icons.close;
        break;
      case 'play_arrow':
        iconData = Icons.play_arrow;
        break;
      case 'pause':
        iconData = Icons.pause;
        break;
      case 'check_circle':
        iconData = Icons.check_circle;
        break;
      case 'cancel':
        iconData = Icons.cancel;
        break;
      case 'phone':
        iconData = Icons.phone;
        break;
      case 'star':
        iconData = Icons.star;
        break;
      case 'report':
        iconData = Icons.report;
        break;
      default:
        iconData = Icons.help;
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _handleAction(action, jobId),
      icon: Icon(iconData, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _navigateToJobDetail(String jobId, String status) {
    // Navigate to appropriate job detail page based on user type
    if (widget.userType == 'helper') {
      // Use comprehensive job detail page for helpers with real data
      context.push('/helper/comprehensive-job-detail/$jobId');
    } else {
      // For helpees, use specific job detail pages based on status
      String route;
      switch (status.toLowerCase()) {
        case 'pending':
          route = '/helpee/job-detail/pending';
          break;
        case 'accepted':
        case 'started':
        case 'paused':
          route = '/helpee/job-detail/ongoing';
          break;
        case 'completed':
          route = '/helpee/job-detail/completed';
          break;
        default:
          route = '/helpee/job-detail/pending';
      }
      context.push(route, extra: {
        'jobId': jobId,
        'jobData': widget.jobData,
      });
    }
  }

  Future<void> _handleAction(String action, String jobId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      Map<String, dynamic>? params;

      // Handle special actions that need user input
      if (action == 'report') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPage(userType: widget.userType),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      } else if (action == 'cancel') {
        params = await _showCancelDialog();
        if (params == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Execute the action
      success = await _jobService.executeJobAction(action, jobId, params);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessage(action)),
              backgroundColor: AppColors.success,
            ),
          );

          // Trigger callback to refresh the list
          widget.onStatusChanged?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${action.toLowerCase()} job'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getSuccessMessage(String action) {
    switch (action) {
      case 'accept':
        return 'Job accepted successfully!';
      case 'reject':
        return 'Job rejected successfully!';
      case 'start':
        return 'Job started successfully!';
      case 'pause':
        return 'Job paused successfully!';
      case 'resume':
        return 'Job resumed successfully!';
      case 'complete':
        return 'Job completed successfully!';
      case 'cancel':
        return 'Job cancelled successfully!';
      case 'report':
        return 'Job reported successfully!';
      default:
        return 'Action completed successfully!';
    }
  }

  Future<Map<String, dynamic>?> _showCancelDialog() async {
    String? reason;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this job?'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Job'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'reason': reason ?? 'Cancelled by user',
            }),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Job'),
          ),
        ],
      ),
    );
  }
}
