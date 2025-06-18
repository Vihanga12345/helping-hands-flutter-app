import 'package:flutter/material.dart';

/// Helpee Profile Bar component with contact options
/// Used for displaying helpee information with communication buttons
class HelpeeProfileBar extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int jobCount;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? height;

  const HelpeeProfileBar({
    super.key,
    required this.name,
    this.profileImageUrl,
    required this.rating,
    required this.jobCount,
    this.onMessage,
    this.onCall,
    this.onTap,
    this.backgroundColor,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            // Profile Image Section
            Container(
              width: 56,
              height: 56,
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: OvalBorder(),
                shadows: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 2,
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
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey.shade600,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and Statistics Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Statistics Row
                  Row(
                    children: [
                      // Rating
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Manjari',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Job Count
                      const Text(
                        '#',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Manjari',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        jobCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Manjari',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Contact Buttons Section
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Message Button
                GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: OvalBorder(),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Call Button
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: OvalBorder(),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
