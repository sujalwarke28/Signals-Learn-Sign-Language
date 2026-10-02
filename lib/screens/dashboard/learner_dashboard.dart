import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../models/progress_summary.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/medallion.dart';
import '../../widgets/pressable.dart';
import '../../widgets/reveal.dart';
import 'dashboard_canopy.dart';
import 'lesson_path.dart';
import 'recall_nudge.dart';

/// The learner's home.
///
/// Built around one question — *what do I do right now?* — and then around
/// making the answer feel like somewhere worth being. The library is drawn as a
/// path rather than listed as rows, because the thing a learner wants to see is
/// not an inventory but how far along they are and what is next.
class LearnerDashboard extends ConsumerWidget {
  const LearnerDashboard({required this.user, required this.stats, super.key});

  final AppUser? user;
  final ProgressSummary stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressMap = ref.watch(progressMapProvider).value ?? const {};
    final lessons = ref.watch(lessonsProvider).value ?? const <Lesson>[];
    final today = ref.watch(todayProvider);

    final focus = stats.continueLesson ?? stats.nextLesson;
    final recall = recallCandidate(
      lessons: lessons,
      progress: progressMap,
      today: today,
    );

    return RevealScope(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DashboardCanopy(
            user: user,
            stats: stats,
            onOpenProgress: () => context.go(Routes.progress),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (focus != null)
                    _NextUpCard(
                      lesson: focus,
                      progress:
                          progressMap[focus.id] ??
                          LessonProgress.notStarted(focus.id),
                      resuming: stats.continueLesson != null,
                    )
                  else if (stats.totalLessons == 0)
                    const _NothingYetCard()
                  else
                    _CompletionMoment(stats: stats),

                  if (recall != null) ...[
                    const SizedBox(height: 14),
                    Reveal(
                      child: _RecallCard(
                        lesson: recall,
                        days: daysBetween(
                          progressMap[recall.id]!.completedAt!,
                          today,
                        ),
                      ),
                    ),
                  ],

                  if (lessons.isNotEmpty) ...[
                    const SizedBox(height: 34),
                    Reveal(
                      child: SectionHeader(
                        title: 'Your path',
                        subtitle: stats.completedLessons == 0
                            ? 'Every sign you learn lights up the trail'
                            : '${stats.completedLessons} of '
                                  '${stats.totalLessons} signs behind you',
                      ),
                    ),
                    const SizedBox(height: 18),
                    LessonPath(
                      lessons: lessons,
                      progress: progressMap,
                      currentId: focus?.id,
                      onTap: (l) => context.push(Routes.lesson(l.id)),
                    ),
                  ],

                  const SizedBox(height: 26),
                  Reveal(
                    child: SectionHeader(
                      title: 'Badges',
                      subtitle:
                          '${stats.earnedBadgeCount} of '
                          '${stats.badges.length} earned',
                      trailing: TextButton(
                        onPressed: () => context.go(Routes.progress),
                        child: const Text('Details'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Medallions(stats: stats),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The single next action, given the room it deserves.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.lesson,
    required this.progress,
    required this.resuming,
  });

  final Lesson lesson;
  final LessonProgress progress;
  final bool resuming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(lesson.category, scheme);

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: 0.20),
                tint.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: tint.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    resuming ? 'PICK UP WHERE YOU LEFT OFF' : 'UP NEXT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: LessonCard.heroTag(lesson.id),
                    child: LessonArtwork(
                      lesson: lesson,
                      size: 78,
                      tint: tint,
                      showPlayIcon: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(status: progress.status, compact: true),
                            Text(
                              '${lesson.category} · ${lesson.durationLabel}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SoundFilledButton(
                onPressed: () => context.push(Routes.lesson(lesson.id)),
                style: FilledButton.styleFrom(
                  backgroundColor: tint,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                child: Text(resuming ? 'Finish this one' : 'Start the lesson'),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 18, end: 0, duration: 620.ms, curve: Curves.easeOutQuart);
  }
}

/// Finishing everything should feel like finishing something.
///
/// `confetti.json` has been sitting unused in the bundle; the one screen that
/// ought to fire it is this one.
class _CompletionMoment extends StatelessWidget {
  const _CompletionMoment({required this.stats});

  final ProgressSummary stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.success.withValues(alpha: 0.20),
                scheme.primary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.success.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: colors.success.withValues(alpha: 0.16),
                blurRadius: 30,
                spreadRadius: -12,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!still)
                Positioned(
                  top: -40,
                  left: -30,
                  right: -30,
                  height: 190,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.75,
                      child: Lottie.asset(
                        'assets/lottie/confetti.json',
                        repeat: false,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: colors.success,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Every sign learned',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All ${stats.totalLessons}, averaging '
                    '${stats.averageScorePercent}%. The next step is not another '
                    'lesson — it is using one of these on somebody.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SoundFilledButton(
                          onPressed: () => context.go(Routes.lessons),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Revisit a sign'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SoundOutlinedButton(
                          onPressed: () => context.go(Routes.community),
                          child: const Text('Community'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutQuart,
          duration: 620.ms,
        );
  }
}

/// Spaced repetition, asked as a question rather than issued as a task.
class _RecallCard extends StatelessWidget {
  const _RecallCard({required this.lesson, required this.days});

  final Lesson lesson;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: colors.streak.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.streak.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.streak, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Still got it?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  'You learned "${lesson.title}" ${agoLabel(days)}. '
                  'Thirty seconds to be sure.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SoundOutlinedButton(
            onPressed: () =>
                context.push(Routes.watch(lesson.id, rewatch: true)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: colors.streak,
              side: BorderSide(color: colors.streak.withValues(alpha: 0.45)),
            ),
            child: const Text('Rewatch'),
          ),
        ],
      ),
    );
  }
}

/// Badges as medallions rather than chips: circular, lit when earned, and
/// visibly dormant rather than merely grey when not.
class _Medallions extends StatelessWidget {
  const _Medallions({required this.stats});

  final ProgressSummary stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: stats.badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => Reveal(
          delay: Duration(milliseconds: i * 55),
          offset: 14,
          child: Medallion(
            badge: stats.badges[i],
            onTap: () => showBadgeDetails(context, stats.badges[i]),
          ),
        ),
      ),
    );
  }
}

class _NothingYetCard extends StatelessWidget {
  const _NothingYetCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_empty_rounded, color: scheme.primary, size: 26),
          const SizedBox(height: 14),
          Text('No lessons yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'They appear here the moment they are published. '
            'Nothing to do on your side.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
