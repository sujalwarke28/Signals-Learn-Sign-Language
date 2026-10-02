import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../models/progress_summary.dart';
import '../../providers/auth_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../router/app_router.dart';
import '../auth/sign_out_action.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final summary = ref.watch(progressSummaryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const LoadingView(message: 'Loading your progress'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () {
              ref.invalidate(lessonsProvider);
              ref.invalidate(progressMapProvider);
              ref.invalidate(attemptsProvider);
            },
          ),
          data: (stats) => _DashboardBody(user: user, stats: stats),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.user, required this.stats});

  final AppUser? user;
  final ProgressSummary stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final progressMap = ref.watch(progressMapProvider).value ?? const {};

    final focus = stats.continueLesson ?? stats.nextLesson;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Greeting(user: user, streak: stats.dayStreak),
              const SizedBox(height: 22),
              _HeadlineCard(stats: stats),
              const SizedBox(height: 18),
              if (focus != null) ...[
                SectionHeader(
                  title: stats.continueLesson != null ? 'Keep going' : 'Start here',
                  subtitle: stats.continueLesson != null
                      ? 'You left this one part-way through'
                      : 'Your next lesson is ready',
                ),
                const SizedBox(height: 10),
                _ContinueCard(
                  lesson: focus,
                  progress: progressMap[focus.id] ?? LessonProgress.notStarted(focus.id),
                ),
                const SizedBox(height: 24),
              ] else if (stats.totalLessons == 0) ...[
                _NoContentCard(isAdmin: user?.isAdmin ?? false),
                const SizedBox(height: 24),
              ] else ...[
                _AllDoneCard(stats: stats),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.task_alt_rounded,
                      value: '${stats.completedLessons}/${stats.totalLessons}',
                      label: 'Lessons done',
                      color: colors.success,
                      onTap: () => context.go(Routes.lessons),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.emoji_events_rounded,
                      value: stats.totalAttempts == 0
                          ? '—'
                          : '${stats.averageScorePercent}%',
                      label: 'Avg quiz score',
                      color: scheme.primary,
                      onTap: () => context.go(Routes.progress),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.dayStreak}',
                      label: stats.dayStreak == 1 ? 'Day streak' : 'Day streak',
                      color: colors.streak,
                      onTap: () => context.go(Routes.progress),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms).moveY(begin: 14, end: 0),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Badges',
                subtitle: '${stats.earnedBadgeCount} of ${stats.badges.length} earned',
                trailing: TextButton(
                  onPressed: () => context.go(Routes.progress),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: stats.badges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => BadgeTile(
                    badge: stats.badges[i],
                    onTap: () => showBadgeDetails(context, stats.badges[i]),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Your categories',
                trailing: TextButton(
                  onPressed: () => context.go(Routes.progress),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(height: 10),
              if (stats.categories.isEmpty)
                Text(
                  'Categories appear once lessons are added.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                )
              else
                for (final c in stats.categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryRow(stats: c),
                  ),
              if (user?.isAdmin ?? false) ...[
                const SizedBox(height: 14),
                const _AdminCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.user, required this.streak});

  final AppUser? user;
  final int streak;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeGreeting,',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                user?.firstName ?? 'there',
                style: theme.textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.streak.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                        size: 18, color: colors.streak)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 5),
                Text(
                  '$streak',
                  style: theme.textTheme.titleMedium?.copyWith(color: colors.streak),
                ),
              ],
            ),
          ),
        Pressable(
          borderRadius: 100,
          onTap: () => context.push(Routes.settings),
          semanticLabel: 'Profile and settings',
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user?.initials ?? '?',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
        // Settings holds the same action, but signing out shouldn't cost a trip
        // through another screen to find. Compact, so the greeting keeps its
        // room next to a streak chip at phone width.
        IconButton(
          onPressed: () => confirmSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded),
          color: scheme.onSurfaceVariant,
          tooltip: 'Sign out',
          visualDensity: VisualDensity.compact,
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).moveY(begin: -10, end: 0);
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.stats});

  final ProgressSummary stats;

  String get _encouragement {
    if (stats.totalLessons == 0) return 'Lessons are on the way.';
    if (stats.completedLessons == 0) return 'Your first lesson is the hardest. Go get it.';
    if (stats.completionPercent == 100) return 'Every lesson done. Genuinely impressive.';
    if (stats.completionPercent >= 60) return 'You\'re well past halfway now.';
    if (stats.completionPercent >= 25) return 'Nice momentum — keep it rolling.';
    return 'Off to a good start.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.85),
            scheme.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: stats.completionFraction,
            size: 100,
            caption: 'complete',
            color: scheme.primary,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your course', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${stats.completedLessons} of ${stats.totalLessons} lessons finished'
                  '${stats.inProgressLessons > 0 ? ', ${stats.inProgressLessons} in progress' : ''}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  _encouragement,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );

    return Pressable(
      borderRadius: 28,
      onTap: () => context.go(Routes.progress),
      semanticLabel: 'Course progress — open details',
      child: card,
    ).animate().fadeIn(delay: 80.ms, duration: 400.ms).scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lesson, required this.progress});

  final Lesson lesson;
  final LessonProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(lesson.category, scheme);

    return Pressable(
      onTap: () => context.push(Routes.lesson(lesson.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: tint.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Hero(
              tag: LessonCard.heroTag(lesson.id),
              child: LessonArtwork(
                lesson: lesson,
                size: 66,
                tint: tint,
                showPlayIcon: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusPill(status: progress.status),
                      const SizedBox(width: 8),
                      Text(
                        lesson.durationLabel,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 120.ms).moveX(begin: -12, end: 0, curve: Curves.easeOutCubic);
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({required this.stats});

  final ProgressSummary stats;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: colors.success, size: 30)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.04, end: 0.04, duration: 1400.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Library complete',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'All ${stats.totalLessons} lessons passed, averaging '
                  '${stats.averageScorePercent}%. Retake any quiz to push it higher.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoContentCard extends StatelessWidget {
  const _NoContentCard({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text('No lessons yet',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'You\'re an admin — add the first lesson and it will appear here '
                    'for every learner straight away.'
                : 'Lessons show up here the moment an admin publishes them. '
                    'Nothing to do on your side.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            SoundFilledButton(
              onPressed: () => context.push(Routes.addLesson),
              icon: const Icon(Icons.add_rounded),
              child: const Text('Add a lesson'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.stats});

  final CategoryStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(stats.category, scheme);

    // Preselect the library's category chip before switching tabs, so the tap
    // lands on just this category instead of the whole catalogue.
    void openCategory() {
      ref.read(lessonFilterProvider.notifier).select(stats.category);
      context.go(Routes.lessons);
    }

    return Pressable(
      borderRadius: 16,
      onTap: openCategory,
      semanticLabel: '${stats.category}: ${stats.completedLessons} of '
          '${stats.totalLessons} lessons done',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(stats.category, style: theme.textTheme.titleSmall),
                ),
                Text(
                  '${stats.completedLessons}/${stats.totalLessons}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 7),
            ProgressBar(value: stats.completionFraction, color: tint, height: 8),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pressable(
      onTap: () => context.push(Routes.addLesson),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin tools',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    'Upload a lesson video and write its quiz',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
