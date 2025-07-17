import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class JobStatusIndicator extends StatefulWidget {
  final String jobTitle;
  final String helperName;
  final String status;
  final Map<String, dynamic>? jobDetails;

  const JobStatusIndicator({
    Key? key,
    required this.jobTitle,
    required this.helperName,
    required this.status,
    this.jobDetails,
  }) : super(key: key);

  @override
  _JobStatusIndicatorState createState() => _JobStatusIndicatorState();
}

class _JobStatusIndicatorState extends State<JobStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // Rotation animation for sandclock
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Start continuous rotation
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Text(
            'Job started and in progress',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Rotating sandclock animation
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
