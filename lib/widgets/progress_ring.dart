import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A chunky animated ring used for the dashboard's headline completion number.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 108,
    this.strokeWidth = 12,
    this.label,
    this.caption,
    this.color,
  });

  /// 0..1
  final double value;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = color ?? scheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: animated,
            strokeWidth: strokeWidth,
            trackColor: scheme.surfaceContainerHighest,
            progressColors: [ringColor, scheme.tertiary],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label ?? '${(animated * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: size * 0.24, height: 1.1),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColors,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> progressColors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;

    final progress = Paint()
      ..shader = SweepGradient(
        colors: progressColors,
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// A rounded, animated bar for per-category and per-quiz progress.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final Color? color;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => LinearProgressIndicator(
          value: animated,
          minHeight: height,
          backgroundColor: scheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(color ?? scheme.primary),
        ),
      ),
    );
  }
}
