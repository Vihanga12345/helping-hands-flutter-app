import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_time_helpers.dart';

class AdminJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;
  final Function(String)? onStatusUpdate;
  final VoidCallback? onDelete;
  final bool showActions;

  const AdminJobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onStatusUpdate,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(job['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header with job title and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'Untitled Job',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (job['id'] != null)
                        Text(
                          'ID: ${job['id'].toString().substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalizeStatus(job['status'] ?? ''),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (if available)
                if (job['description'] != null &&
                    job['description'].isNotEmpty) ...[
                  Text(
                    job['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Participants row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.person,
                        'Helpee',
                        job['helpee_name'] ??
                            job['helpee']?['full_name'] ??
                            'Unknown',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.handyman,
                        'Helper',
                        job['helper_name'] ??
                            job['helper']?['full_name'] ??
                            'Unassigned',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date and payment row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        'Date',
                        _formatJobDate(),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.attach_money,
                        'Rate',
                        '\$${job['hourly_rate'] ?? 0}/hr',
                      ),
                    ),
                  ],
                ),

                // Category and duration
                if (job['category_name'] != null ||
                    job['duration_hours'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (job['category_name'] != null)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.category,
                            'Category',
                            job['category_name'],
                          ),
                        ),
                      if (job['duration_hours'] != null)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.schedule,
                            'Duration',
                            '${job['duration_hours']} hrs',
                          ),
                        ),
                    ],
                  ),
                ],

                // Total amount if available
                if (job['total_amount'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments,
                          color: AppColors.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Amount: \$${job['total_amount']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (showActions) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // View Details Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap ??
                () {
                  context.go(
                    '/admin/job-details/${job['id']}',
                    extra: {'jobData': job},
                  );
                },
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Status Update Menu
        if (onStatusUpdate != null)
          Expanded(
            child: PopupMenuButton<String>(
              onSelected: onStatusUpdate,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.pending,
                          size: 16, color: AppColors.primaryOrange),
                      SizedBox(width: 8),
                      Text('Set Pending'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'accepted',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text('Set Accepted'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'started',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle,
                          size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 8),
                      Text('Set Started'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.done_all,
                          size: 16, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Text('Set Completed'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Set Cancelled'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      color: AppColors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Update',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatJobDate() {
    if (job['date'] != null) {
      return job['date'];
    } else if (job['scheduled_date'] != null) {
      try {
        final date = DateTime.parse(job['scheduled_date']);
        return DateTimeHelpers.formatDateWithSuffix(date);
      } catch (e) {
        return job['scheduled_date'];
      }
    }
    return 'Not scheduled';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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

// Compact version of job card for lists
class AdminJobCardCompact extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;

  const AdminJobCardCompact({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(job['status']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(width: 12),

            // Job info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] ?? 'Untitled Job',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${job['helpee_name'] ?? 'Unknown'} • \$${job['hourly_rate'] ?? 0}/hr',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _capitalizeStatus(job['status'] ?? ''),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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
