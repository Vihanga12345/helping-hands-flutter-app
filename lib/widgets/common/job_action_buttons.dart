import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../services/job_data_service.dart';
import '../../services/custom_auth_service.dart';
import '../../pages/common/report_page.dart';

class JobActionButtons extends StatefulWidget {
  final Map<String, dynamic> job;
  final String userType; // 'helper' or 'helpee'
  final VoidCallback? onJobUpdated;
  final bool showTimer; // Kept for compatibility but not used

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

  Future<void> _handleAction(String action) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final jobId = widget.job['id'];
      final currentUser = _authService.currentUser;
      bool success = false;

      switch (action) {
        case 'accept':
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
          final helperId = currentUser?['user_id'];
          if (helperId != null) {
            success = await _jobDataService.startJob(jobId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job started successfully!')),
              );
            }
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportPage(userType: widget.userType),
            ),
          );
          break;
        // NOTE: Timer actions (start, pause, resume, complete) are now handled
        // by the dedicated HelperJobTimerWidget, not this widget
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

  @override
  Widget build(BuildContext context) {
    final buttons =
        _jobDataService.getJobActionButtons(widget.job, widget.userType);

    // Remove messaging/calling functionality from job cards
    // These features are now only available in profile pages

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons.map((button) {
        // Only skip timer-specific controls (pause, resume), but keep basic job actions (start, complete)
        if (['pause', 'resume'].contains(button['action'])) {
          return const SizedBox.shrink();
        }

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }).toList(),
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
