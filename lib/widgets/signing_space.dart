import 'dart:math' as math;
// PathMetric isn't part of what material.dart re-exports.
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// The hero visual: a ribbon of motion tracing a loop through the signing space.
///
/// In sign language the "signing space" is the invisible box in front of the
/// torso where signs are made — meaning lives in *movement through space*, not
/// in a static shape. A still illustration of a hand would say nothing about
/// that; a travelling trail says it without needing to draw a hand at all.
///
/// Deliberately abstract: no literal hand, so nothing here can misrepresent a
/// real sign to someone who hasn't learnt one yet.
class SigningSpace extends StatefulWidget {
  const SigningSpace({
    super.key,
    this.period = const Duration(seconds: 9),
    this.intensity = 1,
  });

  /// One full lap of the loop. Slow on purpose — this sits behind a headline,
  /// and anything quicker pulls the eye off the words.
  final Duration period;

  /// Scales every alpha. The landing page wants this at full strength; behind
  /// dashboard text it needs to drop to a suggestion of movement, or it
  /// competes with the content sitting on top of it.
  final double intensity;

  @override
  State<SigningSpace> createState() => _SigningSpaceState();
}

class _SigningSpaceState extends State<SigningSpace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Someone who has asked the OS to stop animations gets the whole path at
    // rest rather than nothing — the composition still reads, it just holds
    // still. This matters more than usual in an app about accessibility.
    final still = MediaQuery.disableAnimationsOf(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _TrailPainter(
            t: still ? 0.0 : _c.value,
            head: scheme.primary,
            tail: scheme.tertiary,
            still: still,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.t,
    required this.head,
    required this.tail,
    required this.still,
    this.intensity = 1,
  });

  /// Position of the leading tip along the loop, 0..1.
  final double t;
  final Color head;
  final Color tail;
  final bool still;
  final double intensity;

  /// How much of the loop is lit behind the tip. Much more than half and the
  /// trail stops reading as a direction of travel.
  static const _trail = 0.38;
  static const _segments = 44;

  /// A hand doesn't travel in circles. It arcs out, hesitates, crosses back
  /// and returns — so the loop is asymmetric and never quite repeats its own
  /// curvature.
  Path _loop(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.18, h * 0.62)
      ..cubicTo(w * 0.21, h * 0.27, w * 0.45, h * 0.17, w * 0.54, h * 0.39)
      ..cubicTo(w * 0.61, h * 0.56, w * 0.43, h * 0.65, w * 0.47, h * 0.79)
      ..cubicTo(w * 0.51, h * 0.94, w * 0.75, h * 0.93, w * 0.83, h * 0.70)
      ..cubicTo(w * 0.91, h * 0.46, w * 0.71, h * 0.29, w * 0.55, h * 0.33)
      ..cubicTo(w * 0.36, h * 0.37, w * 0.14, h * 0.44, w * 0.18, h * 0.62)
      ..close();
  }

  /// [PathMetric.extractPath] returns nothing when `start > end`, which happens
  /// every lap as the trail crosses the seam. Stitching the two pieces keeps
  /// the ribbon continuous instead of blinking once per revolution.
  Path _slice(PathMetric m, double from, double to) {
    final len = m.length;
    final a = from % len;
    final b = to % len;
    if (b >= a) return m.extractPath(a, b);
    return m.extractPath(a, len)..addPath(m.extractPath(0, b), Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final metrics = _loop(size).computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final len = m.length;

    // A wash behind the ribbon so it reads as lit rather than drawn on.
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.5),
      size.shortestSide * 0.52,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                head.withValues(alpha: 0.12 * intensity),
                head.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.52, size.height * 0.5),
                radius: size.shortestSide * 0.52,
              ),
            ),
    );

    if (still) {
      canvas.drawPath(
        _loop(size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = head.withValues(alpha: 0.30 * intensity),
      );
      return;
    }

    final tip = t * len;
    for (var i = 0; i < _segments; i++) {
      // 0 at the faint tail, 1 at the bright tip.
      final a = i / _segments;
      final b = (i + 1) / _segments;
      final seg = _slice(
        m,
        tip - _trail * len * (1 - a),
        tip - _trail * len * (1 - b),
      );

      // Both taper together: a stroke that thins without also dimming looks
      // like a wire, not a movement.
      canvas.drawPath(
        seg,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.6 + 6.4 * math.pow(a, 1.4).toDouble()
          ..color = Color.lerp(
            tail,
            head,
            a,
          )!.withValues(alpha: 0.75 * intensity * math.pow(a, 1.6).toDouble()),
      );
    }

    // The tip itself, blurred into a soft point of light.
    final pos = m.getTangentForOffset(tip % len)?.position;
    if (pos != null) {
      canvas.drawCircle(
        pos,
        9,
        Paint()
          ..color = head.withValues(alpha: 0.42 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        pos,
        4.2,
        Paint()..color = head.withValues(alpha: intensity.clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.t != t ||
      old.head != head ||
      old.tail != tail ||
      old.still != still ||
      old.intensity != intensity;
}
