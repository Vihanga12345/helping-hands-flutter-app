import 'package:flutter/material.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String fallbackText;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  const ProfileImageWidget({
    Key? key,
    this.imageUrl,
    this.size = 120,
    this.fallbackText = 'U',
    this.backgroundColor = AppColors.primaryGreen,
    this.borderColor = AppColors.primaryGreen,
    this.borderWidth = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackImage();
    }

    // Handle base64 data URL
    if (imageUrl!.startsWith('data:image')) {
      try {
        final base64Data = imageUrl!.split(',')[1];
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildFallbackImage();
      }
    }

    // Handle network URL
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackImage();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          width: size,
          height: size,
          color: AppColors.lightGrey,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: Center(
        child: Text(
          fallbackText,
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
