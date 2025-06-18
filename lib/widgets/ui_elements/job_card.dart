import 'package:flutter/material.dart';

/// Job Card component with multiple variants for different display contexts
/// Covers UI Elements 7-11: Helpee View Job Card 1-4 variants
class JobCard extends StatelessWidget {
  final String title;
  final String description;
  final String? helperName;
  final String? status;
  final String? location;
  final String? duration;
  final String? price;
  final double? rating;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Widget? statusIndicator;
  final List<Widget>? actionButtons;

  const JobCard({
    super.key,
    required this.title,
    required this.description,
    this.helperName,
    this.status,
    this.location,
    this.duration,
    this.price,
    this.rating,
    this.onTap,
    this.backgroundColor,
    this.statusIndicator,
    this.actionButtons,
  });

  /// Job Card Variant 1 - Basic job card with minimal information
  const JobCard.variant1({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
    this.backgroundColor,
  })  : helperName = null,
        status = null,
        location = null,
        duration = null,
        price = null,
        rating = null,
        statusIndicator = null,
        actionButtons = null;

  /// Job Card Variant 2 - Job card with helper information
  const JobCard.variant2({
    super.key,
    required this.title,
    required this.description,
    this.helperName,
    this.rating,
    this.onTap,
    this.backgroundColor,
  })  : status = null,
        location = null,
        duration = null,
        price = null,
        statusIndicator = null,
        actionButtons = null;

  /// Job Card Variant 3 - Job card with location and pricing
  const JobCard.variant3({
    super.key,
    required this.title,
    required this.description,
    this.location,
    this.duration,
    this.price,
    this.onTap,
    this.backgroundColor,
  })  : helperName = null,
        status = null,
        rating = null,
        statusIndicator = null,
        actionButtons = null;

  /// Job Card Variant 4 - Complete job card with status and actions
  const JobCard.variant4({
    super.key,
    required this.title,
    required this.description,
    this.helperName,
    this.status,
    this.location,
    this.duration,
    this.price,
    this.rating,
    this.statusIndicator,
    this.actionButtons,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
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
            // Header with title and status indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (statusIndicator != null) ...[
                  const SizedBox(width: 8),
                  statusIndicator!,
                ],
                if (status != null && statusIndicator == null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: ShapeDecoration(
                      color: _getStatusColor(status!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      status!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              description,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Manjari',
                fontWeight: FontWeight.w400,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Helper information (if provided)
            if (helperName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      helperName!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (rating != null) ...[
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            // Job details row
            if (location != null || duration != null || price != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (location != null) ...[
                    _buildDetailChip(Icons.location_on_outlined, location!),
                    const SizedBox(width: 8),
                  ],
                  if (duration != null) ...[
                    _buildDetailChip(Icons.access_time, duration!),
                    const SizedBox(width: 8),
                  ],
                  if (price != null) ...[
                    _buildDetailChip(Icons.attach_money, price!),
                  ],
                ],
              ),
            ],
            // Action buttons (if provided)
            if (actionButtons != null && actionButtons!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actionButtons!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'Manjari',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
