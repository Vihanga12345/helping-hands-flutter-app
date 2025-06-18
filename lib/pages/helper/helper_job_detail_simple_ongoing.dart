import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_navigation_bar.dart';
import '../../widgets/ui_elements/helpee_profile_bar.dart';

enum JobTimerState { notStarted, running, paused, completed }

class HelperJobDetailSimpleOngoingPage extends StatefulWidget {
  const HelperJobDetailSimpleOngoingPage({super.key});

  @override
  State<HelperJobDetailSimpleOngoingPage> createState() =>
      _HelperJobDetailSimpleOngoingPageState();
}

class _HelperJobDetailSimpleOngoingPageState
    extends State<HelperJobDetailSimpleOngoingPage> {
  Timer? _timer;
  Duration _elapsedTime = const Duration(hours: 2, minutes: 15, seconds: 30);
  JobTimerState _timerState = JobTimerState.running;

  final double _hourlyRate = 500.0;
  final double _jobTypeRate = 2000.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerState = JobTimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(
          () => _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1));
    });
  }

  void _pauseTimer() {
    setState(() => _timerState = JobTimerState.paused);
    _timer?.cancel();
  }

  void _resumeTimer() {
    setState(() => _timerState = JobTimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(
          () => _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1));
    });
  }

  void _completeJob() {
    _timer?.cancel();
    setState(() => _timerState = JobTimerState.completed);
    double hoursWorked = _elapsedTime.inMinutes / 60.0;
    double totalPayment = (hoursWorked * _hourlyRate) + _jobTypeRate;
    _showJobCompletionDialog(hoursWorked, totalPayment);
  }

  String _formatDuration(Duration duration) {
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Color _getTimerColor() {
    switch (_timerState) {
      case JobTimerState.notStarted:
        return AppColors.textSecondary;
      case JobTimerState.running:
        return AppColors.success;
      case JobTimerState.paused:
        return AppColors.warning;
      case JobTimerState.completed:
        return AppColors.primaryGreen;
    }
  }

  String _getTimerStatus() {
    switch (_timerState) {
      case JobTimerState.notStarted:
        return 'Ready to start';
      case JobTimerState.running:
        return 'Job in progress';
      case JobTimerState.paused:
        return 'Job paused';
      case JobTimerState.completed:
        return 'Job completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Header
              AppHeader(
                title: 'Ongoing Job',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Job Header
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
                              children: [
                                Expanded(
                                  child: Text(
                                    'House Deep Cleaning',
                                    style: AppTextStyles.heading2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ONGOING',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Job ID: JOB001',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Essential Job Information
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
                            Text(
                              'Essential Details',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(Icons.schedule, 'Date & Time',
                                'Dec 25, 2024 at 9:00 AM'),
                            _buildDetailRow(Icons.location_on, 'Location',
                                'Colombo 07, Horton Place'),
                            _buildDetailRow(Icons.payment, 'Payment',
                                'LKR 500/hour + LKR 2,000'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Job Timer Section
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
                          children: [
                            Text(
                              _getTimerStatus(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _getTimerColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: _getTimerColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getTimerColor().withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _formatDuration(_elapsedTime),
                                style: AppTextStyles.heading1.copyWith(
                                  color: _getTimerColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Current earnings: LKR ${((_elapsedTime.inMinutes / 60.0) * _hourlyRate + _jobTypeRate).toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Helpee Information
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
                            Text(
                              'Helpee Contact',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 16),
                            HelpeeProfileBar(
                              name: 'Sarah Johnson',
                              rating: 4.9,
                              jobCount: 42,
                              onMessage: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Opening chat with helpee')),
                                );
                              },
                              onCall: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Calling helpee')),
                                );
                              },
                              onTap: () {
                                context.push('/helper/helpee-profile');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Column(
                        children: [
                          // View Job Details Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/helper/job-detail');
                              },
                              icon: const Icon(Icons.visibility, size: 20),
                              label: const Text('View Job Details'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primaryGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Timer Control Buttons
                          _buildTimerControls(),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              const AppNavigationBar(
                currentTab: NavigationTab.activity,
                userType: UserType.helper,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls() {
    switch (_timerState) {
      case JobTimerState.notStarted:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow, color: AppColors.white),
            label: const Text('Start Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case JobTimerState.running:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pauseTimer,
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warning),
                  foregroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _completeJob,
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case JobTimerState.paused:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resumeTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _completeJob,
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      case JobTimerState.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Job Completed',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showJobCompletionDialog(double hoursWorked, double totalPayment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Job Completed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Congratulations! You have successfully completed the job.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Time Worked: ${hoursWorked.toStringAsFixed(2)} hours'),
                    Text(
                        'Hourly Rate: LKR ${_hourlyRate.toStringAsFixed(0)}/hour'),
                    Text(
                        'Job Type Fee: LKR ${_jobTypeRate.toStringAsFixed(0)}'),
                    const Divider(),
                    Text(
                      'Total Payment: LKR ${totalPayment.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/helper/activity/completed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}
