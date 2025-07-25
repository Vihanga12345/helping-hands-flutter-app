import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';

/// Widget that provides audio visualization effects
/// Shows animated bars or waves to indicate voice activity
class AudioVisualizer extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final double width;
  final double height;
  final AudioVisualizerType type;

  const AudioVisualizer({
    super.key,
    required this.isActive,
    this.color,
    this.width = 120.0,
    this.height = 60.0,
    this.type = AudioVisualizerType.bars,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Individual bar controllers for staggered animation
    _barControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    // Create animations for each bar
    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Start animations if active
    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startAnimations() {
    _controller.repeat();
    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isActive) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    _controller.stop();
    for (final controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primaryGreen;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.type == AudioVisualizerType.bars
          ? _buildBarsVisualizer(effectiveColor)
          : _buildWaveVisualizer(effectiveColor),
    );
  }

  /// Build animated bars visualizer
  Widget _buildBarsVisualizer(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            final height = widget.isActive
                ? (widget.height * 0.3) +
                    (widget.height * 0.6 * _barAnimations[index].value)
                : widget.height * 0.2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? color
                        .withOpacity(0.7 + (0.3 * _barAnimations[index].value))
                    : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          },
        );
      }),
    );
  }

  /// Build animated wave visualizer
  Widget _buildWaveVisualizer(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animationValue: widget.isActive ? _controller.value : 0.0,
            color: color,
            isActive: widget.isActive,
          ),
          size: Size(widget.width, widget.height),
        );
      },
    );
  }
}

/// Custom painter for wave visualizer
class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isActive;

  WavePainter({
    required this.animationValue,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) {
      // Draw flat line when inactive
      final paint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final frequency = 2.0; // Number of waves
    final amplitude = size.height * 0.3; // Wave height
    final phase = animationValue * 2 * math.pi; // Animation phase

    // Start point
    path.moveTo(0, size.height / 2);

    // Generate wave points
    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = x / size.width;
      final waveValue =
          math.sin((normalizedX * frequency * 2 * math.pi) + phase);
      final y = (size.height / 2) + (waveValue * amplitude);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive;
  }
}

/// Audio visualizer types
enum AudioVisualizerType {
  bars,
  wave,
}

/// Preset audio visualizer widgets for common use cases
class AudioVisualizerPresets {
  /// Small circular visualizer for buttons
  static Widget circular({
    required bool isActive,
    Color? color,
    double size = 40.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: AudioVisualizer(
        isActive: isActive,
        color: color,
        width: size * 0.7,
        height: size * 0.4,
        type: AudioVisualizerType.bars,
      ),
    );
  }

  /// Medium-sized visualizer for status indicators
  static Widget status({
    required bool isActive,
    Color? color,
  }) {
    return AudioVisualizer(
      isActive: isActive,
      color: color,
      width: 80.0,
      height: 40.0,
      type: AudioVisualizerType.bars,
    );
  }

  /// Large visualizer for main display
  static Widget main({
    required bool isActive,
    Color? color,
    AudioVisualizerType type = AudioVisualizerType.wave,
  }) {
    return AudioVisualizer(
      isActive: isActive,
      color: color,
      width: 200.0,
      height: 80.0,
      type: type,
    );
  }

  /// Compact visualizer for list items
  static Widget compact({
    required bool isActive,
    Color? color,
  }) {
    return AudioVisualizer(
      isActive: isActive,
      color: color,
      width: 60.0,
      height: 24.0,
      type: AudioVisualizerType.bars,
    );
  }
}
