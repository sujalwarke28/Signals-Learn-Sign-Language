import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sound/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/question.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';

/// One question at a time. You must pick an option before **Check** enables,
/// and you can't go back and change an answer once it's checked — which is what
/// makes the score meaningful.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  int? _selected;
  bool _checked = false;
  bool _submitting = false;
  final Map<String, int> _answers = {};
  int _correctSoFar = 0;

  Future<void> _check(Question question) async {
    if (_selected == null || _checked) return;
    final correct = question.isCorrect(_selected!);
    setState(() {
      _checked = true;
      _answers[question.id] = _selected!;
      if (correct) _correctSoFar++;
    });
    ref.playSfx(correct ? Sfx.correct : Sfx.incorrect);
  }

  Future<void> _next(List<Question> questions, Lesson lesson) async {
    if (!_checked) return;
    if (_index < questions.length - 1) {
      ref.playSfx(Sfx.tap);
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
      });
      return;
    }
    await _submit(questions, lesson);
  }

  Future<void> _submit(List<Question> questions, Lesson lesson) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _submitting = true);
    try {
      final attempt = await ref.read(progressRepositoryProvider).submitAttempt(
            uid: uid,
            lesson: lesson,
            questions: questions,
            answers: _answers,
          );
      if (!mounted) return;
      // Replace so Back from the results screen lands on the lesson, not on a
      // finished quiz the learner could resubmit.
      context.pushReplacement(Routes.results(lesson.id), extra: attempt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your result: $e')),
      );
    }
  }

  Future<bool> _confirmQuit() async {
    if (_answers.isEmpty) return true;
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the quiz?'),
        content: const Text(
          'Your answers so far won\'t be saved and no score will be recorded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return quit ?? false;
  }

  /// Asks, then leaves. Uses `State.context` so the `mounted` guard after the
  /// dialog's await is the one the analyzer expects.
  Future<void> _maybeLeave() async {
    final leave = await _confirmQuit();
    if (!leave || !mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonProvider(widget.lessonId));
    final questions = ref.watch(questionsProvider(widget.lessonId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _maybeLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: switch ((lesson, questions)) {
            (AsyncError(:final error), _) => ErrorView(error: error),
            (_, AsyncError(:final error)) => ErrorView(error: error),
            (AsyncData(value: final l), AsyncData(value: final qs)) =>
              l == null || qs.isEmpty
                  ? EmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'No quiz yet',
                      message: l == null
                          ? 'This lesson no longer exists.'
                          : 'An admin hasn\'t added questions for this lesson.',
                      action: OutlinedButton(
                        onPressed: () => context.pop(),
                        style:
                            OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                        child: const Text('Go back'),
                      ),
                    )
                  : _buildQuiz(l, qs),
            _ => const LoadingView(message: 'Loading questions'),
          },
        ),
      ),
    );
  }

  Widget _buildQuiz(Lesson lesson, List<Question> questions) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final question = questions[_index];
    final isLast = _index == questions.length - 1;

    return ContentWidth(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Leave quiz',
                  onPressed: _maybeLeave,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${_index + 1} of ${questions.length}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      ProgressBar(
                        value: (_index + (_checked ? 1 : 0)) / questions.length,
                        height: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _ScorePill(correct: _correctSoFar, answered: _answers.length),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                key: ValueKey(question.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lesson.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppPalette.categoryTint(lesson.category, scheme),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(question.prompt, style: theme.textTheme.headlineSmall),
                  if (question.hasImage) ...[
                    const SizedBox(height: 18),
                    _QuestionImage(url: question.imageUrl!),
                  ],
                  const SizedBox(height: 24),
                  for (var i = 0; i < question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionTile(
                        label: question.options[i],
                        letter: String.fromCharCode(65 + i),
                        selected: _selected == i,
                        checked: _checked,
                        isCorrect: question.correctIndex == i,
                        onTap: _checked
                            ? null
                            : () {
                                ref.playSfx(Sfx.tap);
                                setState(() => _selected = i);
                              },
                      ),
                    ),
                  if (_checked) ...[
                    const SizedBox(height: 4),
                    _Feedback(
                      correct: question.isCorrect(_selected ?? -1),
                      question: question,
                    ),
                  ],
                ],
              )
                  .animate(key: ValueKey(question.id))
                  .fadeIn(duration: 260.ms)
                  .moveX(begin: 24, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              children: [
                if (!_checked && _selected == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Pick an answer to continue',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                SoundFilledButton(
                  sfx: null,
                  onPressed: _submitting
                      ? null
                      : _checked
                          ? () => _next(questions, lesson)
                          : _selected == null
                              ? null
                              : () => _check(question),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(
                          !_checked
                              ? 'Check answer'
                              : isLast
                                  ? 'See results'
                                  : 'Next question',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The optional picture that goes with a question prompt.
///
/// Height-capped and `BoxFit.contain` so a portrait photo can't push the options
/// off the screen, and a failed load degrades to a caption rather than a red
/// error box — the question text still stands on its own.
class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final total = progress.expectedTotalBytes;
            return Container(
              height: 170,
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                value: total == null
                    ? null
                    : progress.cumulativeBytesLoaded / total,
              ),
            );
          },
          errorBuilder: (context, _, _) => Container(
            height: 110,
            color: scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant),
                const SizedBox(height: 6),
                Text(
                  'Image didn\'t load',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.correct, required this.answered});

  final int correct;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: answered == 0
            ? scheme.surfaceContainerHighest
            : colors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: answered == 0 ? scheme.onSurfaceVariant : colors.success,
          ),
          const SizedBox(width: 5),
          Text(
            '$correct',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: answered == 0 ? scheme.onSurfaceVariant : colors.success,
                ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.letter,
    required this.selected,
    required this.checked,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final String letter;
  final bool selected;
  final bool checked;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    // Once checked: the right answer always turns green; a wrong pick turns red.
    late final Color border;
    late final Color background;
    late final Color foreground;
    IconData? trailing;

    if (checked && isCorrect) {
      border = colors.success;
      background = colors.success.withValues(alpha: 0.13);
      foreground = scheme.onSurface;
      trailing = Icons.check_circle_rounded;
    } else if (checked && selected) {
      border = colors.wrong;
      background = colors.wrong.withValues(alpha: 0.13);
      foreground = scheme.onSurface;
      trailing = Icons.cancel_rounded;
    } else if (selected) {
      border = scheme.primary;
      background = scheme.primary.withValues(alpha: 0.10);
      foreground = scheme.onSurface;
    } else {
      border = scheme.outlineVariant.withValues(alpha: 0.6);
      background = scheme.surfaceContainerLow;
      foreground = scheme.onSurface;
    }

    final tile = Pressable(
      onTap: onTap,
      sfx: null,
      borderRadius: 20,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: selected || checked ? 2 : 1.3),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected || (checked && isCorrect)
                    ? border.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected || (checked && isCorrect)
                      ? border
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Icon(trailing, color: border, size: 22),
            ],
          ],
        ),
      ),
    );

    // The bounce only fires on the option that was just revealed as correct.
    if (checked && isCorrect) {
      return tile.animate().scale(
            begin: const Offset(1, 1),
            end: const Offset(1.035, 1.035),
            duration: 160.ms,
            curve: Curves.easeOut,
          ).then().scale(
            begin: const Offset(1, 1),
            end: const Offset(1 / 1.035, 1 / 1.035),
            duration: 260.ms,
            curve: Curves.elasticOut,
          );
    }
    if (checked && selected && !isCorrect) {
      return tile.animate().shake(hz: 4, offset: const Offset(4, 0), duration: 320.ms);
    }
    return tile;
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.question});

  final bool correct;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tint = correct ? colors.success : colors.wrong;
    final explanation = question.explanation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.sentiment_very_satisfied_rounded : Icons.lightbulb_rounded,
                color: tint,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct!' : 'The answer is "${question.correctOption}"',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: tint),
              ),
            ],
          ),
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(explanation, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 240.ms)
        .moveY(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}
