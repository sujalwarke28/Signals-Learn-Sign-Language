import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/pressable.dart';

/// The lesson library as a route you walk, not a list you scan.
///
/// A flat list says "here is the inventory". A path says "you are here, that is
/// behind you, this is next" — the same information carrying a sense of travel,
/// which is most of what makes a learning app feel like it is going somewhere.
///
/// The curve is drawn, not decorative: the lit section is exactly how far along
/// the learner is, so the picture and the number can never disagree.
class LessonPath extends StatefulWidget {
  const LessonPath({
    super.key,
    required this.lessons,
    required this.progress,
    required this.onTap,
    this.currentId,
  });

  final List<Lesson> lessons;
  final Map<String, LessonProgress> progress;
  final void Function(Lesson lesson) onTap;

  /// The node that breathes — where the learner should go next.
  final String? currentId;

  /// Vertical distance between node centres.
  static const rowHeight = 118.0;
  static const nodeSize = 66.0;

  @override
  State<LessonPath> createState() => _LessonPathState();
}

class _LessonPathState extends State<LessonPath> with TickerProviderStateMixin {
  /// Draws the trail on, once, on arrival.
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: 600 + 90 * widget.lessons.length.clamp(0, 8),
    ),
  )..forward();

  /// The slow halo on the current node. Separate controller because it repeats
  /// forever and the draw-on must not.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _draw.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Node centres: a gentle wave down the column. The phase is irrational-ish
  /// so the left/right rhythm doesn't fall into an obvious zigzag.
  List<Offset> _points(double width) {
    final amplitude = math.min(width * 0.27, 96.0);
    final cx = width / 2;
    return [
      for (var i = 0; i < widget.lessons.length; i++)
        Offset(
          cx + amplitude * math.sin(i * 0.85 + 0.4),
          LessonPath.nodeSize / 2 + i * LessonPath.rowHeight,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);

    if (widget.lessons.isEmpty) return const SizedBox.shrink();

    final done = widget.lessons
        .where((l) => widget.progress[l.id]?.isCompleted ?? false)
        .length;
    final reached = widget.lessons.isEmpty
        ? 0.0
        : (done / widget.lessons.length).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final points = _points(width);
        final height =
            LessonPath.nodeSize +
            (widget.lessons.length - 1) * LessonPath.rowHeight +
            46; // room for the label under the last node

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _draw,
                  builder: (context, _) => CustomPaint(
                    painter: _TrailPainter(
                      points: points,
                      drawn: still
                          ? 1
                          : Curves.easeOutCubic.transform(_draw.value),
                      reached: reached,
                      lit: scheme.primary,
                      unlit: scheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < widget.lessons.length; i++)
                _node(context, i, points[i], still),
            ],
          ),
        );
      },
    );
  }

  Widget _node(BuildContext context, int i, Offset p, bool still) {
    final lesson = widget.lessons[i];
    final progress =
        widget.progress[lesson.id] ?? LessonProgress.notStarted(lesson.id);
    final isCurrent = lesson.id == widget.currentId;

    // Nodes arrive just behind the line that reaches them.
    final start = (i / (widget.lessons.length + 1)).clamp(0.0, 0.85);
    final appear = still
        ? const AlwaysStoppedAnimation(1.0)
        : CurvedAnimation(
            parent: _draw,
            curve: Interval(
              start,
              (start + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          );

    return Positioned(
      left: p.dx - LessonPath.nodeSize / 2,
      top: p.dy - LessonPath.nodeSize / 2,
      width: LessonPath.nodeSize,
      child: ScaleTransition(
        scale: appear,
        child: FadeTransition(
          opacity: appear.drive(Tween(begin: 0.0, end: 1.0)),
          child: _PathNode(
            lesson: lesson,
            progress: progress,
            isCurrent: isCurrent,
            pulse: _pulse,
            still: still,
            onTap: () => widget.onTap(lesson),
          ),
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.lesson,
    required this.progress,
    required this.isCurrent,
    required this.pulse,
    required this.still,
    required this.onTap,
  });

  final Lesson lesson;
  final LessonProgress progress;
  final bool isCurrent;
  final Animation<double> pulse;
  final bool still;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final tint = AppPalette.categoryTint(lesson.category, scheme);
    final done = progress.isCompleted;

    final (fill, border, glyphColor) = done
        ? (tint.withValues(alpha: 0.22), tint, tint)
        : isCurrent
        ? (tint.withValues(alpha: 0.16), tint, tint)
        : (
            scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            scheme.outlineVariant,
            scheme.onSurfaceVariant,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pressable(
          borderRadius: 100,
          onTap: onTap,
          semanticLabel: '${lesson.title}, ${progress.status.label}',
          child: SizedBox(
            width: LessonPath.nodeSize,
            height: LessonPath.nodeSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // The halo: a ring that swells and fades outward, so the eye is
                // pulled to the one node worth tapping without anything moving
                // fast enough to nag.
                if (isCurrent && !still)
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, _) {
                      final t = pulse.value;
                      return Container(
                        width: LessonPath.nodeSize * (1 + 0.42 * t),
                        height: LessonPath.nodeSize * (1 + 0.42 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tint.withValues(alpha: 0.38 * (1 - t)),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: border, width: 2),
                    boxShadow: [
                      if (done || isCurrent)
                        BoxShadow(
                          color: tint.withValues(alpha: 0.26),
                          blurRadius: 18,
                          spreadRadius: -4,
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : LessonArtwork.glyphFor(lesson.category),
                    color: glyphColor,
                    size: done ? 28 : 24,
                  ),
                ),
                if (done)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.done_rounded,
                        size: 10,
                        color: scheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          lesson.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: done || isCurrent
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.drawn,
    required this.reached,
    required this.lit,
    required this.unlit,
  });

  final List<Offset> points;

  /// How much of the whole trail has been drawn on, 0..1. Entrance only.
  final double drawn;

  /// How far the learner has actually got, 0..1.
  final double reached;

  final Color lit;
  final Color unlit;

  /// Control points pulled vertically give an S between each pair of nodes —
  /// the shape a path takes going round something, rather than a kinked
  /// polyline.
  Path _route() {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final pull = (b.dy - a.dy) * 0.52;
      path.cubicTo(a.dx, a.dy + pull, b.dx, b.dy - pull, b.dx, b.dy);
    }
    return path;
  }

  Path _upTo(PathMetric m, double fraction) =>
      m.extractPath(0, m.length * fraction.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final metrics = _route().computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = unlit.withValues(alpha: 0.45);

    // The dim trail draws on first, then the lit section fills along it.
    canvas.drawPath(_upTo(m, drawn), base);

    final litEnd = reached * drawn;
    if (litEnd <= 0) return;

    canvas.drawPath(
      _upTo(m, litEnd),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lit.withValues(alpha: 0.55), lit],
        ).createShader(Offset.zero & size),
    );

    // A soft bloom under the lit section, so it reads as travelled rather than
    // merely coloured in.
    canvas.drawPath(
      _upTo(m, litEnd),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..color = lit.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.drawn != drawn ||
      old.reached != reached ||
      old.lit != lit ||
      old.points != points;
}
