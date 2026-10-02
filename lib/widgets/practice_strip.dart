import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';
import '../screens/progress/practice_history.dart';

/// Quiz attempts per day over the last fortnight.
///
/// The question it answers is "have I been showing up?", which is magnitude
/// over discrete days — so bars, not a line. One series, so no legend: the
/// heading names it. Days without practice keep a visible stub rather than
/// vanishing, because a gap in the row is the information.
///
/// Identity is never carried by colour alone: every bar has its weekday letter
/// under it, the total is stated in words above, and each bar carries a
/// semantic label for screen readers.
class PracticeStrip extends StatelessWidget {
  const PracticeStrip({super.key, required this.days});

  final List<PracticeDay> days;

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);

    if (days.isEmpty) return const SizedBox.shrink();

    final busiest = days
        .map((d) => d.attempts)
        .fold(0, (a, b) => a > b ? a : b);
    final total = days.fold(0, (a, d) => a + d.attempts);
    final active = days.where((d) => d.practised).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Practice, last 14 days', style: theme.textTheme.titleMedium),
          const SizedBox(height: 3),
          // The numbers in words: this is the non-visual reading of the chart,
          // not decoration.
          Text(
            total == 0
                ? 'No quizzes yet this fortnight'
                : '$total ${total == 1 ? 'quiz' : 'quizzes'} across '
                      '$active ${active == 1 ? 'day' : 'days'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  Expanded(
                    child: _Bar(
                      day: days[i],
                      busiest: busiest,
                      letter: _weekdayLetters[days[i].date.weekday - 1],
                      isToday: i == days.length - 1,
                      active: colors.streak,
                      idle: scheme.outlineVariant,
                      delay: still
                          ? Duration.zero
                          : Duration(milliseconds: 30 * i),
                      still: still,
                    ),
                  ),
                  // A 2px gutter between bars, so adjacent fills never touch.
                  if (i != days.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.busiest,
    required this.letter,
    required this.isToday,
    required this.active,
    required this.idle,
    required this.delay,
    required this.still,
  });

  final PracticeDay day;
  final int busiest;
  final String letter;
  final bool isToday;
  final Color active;
  final Color idle;
  final Duration delay;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // A quiet floor for empty days: the absence has to be visible, but it must
    // not read as a small amount of practice.
    const floor = 5.0;
    const ceiling = 62.0;
    final fraction = busiest == 0 ? 0.0 : day.attempts / busiest;
    final height = day.practised ? floor + (ceiling - floor) * fraction : floor;

    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: day.practised
            ? active.withValues(alpha: 0.35 + 0.65 * fraction)
            : idle.withValues(alpha: 0.30),
        // Rounded data-end on top, square where it meets the baseline.
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );

    return Semantics(
      label:
          '${_dayLabel(day.date)}: '
          '${day.attempts == 0 ? 'no quizzes' : '${day.attempts} '
                    '${day.attempts == 1 ? 'quiz' : 'quizzes'}'}',
      child: Tooltip(
        message: '${day.attempts} on ${_dayLabel(day.date)}',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            still
                ? bar
                : bar
                      .animate()
                      .scaleY(
                        begin: 0,
                        end: 1,
                        alignment: Alignment.bottomCenter,
                        duration: 520.ms,
                        delay: delay,
                        curve: Curves.easeOutQuart,
                      )
                      .fadeIn(duration: 240.ms, delay: delay),
            const SizedBox(height: 7),
            Text(
              letter,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            // Today gets a dot instead of a label, so the eye finds "now"
            // without fourteen competing numbers.
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: isToday ? scheme.onSurface : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime d) => '${d.day}/${d.month}';
}
