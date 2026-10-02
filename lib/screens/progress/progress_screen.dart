import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/progress_summary.dart';
import '../../models/quiz_attempt.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/progress_ring.dart';

/// Every figure here is derived from Firestore documents by
/// [ProgressSummary.from] and re-derived whenever those streams emit — finishing
/// a quiz updates this screen without a refresh.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const LoadingView(message: 'Crunching your numbers'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () {
              ref.invalidate(lessonsProvider);
              ref.invalidate(progressMapProvider);
              ref.invalidate(attemptsProvider);
            },
          ),
          data: (stats) => _Body(stats: stats),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats});

  final ProgressSummary stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    if (stats.totalLessons == 0) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'Nothing to measure yet',
        message: 'Once lessons are published and you take a quiz, your stats '
            'appear here — all computed from your real results.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your progress', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Live from your quiz results — nothing simulated.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.8),
                      scheme.tertiaryContainer.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    ProgressRing(
                      value: stats.completionFraction,
                      size: 132,
                      strokeWidth: 14,
                      caption: 'of the course',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${stats.completedLessons} of ${stats.totalLessons} lessons complete',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (stats.inProgressLessons > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${stats.inProgressLessons} in progress',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 380.ms).scale(
                    begin: const Offset(0.97, 0.97),
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.quiz_rounded,
                      value: '${stats.totalAttempts}',
                      label: 'Quizzes taken',
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.verified_rounded,
                      value: '${stats.passedAttempts}',
                      label: 'Passed',
                      color: colors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.star_rounded,
                      value: '${stats.perfectQuizzes}',
                      label: 'Perfect runs',
                      color: colors.streak,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.percent_rounded,
                      value: stats.totalAttempts == 0
                          ? '—'
                          : '${stats.averageScorePercent}%',
                      label: 'Average (best attempts)',
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.dayStreak}',
                      label: stats.dayStreak == 1 ? 'Day streak' : 'Day streak',
                      color: colors.streak,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'By category',
                subtitle: 'Completion and your average score in each',
              ),
              const SizedBox(height: 14),
              for (final c in stats.categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(stats: c),
                ),
              const SizedBox(height: 14),
              SectionHeader(
                title: 'Badges',
                subtitle: '${stats.earnedBadgeCount} of ${stats.badges.length} earned',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final b in stats.badges)
                    BadgeTile(
                      badge: b,
                      onTap: () => showBadgeDetails(context, b),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Recent quizzes',
                subtitle: stats.recentAttempts.isEmpty
                    ? 'No attempts yet'
                    : 'Your last ${stats.recentAttempts.length}',
              ),
              const SizedBox(height: 12),
              if (stats.recentAttempts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Take a lesson quiz and it will show up here with your score.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                for (final a in stats.recentAttempts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AttemptRow(attempt: a),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.stats});

  final CategoryStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(stats.category, scheme);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.25), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category_rounded, size: 17, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(stats.category, style: theme.textTheme.titleMedium),
              ),
              Text(
                '${stats.completionPercent}%',
                style: theme.textTheme.titleMedium?.copyWith(color: tint),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: stats.completionFraction, color: tint),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                label: 'Done',
                value: '${stats.completedLessons}/${stats.totalLessons}',
              ),
              const SizedBox(width: 18),
              if (stats.inProgressLessons > 0)
                _MiniStat(label: 'Started', value: '${stats.inProgressLessons}'),
              if (stats.inProgressLessons > 0) const SizedBox(width: 18),
              _MiniStat(
                label: 'Avg score',
                value: stats.hasAttempts ? '${stats.averageScorePercent}%' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final tint = attempt.passed ? colors.success : colors.wrong;

    return InkWell(
      onTap: () => context.push(Routes.lesson(attempt.lessonId)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                '${attempt.percent}',
                style: theme.textTheme.titleSmall?.copyWith(color: tint),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.lessonTitle.isEmpty ? 'Lesson' : attempt.lessonTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${attempt.score}/${attempt.total} correct'
                    '${attempt.createdAt == null ? '' : ' · ${_when(attempt.createdAt!)}'}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                attempt.passed ? 'Passed' : 'Below ${AppConstants.passThresholdPercent}%',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tint, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _when(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(when);
  }
}
