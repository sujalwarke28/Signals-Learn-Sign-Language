import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_theme.dart';
import '../models/lesson_progress.dart';
import '../models/progress_summary.dart';
import 'pressable.dart';

/// Caps content width and centres it, so the web build doesn't stretch a
/// phone-shaped layout across a 27" monitor.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Breakpoints. Phone is the design target; the wider tiers only widen grids.
class Breakpoints {
  const Breakpoints._();
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;

  static int lessonColumns(double width) {
    if (width >= expanded) return 3;
    if (width >= compact) return 2;
    return 1;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact;
}

/// The little coloured status chip on lesson cards.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final LessonStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (bg, fg, icon) = switch (status) {
      LessonStatus.completed => (
          colors.success.withValues(alpha: 0.16),
          colors.success,
          Icons.check_circle_rounded,
        ),
      LessonStatus.inProgress => (
          colors.streak.withValues(alpha: 0.18),
          colors.streak,
          Icons.play_circle_fill_rounded,
        ),
      LessonStatus.notStarted => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.lock_open_rounded,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: fg),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              status.label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small labelled number, used in rows on the dashboard and progress screen.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  /// When set, the tile becomes a touch target: it dips under the finger, plays
  /// the tap cue, and grows a chevron, so the affordance is visible instead of
  /// something you only find by poking at it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              if (onTap != null) ...[
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 24, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Pressable(
      borderRadius: 20,
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: tile,
    );
  }
}

/// A badge, greyed out until earned.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge, this.onTap});

  final EarnedBadge badge;

  /// Tapping is the only way a badge's meaning is reachable on a phone — the
  /// [Tooltip] below opens on a long press, which nobody tries.
  final VoidCallback? onTap;

  static const _icons = {
    BadgeIcon.footprints: Icons.directions_walk_rounded,
    BadgeIcon.quiz: Icons.quiz_rounded,
    BadgeIcon.star: Icons.star_rounded,
    BadgeIcon.flame: Icons.local_fire_department_rounded,
    BadgeIcon.mountain: Icons.terrain_rounded,
    BadgeIcon.trophy: Icons.emoji_events_rounded,
  };

  /// The glyph for a badge, so [showBadgeDetails] can draw the same one.
  static IconData iconFor(BadgeIcon icon) => _icons[icon]!;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final tint = badge.earned ? colors.streak : scheme.onSurfaceVariant;

    final tile = Tooltip(
      message: badge.description,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: badge.earned
              ? tint.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badge.earned
                ? tint.withValues(alpha: 0.45)
                : scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              badge.earned ? _icons[badge.icon]! : Icons.lock_rounded,
              color: tint.withValues(alpha: badge.earned ? 1 : 0.5),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              badge.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badge.earned ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );

    final target = onTap == null
        ? tile
        : Pressable(
            borderRadius: 20,
            onTap: onTap,
            semanticLabel:
                '${badge.label}. ${badge.earned ? 'Earned' : 'Not earned yet'}',
            child: tile,
          );

    // Earned badges get a one-off pop so unlocking one is noticeable.
    return badge.earned
        ? target.animate().scale(
            begin: const Offset(0.86, 0.86),
            end: const Offset(1, 1),
            duration: 420.ms,
            curve: Curves.elasticOut,
          )
        : target;
  }
}

/// Explains one badge: what earns it, and whether it has been earned.
///
/// Lives next to [BadgeTile] so the dashboard and the progress screen open the
/// same sheet rather than each growing their own.
Future<void> showBadgeDetails(BuildContext context, EarnedBadge badge) {
  final scheme = Theme.of(context).colorScheme;
  final colors = AppColors.of(context);
  final tint = badge.earned ? colors.streak : scheme.onSurfaceVariant;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.earned
                      ? BadgeTile.iconFor(badge.icon)
                      : Icons.lock_rounded,
                  size: 34,
                  color: tint,
                ),
              ),
              const SizedBox(height: 16),
              Text(badge.label, style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge.earned ? 'Earned' : 'Not earned yet',
                  style: text.labelMedium
                      ?.copyWith(color: tint, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Friendly full-panel empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -7, duration: 2200.ms, curve: Curves.easeInOut),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Consistent error panel for a failed provider.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = error.toString();
    final isPermission = message.contains('permission-denied') ||
        message.toLowerCase().contains('insufficient permissions');

    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: isPermission ? 'Not allowed to read that' : 'Something went wrong',
      message: isPermission
          ? 'Firestore rejected the read. Check that the security rules are '
              'deployed and that you are signed in.\n\n$message'
          : message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                minimumSize: const Size(160, 48),
              ),
            ),
    );
  }
}

/// A soft full-bleed loading state that matches the theme.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      );
}
