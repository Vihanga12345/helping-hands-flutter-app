import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';

class JobActionButtons extends StatefulWidget {
  final Map<String, dynamic> job;
  final String userType; // 'helper' or 'helpee'
  final VoidCallback? onJobUpdated;
  final bool showTimer;

  const JobActionButtons({
    super.key,
    required this.job,
    required this.userType,
    this.onJobUpdated,
    this.showTimer = false,
  });

  @override
  State<JobActionButtons> createState() => _JobActionButtonsState();
}

class _JobActionButtonsState extends State<JobActionButtons> {
  final JobDataService _jobDataService = JobDataService();
  final CustomAuthService _authService = CustomAuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _timerInfo;

  @override
  void initState() {
    super.initState();
    if (widget.showTimer) {
      _loadTimerInfo();
    }
  }

  Future<void> _loadTimerInfo() async {
    if (widget.job['id'] != null) {
      final timerInfo = await _jobDataService.getJobTimerInfo(widget.job['id']);
      if (mounted) {
        setState(() {
          _timerInfo = timerInfo;
        });
      }
    }
  }

  Future<void> _handleAction(String action) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final jobId = widget.job['id'];
      bool success = false;

      switch (action) {
        case 'accept':
          final currentUser = _authService.currentUser;
          final helperId = currentUser?['user_id'];
          if (helperId != null) {
            success = await _jobDataService.acceptJob(jobId, helperId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job accepted successfully!')),
              );
            }
          }
          break;
        case 'reject':
          final currentUser = _authService.currentUser;
          final helperId = currentUser?['user_id'];
          if (helperId != null) {
            success = await _jobDataService.rejectJob(jobId, helperId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job rejected')),
              );
            }
          }
          break;
        case 'ignore':
          final currentUser = _authService.currentUser;
          final helperId = currentUser?['user_id'];
          if (helperId != null) {
            success = await _jobDataService.ignoreJob(jobId, helperId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job ignored')),
              );
            }
          }
          break;
        case 'start':
          success = await _jobDataService.startJob(jobId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job timer started!')),
            );
            _loadTimerInfo(); // Refresh timer info
          }
          break;
        case 'pause':
          success = await _jobDataService.pauseJob(jobId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job timer paused')),
            );
            _loadTimerInfo(); // Refresh timer info
          }
          break;
        case 'resume':
          success = await _jobDataService.resumeJob(jobId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job timer resumed!')),
            );
            _loadTimerInfo(); // Refresh timer info
          }
          break;
        case 'complete':
          success = await _jobDataService.completeJob(jobId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job completed successfully!')),
            );
          }
          break;
        case 'report':
          _showReportDialog();
          break;
      }

      if (success && widget.onJobUpdated != null) {
        widget.onJobUpdated!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Job'),
        content:
            const Text('Job reporting functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    if (_timerInfo == null) return const SizedBox.shrink();

    final isRunning = _timerInfo!['is_timer_running'] ?? false;
    final formattedTime = _timerInfo!['formatted_elapsed_time'] ?? '00:00:00';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isRunning
            ? AppColors.primaryGreen.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRunning ? AppColors.primaryGreen : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.timer : Icons.pause_circle_outline,
            size: 16,
            color: isRunning ? AppColors.primaryGreen : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            formattedTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: isRunning ? AppColors.primaryGreen : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons =
        _jobDataService.getJobActionButtons(widget.job, widget.userType);

    if (buttons.isEmpty && !widget.showTimer) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timer display
        if (widget.showTimer && _timerInfo != null) ...[
          _buildTimer(),
          const SizedBox(height: 8),
        ],

        // Action buttons
        if (buttons.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons.map((button) {
              Color buttonColor;
              switch (button['color']) {
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
                  break;
              }

              return SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _handleAction(button['action']),
                  icon: _isLoading && button['action'] != 'report'
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Icon(
                          _getIconData(button['icon']),
                          size: 16,
                        ),
                  label: Text(
                    button['text'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: AppColors.white,
                    elevation: 2,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'pause':
        return Icons.pause;
      case 'check_circle':
        return Icons.check_circle;
      case 'report':
        return Icons.report;
      default:
        return Icons.help_outline;
    }
  }
}
 