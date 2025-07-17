import 'package:flutter/material.dart';
import 'package:helping_hands_app/utils/app_colors.dart';

class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final Function(int rating) onRatingChanged;
  final bool isInteractive;

  const StarRatingWidget({
    Key? key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starSize = 30.0,
    this.activeColor = AppColors.primaryOrange,
    this.inactiveColor = Colors.grey,
    required this.onRatingChanged,
    this.isInteractive = true,
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with SingleTickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onStarTapped(int rating) {
    if (!widget.isInteractive) return;

    setState(() {
      _currentRating = rating;
    });

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Notify parent widget
    widget.onRatingChanged(rating);
  }

  Widget _buildStar(int index) {
    final isActive = index < _currentRating;

    return GestureDetector(
      onTap: widget.isInteractive ? () => _onStarTapped(index + 1) : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale =
              index == _currentRating - 1 ? _scaleAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                isActive ? Icons.star : Icons.star_border,
                size: widget.starSize,
                color: isActive ? widget.activeColor : widget.inactiveColor,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.maxRating,
        (index) => _buildStar(index),
      ),
    );
  }
}

// Display-only star rating widget for showing ratings
class DisplayStarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;

  const DisplayStarRating({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 16.0,
    this.activeColor = AppColors.primaryOrange,
    this.inactiveColor = Colors.grey,
    this.showRatingText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1;
          IconData iconData;
          Color color;

          if (rating >= starValue) {
            iconData = Icons.star;
            color = activeColor;
          } else if (rating >= starValue - 0.5) {
            iconData = Icons.star_half;
            color = activeColor;
          } else {
            iconData = Icons.star_border;
            color = inactiveColor;
          }

          return Icon(
            iconData,
            size: starSize,
            color: color,
          );
        }),
        if (showRatingText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: starSize * 0.6,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
