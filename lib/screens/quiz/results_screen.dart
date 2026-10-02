import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz_attempt.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.lessonId, this.attempt});

  final String lessonId;

  /// Passed through `extra` from the quiz. Null when the screen is reached by
  /// URL (a browser refresh on the web build), in which case we fall back to the
  /// learner's latest stored attempt for this lesson.
  final QuizAttempt? attempt;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final _celebration = GlobalKey<CelebrationScopeState>();
  bool _celebrated = false;

  QuizAttempt? get _attempt {
    if (widget.attempt != null) return widget.attempt;
    final attempts = ref.watch(attemptsProvider).value ?? const [];
    return attempts.where((a) => a.lessonId == widget.lessonId).firstOrNull;
  }

  void _celebrateOnce(bool passed) {
    if (_celebrated || !passed) return;
    _celebrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _celebration.currentState?.celebrate();
      ref.playSfx(Sfx.celebrate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    final summary = ref.watch(progressSummaryProvider).value;
    final lessons = ref.watch(lessonsProvider).value ?? const [];

    if (attempt == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go(Routes.lesson(widget.lessonId)),
          ),
        ),
        body: const LoadingView(message: 'Loading your result'),
      );
    }

    _celebrateOnce(attempt.passed);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final tint = attempt.passed ? colors.success : colors.streak;

    // "Next lesson" = the first lesson after this one that isn't finished.
    final currentIndex = lessons.indexWhere((l) => l.id == widget.lessonId);
    final nextLesson = currentIndex == -1
        ? null
        : lessons.skip(currentIndex + 1).firstOrNull ?? summary?.nextLesson;

    return CelebrationScope(
      key: _celebration,
      child: Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Back to lesson',
                    onPressed: () => context.go(Routes.lesson(widget.lessonId)),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              attempt.passed
                                  ? Icons.emoji_events_rounded
                                  : Icons.restart_alt_rounded,
                              size: 40,
                              color: tint,
                            ),
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.3, 0.3),
                              duration: 700.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 300.ms),
                        const SizedBox(height: 20),
                        Text(
                          attempt.passed ? _praise(attempt) : 'Not quite yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ).animate().fadeIn(delay: 150.ms).moveY(begin: 10, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          attempt.passed
                              ? '${attempt.lessonTitle} is complete.'
                              : 'You need ${AppConstants.passThresholdPercent}% to pass '
                                  '— give it another go.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ).animate().fadeIn(delay: 220.ms),
                        const SizedBox(height: 28),
                        Center(
                          child: ProgressRing(
                            value: attempt.percent / 100,
                            size: 150,
                            strokeWidth: 15,
                            caption: '${attempt.score} of ${attempt.total}',
                            color: tint,
                          ),
                        ).animate().fadeIn(delay: 300.ms).scale(
                              begin: const Offset(0.85, 0.85),
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                icon: Icons.check_rounded,
                                value: '${attempt.score}',
                                label: 'Correct',
                                color: colors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: Icons.close_rounded,
                                value: '${attempt.total - attempt.score}',
                                label: 'Missed',
                                color: colors.wrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: Icons.percent_rounded,
                                value: '${attempt.percent}',
                                label: 'Score',
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 380.ms).moveY(begin: 14, end: 0),
                        if (summary != null) ...[
                          const SizedBox(height: 22),
                          _LiveProgressCard(
                            completed: summary.completedLessons,
                            total: summary.totalLessons,
                            average: summary.averageScorePercent,
                            fraction: summary.completionFraction,
                          ).animate().fadeIn(delay: 450.ms),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                  child: Column(
                    children: [
                      if (attempt.passed && nextLesson != null)
                        SoundFilledButton(
                          onPressed: () =>
                              context.pushReplacement(Routes.lesson(nextLesson.id)),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          child: Text('Next: ${nextLesson.title}'),
                        )
                      else
                        SoundFilledButton(
                          onPressed: () =>
                              context.pushReplacement(Routes.quiz(widget.lessonId)),
                          icon: const Icon(Icons.replay_rounded),
                          child: Text(attempt.passed ? 'Retake quiz' : 'Try again'),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SoundOutlinedButton(
                              onPressed: () => context.go(Routes.lesson(widget.lessonId)),
                              child: const Text('Back to lesson'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SoundOutlinedButton(
                              onPressed: () => context.go(Routes.progress),
                              child: const Text('My progress'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _praise(QuizAttempt attempt) {
    if (attempt.score == attempt.total) return 'Perfect score!';
    if (attempt.percent >= 90) return 'Brilliant!';
    if (attempt.percent >= 80) return 'Nicely done!';
    return 'You passed!';
  }
}

/// Proof that the numbers are live: this card reads the same derived summary the
/// Dashboard and Progress screens use, already including the attempt that was
/// submitted a moment ago.
class _LiveProgressCard extends StatelessWidget {
  const _LiveProgressCard({
    required this.completed,
    required this.total,
    required this.average,
    required this.fraction,
  });

  final int completed;
  final int total;
  final int average;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Updated just now', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                '$completed/$total lessons',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: fraction),
          const SizedBox(height: 10),
          Text(
            'Course $average% average across your best attempts.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
