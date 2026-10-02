import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';
import 'watch_action.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonProvider(lessonId));
    final progress = ref.watch(lessonProgressProvider(lessonId));
    final questions = ref.watch(questionsProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: lesson.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(lessonProvider(lessonId)),
        ),
        data: (l) => l == null
            ? const EmptyState(
                icon: Icons.help_outline_rounded,
                title: 'Lesson not found',
                message: 'It may have been removed by an admin.',
              )
            : _Body(
                lesson: l,
                progress: progress,
                questionCount: questions.value?.length,
              ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.lesson,
    required this.progress,
    required this.questionCount,
  });

  final Lesson lesson;
  final LessonProgress progress;
  final int? questionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final tint = AppPalette.categoryTint(lesson.category, scheme);
    final hasQuiz = (questionCount ?? 0) > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: LessonCard.heroTag(lesson.id),
                    child: LessonArtwork(
                      lesson: lesson,
                      size: 96,
                      tint: tint,
                      borderRadius: 24,
                      showPlayIcon: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lesson.title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        StatusPill(status: progress.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: lesson.durationLabel,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: lesson.difficulty,
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.quiz_outlined,
                    label: hasQuiz
                        ? '$questionCount question${questionCount == 1 ? '' : 's'}'
                        : 'No quiz',
                  ),
                ],
              ).animate().fadeIn(delay: 80.ms),
              if (lesson.isPlaceholderVideo) ...[
                const SizedBox(height: 18),
                const _PlaceholderNotice(),
              ],
              const SizedBox(height: 24),
              Text('About this lesson', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                lesson.description.isEmpty
                    ? 'No description was added for this lesson.'
                    : lesson.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 26),
              if (progress.bestScorePercent > 0 || progress.attemptCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      ProgressRing(
                        value: progress.bestScorePercent / 100,
                        size: 66,
                        strokeWidth: 8,
                        color: progress.quizPassed ? colors.success : colors.streak,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your best score',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${progress.attemptCount} '
                              'attempt${progress.attemptCount == 1 ? '' : 's'} · '
                              '${progress.quizPassed ? 'passed' : 'not passed yet'}'
                              ' (${AppConstants.passThresholdPercent}% to pass)',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
              ],
              _Steps(progress: progress, hasQuiz: hasQuiz),
              const SizedBox(height: 26),
              Builder(builder: (context) {
                final action = watchActionFor(
                  lesson: lesson,
                  progress: progress,
                  allowRewatch: kAllowRewatch,
                );
                return SoundFilledButton(
                  onPressed: action.enabled
                      ? () => context.push(
                            Routes.watch(lesson.id, rewatch: action.rewatch),
                          )
                      : null,
                  icon: Icon(action.icon),
                  child: Text(action.label),
                );
              }),
              if (lesson.videoUrl.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This lesson has no video attached yet.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              SoundOutlinedButton(
                onPressed: !hasQuiz || !progress.quizUnlocked
                    ? null
                    : () => context.push(Routes.quiz(lesson.id)),
                icon: Icon(progress.quizUnlocked
                    ? Icons.quiz_rounded
                    : Icons.lock_outline_rounded),
                child: Text(
                  !hasQuiz
                      ? 'Quiz coming soon'
                      : progress.quizUnlocked
                          ? (progress.quizPassed ? 'Retake quiz' : 'Take the quiz')
                          : 'Finish the video to unlock',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
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
  }
}

/// Visual state machine: watch -> quiz -> done.
class _Steps extends StatelessWidget {
  const _Steps({required this.progress, required this.hasQuiz});

  final LessonProgress progress;
  final bool hasQuiz;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        'Watch the video',
        progress.videoCompleted
            ? _StepState.done
            : progress.isInProgress
                ? _StepState.active
                : _StepState.todo,
      ),
      (
        'Pass the quiz (${AppConstants.passThresholdPercent}%)',
        progress.quizPassed
            ? _StepState.done
            : progress.videoCompleted
                ? _StepState.active
                : _StepState.todo,
      ),
      (
        'Lesson complete',
        progress.isCompleted ? _StepState.done : _StepState.todo,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How to finish it', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            label: steps[i].$1,
            state: steps[i].$2,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

enum _StepState { todo, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state, required this.isLast});

  final String label;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final (color, icon) = switch (state) {
      _StepState.done => (colors.success, Icons.check_rounded),
      _StepState.active => (scheme.primary, Icons.play_arrow_rounded),
      _StepState.todo => (scheme.onSurfaceVariant, Icons.circle_outlined),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: state == _StepState.todo
                    ? Colors.transparent
                    : color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.6), width: 1.6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        state == _StepState.active ? FontWeight.w800 : FontWeight.w600,
                    color: state == _StepState.todo
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderNotice extends StatelessWidget {
  const _PlaceholderNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sample lesson: the clip is a placeholder standing in for real '
              'sign-language footage. The quiz content is real.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
