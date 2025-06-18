import 'package:flutter/material.dart';

/// Job Rates and Payment Type component for displaying payment information
/// Used in job details and rate comparison screens
class JobRatesPayment extends StatelessWidget {
  final double hourlyRate;
  final String paymentType;
  final String? estimatedTotal;
  final String? duration;
  final bool showEstimate;
  final Color? backgroundColor;
  final double? width;

  const JobRatesPayment({
    super.key,
    required this.hourlyRate,
    required this.paymentType,
    this.estimatedTotal,
    this.duration,
    this.showEstimate = true,
    this.backgroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: effectiveBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Type Header
          Row(
            children: [
              Icon(
                _getPaymentIcon(paymentType),
                size: 24,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                paymentType,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Manjari',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hourly Rate
          Row(
            children: [
              const Text(
                'Rate: ',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontFamily: 'Manjari',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${hourlyRate.toStringAsFixed(2)}/hr',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Manjari',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Duration (if provided)
          if (duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Duration: ',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontFamily: 'Manjari',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  duration!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Manjari',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          // Estimated Total (if enabled and provided)
          if (showEstimate && estimatedTotal != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black26),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Total:',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Manjari',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${estimatedTotal!}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Manjari',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'hourly':
        return Icons.access_time;
      case 'fixed':
        return Icons.attach_money;
      case 'per task':
        return Icons.task_alt;
      default:
        return Icons.payment;
    }
  }
}
