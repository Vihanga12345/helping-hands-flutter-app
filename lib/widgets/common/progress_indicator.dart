import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> stepTitles;
  final Function(int)? onStepTapped;
  final bool enableNavigation;

  const ProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepTitles,
    this.onStepTapped,
    this.enableNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber <= currentStep;
              final isCurrent = stepNumber == currentStep;
              final isCompleted = stepNumber < currentStep;

              return Row(
                children: [
                  _buildStepBubble(
                    stepNumber: stepNumber,
                    isActive: isActive,
                    isCurrent: isCurrent,
                    isCompleted: isCompleted,
                  ),
                  if (index < totalSteps - 1)
                    _buildConnectorLine(isActive: stepNumber < currentStep),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Step $currentStep of $totalSteps: ${stepTitles[currentStep - 1]}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepBubble({
    required int stepNumber,
    required bool isActive,
    required bool isCurrent,
    required bool isCompleted,
  }) {
    Color backgroundColor;
    Color textColor;
    Widget child;

    if (isCompleted) {
      backgroundColor = AppColors.primaryGreen;
      textColor = Colors.white;
      child = const Icon(
        Icons.check,
        color: Colors.white,
        size: 18,
      );
    } else if (isCurrent) {
      backgroundColor = AppColors.primaryGreen;
      textColor = Colors.white;
      child = Text(
        stepNumber.toString(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    } else {
      backgroundColor = AppColors.lightGrey;
      textColor = AppColors.textSecondary;
      child = Text(
        stepNumber.toString(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      );
    }

    return GestureDetector(
      onTap: enableNavigation && onStepTapped != null
          ? () => onStepTapped!(stepNumber)
          : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isCurrent
              ? Border.all(
                  color: AppColors.primaryGreen,
                  width: 3,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildConnectorLine({required bool isActive}) {
    return Container(
      width: 40,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryGreen : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class SimpleProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final String stepTitle;

  const SimpleProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber <= currentStep;

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryGreen
                          : AppColors.lightGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        stepNumber.toString(),
                        style: TextStyle(
                          color:
                              isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (index < totalSteps - 1)
                    Container(
                      width: 30,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: stepNumber < currentStep
                          ? AppColors.primaryGreen
                          : AppColors.lightGrey,
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            stepTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
