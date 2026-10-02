import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/progress_summary.dart';
import '../../widgets/count_up.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/signing_space.dart';
import '../auth/sign_out_action.dart';
import 'dashboard_header.dart';

/// The top of the learner's screen: greeting, standing, and a sense of place.
///
/// This used to be a grey information band. The job it actually has is to make
/// the app feel like somewhere worth coming back to — so it carries the same
/// drawn-motion motif as the landing page, which is what ties the two halves of
/// the product together visually.
class DashboardCanopy extends ConsumerWidget {
  const DashboardCanopy({
    super.key,
    required this.user,
    required this.stats,
    required this.onOpenProgress,
  });

  final AppUser? user;
  final ProgressSummary stats;
  final VoidCallback onOpenProgress;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// One warm line that changes with where they actually are. Never a scold,
  /// and never the same sentence two states running.
  String get _line {
    if (stats.totalLessons == 0) return 'Lessons are on their way.';
    if (stats.completedLessons == 0) {
      return 'Your first sign is four minutes away.';
    }
    if (stats.completionPercent == 100) {
      return 'You have learned every sign here. That is a real thing to have done.';
    }
    if (stats.completionPercent >= 60) return 'You are well past halfway.';
    if (stats.dayStreak >= 3) return 'You keep showing up. It shows.';
    return 'Picking it up, one sign at a time.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(34),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.17),
                  scheme.tertiary.withValues(alpha: 0.10),
                  scheme.surface.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Faint, because it sits under text. At full strength it would be
                // a landing page, not a header.
                Positioned(
                  right: -70,
                  top: -40,
                  width: 320,
                  height: 300,
                  child: IgnorePointer(
                    child: SigningSpace(
                      intensity: 0.42,
                      period: const Duration(seconds: 15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 18, 26),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_timeGreeting,',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    user?.firstName ?? 'there',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(fontSize: 34, height: 1.05),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            AvatarButton(user: user, size: 44),
                            IconButton(
                              onPressed: () => confirmSignOut(context, ref),
                              icon: const Icon(Icons.logout_rounded),
                              color: scheme.onSurfaceVariant,
                              tooltip: 'Sign out',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _line,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _Standing(
                          stats: stats,
                          streakColor: colors.streak,
                          onTap: onOpenProgress,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 450.ms)
        .moveY(begin: -14, end: 0, curve: Curves.easeOutQuart);
  }
}

/// The ring, the count, and the streak — one object instead of three tiles.
class _Standing extends StatelessWidget {
  const _Standing({
    required this.stats,
    required this.streakColor,
    required this.onTap,
  });

  final ProgressSummary stats;
  final Color streakColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          ProgressRing(
            value: stats.completionFraction,
            size: 84,
            caption: 'done',
            color: scheme.primary,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CountUp(
                      value: stats.completedLessons,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 32,
                        height: 1,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'of ${stats.totalLessons} signs learned',
                        maxLines: 2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StreakChip(streak: stats.dayStreak, color: streakColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, required this.color});

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warm = streak > 0;

    // At zero this is an invitation, not a broken chain. Nothing on this screen
    // is allowed to make someone feel behind.
    final label = switch (streak) {
      0 => 'A good day to start again',
      1 => 'Practised today',
      _ => '$streak days in a row',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: warm
            ? color.withValues(alpha: 0.15)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: warm
              ? color.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warm
                ? Icons.local_fire_department_rounded
                : Icons.wb_twilight_rounded,
            size: 15,
            color: warm ? color : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: warm ? color : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
