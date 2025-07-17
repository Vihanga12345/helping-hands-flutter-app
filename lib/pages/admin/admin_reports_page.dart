import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../widgets/common/app_header.dart';
import '../../utils/app_colors.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({Key? key}) : super(key: key);

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await ReportService.getAllReports();

      if (mounted) {
        if (result['success']) {
          setState(() {
            _reports = List<Map<String, dynamic>>.from(result['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = result['message'] ?? 'Failed to load reports';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error loading reports: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markReportAsSeen(String reportId, int index) async {
    try {
      final result = await ReportService.markReportAsSeen(reportId);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _reports[index]['is_seen'] = true;
            _reports[index]['seen_at'] = DateTime.now().toIso8601String();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report marked as seen'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        final hours = difference.inHours;
        if (hours == 0) {
          final minutes = difference.inMinutes;
          return minutes == 0 ? 'Just now' : '${minutes}m ago';
        }
        return '${hours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Helpee issue':
        return Colors.blue;
      case 'Helper issue':
        return Colors.green;
      case 'Job issue':
        return Colors.orange;
      case 'Job rate issue':
        return Colors.purple;
      case 'Job question issue':
        return Colors.teal;
      case 'Other issue':
        return Colors.grey;
      case 'Question':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppHeader(
        title: 'Application Issues & Reports',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : _hasError
              ? Center(
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
                        'Error Loading Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadReports,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Reports Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All user reports will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      color: AppColors.primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final isRead = report['is_seen'] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? Colors.grey.shade300
                                    : AppColors.primaryGreen.withOpacity(0.3),
                                width: isRead ? 1 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      // Status Indicator
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? Colors.grey
                                              : AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report['user_name'] ??
                                                  'Unknown User',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isRead
                                                    ? Colors.grey.shade700
                                                    : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${report['user_type']?.toUpperCase() ?? 'UNKNOWN'} • ${report['user_email'] ?? 'No email'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Time
                                      Text(
                                        _formatDate(report['submitted_at']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                              report['report_category'] ?? '')
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getCategoryColor(
                                            report['report_category'] ?? ''),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      report['report_category'] ??
                                          'Unknown Category',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getCategoryColor(
                                            report['report_category'] ?? ''),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    report['description'] ??
                                        'No description provided',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Action Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (isRead) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Seen ${_formatDate(report['seen_at'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _markReportAsSeen(
                                            report['id'],
                                            index,
                                          ),
                                          icon: const Icon(
                                            Icons.visibility,
                                            size: 16,
                                          ),
                                          label: const Text('Mark as Seen'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
