import 'package:flutter/material.dart';

/// Helper Profile Bar component for displaying helper information from helpee POV
/// Redesigned to show: name, profile pic, rating, job count, job types
class HelperProfileBar extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int jobCount;
  final List<String> jobTypes;
  final VoidCallback? onTap;
  final String? helperId;
  final Map<String, dynamic>? helperData;
  final Color? backgroundColor;
  final double? height;

  const HelperProfileBar({
    super.key,
    required this.name,
    this.profileImageUrl,
    required this.rating,
    required this.jobCount,
    this.jobTypes = const [],
    this.onTap,
    this.helperId,
    this.helperData,
    this.backgroundColor,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    // Format job types to display (max 3, then "...more")
    String displayJobTypes = '';
    if (jobTypes.isNotEmpty) {
      if (jobTypes.length <= 3) {
        displayJobTypes = jobTypes.join(' • ').toLowerCase();
      } else {
        displayJobTypes =
            '${jobTypes.take(3).join(' • ').toLowerCase()} • +${jobTypes.length - 3} more';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: effectiveBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 6,
              offset: Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image Section
            Container(
              width: 62,
              height: 62,
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: OvalBorder(),
                shadows: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.grey.shade600,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Helper Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Helper Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),


                ],
              ),
            ),

            const SizedBox(width: 12),

            // Statistics Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Rating with star
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Job Count with # symbol
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '#',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      jobCount.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
