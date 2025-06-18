import 'package:flutter/material.dart';

/// Reusable button component for the Helping Hands app
/// Provides consistent styling across all buttons in the application
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isEnabled;
  final Widget? icon;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 60,
    this.backgroundColor,
    this.textColor = Colors.black,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.isEnabled = true,
    this.icon,
    this.borderRadius = 30,
  });

  /// Primary green button (default style)
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 60,
    this.textColor = Colors.black,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.isEnabled = true,
    this.icon,
    this.borderRadius = 30,
  }) : backgroundColor = const Color(0xFF5BBA6F);

  /// Large button for main actions
  const AppButton.large({
    super.key,
    required this.text,
    this.onPressed,
    this.width = double.infinity,
    this.textColor = Colors.black,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.isEnabled = true,
    this.icon,
    this.borderRadius = 30,
  })  : backgroundColor = const Color(0xFF5BBA6F),
        height = 80;

  /// Secondary button with outline style
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 60,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
    this.isEnabled = true,
    this.icon,
    this.borderRadius = 30,
  })  : backgroundColor = Colors.transparent,
        textColor = const Color(0xFF5BBA6F);

  /// Small button for compact spaces
  const AppButton.small({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 40,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.isEnabled = true,
    this.icon,
    this.borderRadius = 20,
  })  : backgroundColor = const Color(0xFF5BBA6F),
        textColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF5BBA6F);
    final isSecondary = backgroundColor == Colors.transparent;

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: isEnabled ? effectiveBackgroundColor : Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: isSecondary
              ? BorderSide(
                  color: isEnabled ? const Color(0xFF5BBA6F) : Colors.grey,
                  width: 2,
                )
              : BorderSide.none,
        ),
        shadows: !isSecondary && isEnabled
            ? [
                const BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isEnabled ? onPressed : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled
                          ? (isSecondary ? const Color(0xFF5BBA6F) : textColor)
                          : Colors.grey.shade600,
                      fontSize: fontSize,
                      fontFamily: 'Manjari',
                      fontWeight: fontWeight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
