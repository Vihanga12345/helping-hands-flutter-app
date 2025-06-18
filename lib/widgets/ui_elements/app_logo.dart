import 'package:flutter/material.dart';

/// Reusable logo component for the Helping Hands app
/// Used across splash screen, authentication pages, and headers
class AppLogo extends StatelessWidget {
  final double? size;
  final VoidCallback? onTap;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 100,
    this.onTap,
    this.showBackground = false,
  });

  /// Large logo for splash screens and main branding
  const AppLogo.large({
    super.key,
    this.onTap,
    this.showBackground = true,
  }) : size = 200;

  /// Medium logo for headers and navigation
  const AppLogo.medium({
    super.key,
    this.onTap,
    this.showBackground = false,
  }) : size = 100;

  /// Small logo for compact spaces
  const AppLogo.small({
    super.key,
    this.onTap,
    this.showBackground = false,
  }) : size = 60;

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: showBackground
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(0.50, -0.00),
                end: Alignment(0.50, 1.00),
                colors: [Color(0xFFE8FFE4), Color(0xFFE6FFE4)],
              ),
            )
          : null,
      child: Stack(
        children: [
          // Outer green circle
          Positioned(
            left: size! * 0.14, // Proportional positioning
            top: size! * 0.14,
            child: Container(
              width: size! * 0.72,
              height: size! * 0.72,
              decoration: const ShapeDecoration(
                color: Color(0xFF2A9134),
                shape: OvalBorder(
                  side: BorderSide(
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Inner white circle
          Positioned(
            left: size! * 0.17,
            top: size! * 0.17,
            child: Container(
              width: size! * 0.66,
              height: size! * 0.66,
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: OvalBorder(),
              ),
            ),
          ),
          // Inner green circle with hands icon
          Positioned(
            left: size! * 0.19,
            top: size! * 0.19,
            child: Container(
              width: size! * 0.62,
              height: size! * 0.62,
              decoration: const ShapeDecoration(
                color: Color(0xFF2A9134),
                shape: OvalBorder(
                  side: BorderSide(
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Colors.white,
                  ),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.favorite_border, // Representing helping hands
                  color: Colors.white,
                  size: size! * 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Make tappable if onTap is provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}
