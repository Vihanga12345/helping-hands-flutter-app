import 'package:flutter/material.dart';

/// Job Title component for displaying job titles with consistent styling
/// Used across different pages for job title display
class JobTitle extends StatelessWidget {
  final String title;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Widget? prefix;
  final Widget? suffix;

  const JobTitle({
    super.key,
    required this.title,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.textColor = Colors.black,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.prefix,
    this.suffix,
  });

  /// Large job title for headers and main displays
  const JobTitle.large({
    super.key,
    required this.title,
    this.fontWeight = FontWeight.w700,
    this.textColor = Colors.black,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.prefix,
    this.suffix,
  }) : fontSize = 24;

  /// Medium job title for standard displays
  const JobTitle.medium({
    super.key,
    required this.title,
    this.fontWeight = FontWeight.w700,
    this.textColor = Colors.black,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.prefix,
    this.suffix,
  }) : fontSize = 20;

  /// Small job title for compact displays
  const JobTitle.small({
    super.key,
    required this.title,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.black,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.prefix,
    this.suffix,
  }) : fontSize = 16;

  /// Job title with light styling
  const JobTitle.light({
    super.key,
    required this.title,
    this.fontSize = 20,
    this.textColor = Colors.black54,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.prefix,
    this.suffix,
  }) : fontWeight = FontWeight.w500;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontFamily: 'Manjari',
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    // If no prefix or suffix, return just the title
    if (prefix == null && suffix == null) {
      return titleWidget;
    }

    // Return with prefix/suffix
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (prefix != null) ...[
          prefix!,
          const SizedBox(width: 8),
        ],
        Flexible(child: titleWidget),
        if (suffix != null) ...[
          const SizedBox(width: 8),
          suffix!,
        ],
      ],
    );
  }
}
