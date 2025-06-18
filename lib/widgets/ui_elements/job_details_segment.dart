import 'package:flutter/material.dart';

/// Job Details Segment component for displaying detailed job information
/// Used in job detail pages and job overview screens
class JobDetailsSegment extends StatelessWidget {
  final String title;
  final String description;
  final String? location;
  final String? duration;
  final String? price;
  final String? category;
  final Widget? additionalInfo;
  final Color? backgroundColor;

  const JobDetailsSegment({
    super.key,
    required this.title,
    required this.description,
    this.location,
    this.duration,
    this.price,
    this.category,
    this.additionalInfo,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    return Container(
      width: double.infinity,
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
        children: [
          // Job Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Manjari',
              fontWeight: FontWeight.w700,
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                category!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'Manjari',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Job Description
          Text(
            description,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Manjari',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          // Job Details Row
          Row(
            children: [
              if (location != null) ...[
                _buildDetailItem(
                  icon: Icons.location_on_outlined,
                  text: location!,
                ),
                const SizedBox(width: 16),
              ],
              if (duration != null) ...[
                _buildDetailItem(
                  icon: Icons.access_time,
                  text: duration!,
                ),
                const SizedBox(width: 16),
              ],
              if (price != null) ...[
                _buildDetailItem(
                  icon: Icons.attach_money,
                  text: price!,
                ),
              ],
            ],
          ),
          if (additionalInfo != null) ...[
            const SizedBox(height: 16),
            additionalInfo!,
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.black54,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Manjari',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 