import 'package:flutter/material.dart';

/// Reusable job tile component for the Helping Hands app
/// Used for displaying job categories with images and titles
class JobTile extends StatelessWidget {
  final String title;
  final Widget? icon;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const JobTile({
    super.key,
    required this.title,
    this.icon,
    this.imageUrl,
    this.onTap,
    this.width = 120,
    this.height = 175,
    this.backgroundColor,
    this.textColor = Colors.black,
  });

  /// Small job tile for grid layouts
  const JobTile.small({
    super.key,
    required this.title,
    this.icon,
    this.imageUrl,
    this.onTap,
    this.backgroundColor,
    this.textColor = Colors.black,
  })  : width = 100,
        height = 140;

  /// Large job tile for featured categories
  const JobTile.large({
    super.key,
    required this.title,
    this.icon,
    this.imageUrl,
    this.onTap,
    this.backgroundColor,
    this.textColor = Colors.black,
  })  : width = 160,
        height = 220;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF8FD89F);
    final imageHeight = height! * 0.58; // 58% for image area
    final textHeight = height! * 0.42; // 42% for text area

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: effectiveBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
          children: [
            // Image/Icon Section
            Container(
              width: width! - 12,
              height: imageHeight - 6,
              margin: const EdgeInsets.only(top: 6, left: 6, right: 6),
              decoration: ShapeDecoration(
                color: Colors.white,
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
              child: Center(
                child: icon ??
                    (imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            width: width! * 0.6,
                            height: imageHeight * 0.6,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.work_outline,
                              size: width! * 0.3,
                              color: const Color(0xFF8FD89F),
                            ),
                          )
                        : Icon(
                            Icons.work_outline,
                            size: width! * 0.3,
                            color: const Color(0xFF8FD89F),
                          )),
              ),
            ),
            // Text Section
            Expanded(
              child: Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: width! < 120 ? 16 : 20,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
