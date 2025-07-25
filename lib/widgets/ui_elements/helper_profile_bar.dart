import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common/profile_image_widget.dart';

/// Helper Profile Bar component for displaying helper information from helpee POV
/// Redesigned to show: name, profile pic, job types only
/// Enhanced to support selection mode for private job creation
class HelperProfileBar extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final List<String> jobTypes;
  final VoidCallback? onTap;
  final String? helperId;
  final Map<String, dynamic>? helperData;
  final Color? backgroundColor;
  final double? height;
  final bool isSelectionMode;

  const HelperProfileBar({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.jobTypes = const [],
    this.onTap,
    this.helperId,
    this.helperData,
    this.backgroundColor,
    this.height = 90,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);

    // Format job types to display (max 3, then "...more")
    String displayJobTypes = '';
    if (jobTypes.isNotEmpty) {
      final validJobTypes = jobTypes
          .where((type) => type != null)
          .map((type) => type.toLowerCase())
          .toList();
      if (validJobTypes.length <= 3) {
        displayJobTypes = validJobTypes.join(' • ');
      } else {
        displayJobTypes =
            '${validJobTypes.take(3).join(' • ')} • +${validJobTypes.length - 3} more';
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
            side: isSelectionMode
                ? const BorderSide(color: Color(0xFF8FD89F), width: 2)
                : BorderSide.none,
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
            ProfileImageWidget(
              imageUrl: profileImageUrl,
              size: 62,
              fallbackText: name.isNotEmpty ? name[0].toUpperCase() : 'H',
              borderWidth: 0,
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
                  if (displayJobTypes.isNotEmpty)
                    Text(
                      displayJobTypes,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Selection/Navigation Section
            if (isSelectionMode)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8FD89F),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black54,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
