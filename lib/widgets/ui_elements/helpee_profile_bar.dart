import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../common/profile_image_widget.dart';

/// Helpee Profile Bar component with contact options
/// Used for displaying helpee information with communication buttons
class HelpeeProfileBar extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final String? serviceType;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? height;

  const HelpeeProfileBar({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.serviceType,
    this.onMessage,
    this.onCall,
    this.onTap,
    this.backgroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.primaryGreen.withOpacity(0.15);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image Section
            ProfileImageWidget(
              imageUrl: profileImageUrl,
              size: 50,
              fallbackText: name.isNotEmpty ? name[0].toUpperCase() : 'H',
              borderWidth: 0,
            ),
            const SizedBox(width: 12),

            // Name and Service Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (serviceType != null && serviceType!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      serviceType!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow Icon
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
