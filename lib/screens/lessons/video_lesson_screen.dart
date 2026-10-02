import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants.dart';
import '../../data/progress_repository.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/video_frame.dart';
import 'watch_action.dart';

/// Plays the lesson video and drives the first half of the lesson state machine.
///
/// - the first frame of playback marks the lesson **in progress**
/// - crossing [AppConstants.videoCompleteFraction] marks the video **watched**,
///   which is what unlocks the quiz
class VideoLessonScreen extends ConsumerStatefulWidget {
  const VideoLessonScreen({
    super.key,
    required this.lessonId,
    this.rewatch = false,
  });

  final String lessonId;

  /// Start from the beginning and clear the saved position, rather than
  /// resuming where the learner left off.
  final bool rewatch;

  @override
  ConsumerState<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends ConsumerState<VideoLessonScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  String? _error;
  bool _initialising = true;

  bool _markedStarted = false;
  bool _markedWatched = false;
  double _watchedFraction = 0;
  Timer? _positionSaveTimer;

  @override
  void initState() {
    super.initState();
    // Wait for the lesson document before we know what to load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final lesson = await ref.read(lessonProvider(widget.lessonId).future);
    if (!mounted) return;
    if (lesson == null) {
      setState(() {
        _error = 'This lesson no longer exists.';
        _initialising = false;
      });
      return;
    }
    if (lesson.videoUrl.isEmpty) {
      setState(() {
        _error = 'This lesson has no video attached yet.';
        _initialising = false;
      });
      return;
    }
    await _load(lesson);
  }

  Future<void> _load(Lesson lesson) async {
    // Held separately so a failure part-way through can still release it.
    VideoPlayerController? created;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(lesson.videoUrl),
      );
      created = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Resume, or restart for an explicit rewatch. Seek before Chewie takes
      // over so playback never starts at the wrong frame.
      final start = resumePointFor(
        rewatch: widget.rewatch,
        progress: ref.read(lessonProgressProvider(widget.lessonId)),
        duration: controller.value.duration,
      );
      if (start > Duration.zero) {
        await controller.seekTo(start);
        if (!mounted) {
          await controller.dispose();
          return;
        }
      }
      if (widget.rewatch) {
        // Drop the stale checkpoint so a later resume can't jump back.
        unawaited(_resetSavedPosition());
      }
      setState(
        () => _watchedFraction = controller.value.duration > Duration.zero
            ? start.inMilliseconds / controller.value.duration.inMilliseconds
            : 0,
      );

      // Browsers reject unmuted autoplay without a prior user gesture
      // (NotAllowedError), which leaves the player stalled. Muted autoplay is
      // permitted, and these are sign-language clips, so the visual carries the
      // lesson; the learner can unmute from Chewie's own control bar.
      if (kIsWeb) {
        await controller.setVolume(0);
        if (!mounted) {
          await controller.dispose();
          return;
        }
      }

      controller.addListener(_onTick);
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1, 1.25, 1.5],
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          bufferedColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.3),
        ),
      );
      setState(() {
        _controller = controller;
        _chewie = chewie;
        _initialising = false;
      });
      // Only needed once a controller exists, and cached here so the final
      // save in dispose() never touches `ref`.
      _cacheSaveHandles();
      // Persist the scrub position every few seconds rather than every frame.
      _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _savePosition(),
      );
    } catch (e) {
      // The controller never reached state, so dispose() would not free it:
      // release the platform resources here instead of leaking them.
      if (_controller == null) {
        await created?.dispose();
      }
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the video.\n\n$e';
        _initialising = false;
      });
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration.inMilliseconds <= 0) return;

    final fraction = position.inMilliseconds / duration.inMilliseconds;
    if ((fraction - _watchedFraction).abs() > 0.004) {
      setState(() => _watchedFraction = fraction.clamp(0, 1));
    }

    if (!_markedStarted && controller.value.isPlaying) {
      _markedStarted = true;
      _markStarted();
    }

    final reachedEnd =
        fraction >= AppConstants.videoCompleteFraction ||
        _isFinished(controller);
    if (!_markedWatched && reachedEnd) {
      _markedWatched = true;
      _markWatched();
    }
  }

  bool _isFinished(VideoPlayerController c) =>
      !c.value.isPlaying &&
      c.value.position >= c.value.duration &&
      c.value.duration > Duration.zero;

  Future<void> _markStarted() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .markVideoStarted(uid, widget.lessonId);
  }

  Future<void> _markWatched() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .markVideoCompleted(uid, widget.lessonId);
    if (!mounted) return;
    ref.playSfx(Sfx.complete);
    setState(() {});
  }

  Future<void> _resetSavedPosition() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .saveVideoPosition(uid, widget.lessonId, 0);
  }

  /// Cached so the final save in [dispose] does not touch `ref`, which is
  /// unsafe once the element is being unmounted.
  ProgressRepository? _repo;
  String? _uid;

  void _cacheSaveHandles() {
    _repo = ref.read(progressRepositoryProvider);
    _uid = ref.read(currentUidProvider);
  }

  void _savePosition() {
    final uid = _uid;
    final repo = _repo;
    final controller = _controller;
    if (uid == null ||
        repo == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    repo.saveVideoPosition(
      uid,
      widget.lessonId,
      controller.value.position.inSeconds,
    );
  }

  @override
  void dispose() {
    // The periodic timer only checkpoints every 5s, so save one last time or
    // the final seconds of watching are lost on the way out.
    _savePosition();
    _positionSaveTimer?.cancel();
    _controller?.removeListener(_onTick);
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonProvider(widget.lessonId)).value;
    final progress = ref.watch(lessonProgressProvider(widget.lessonId));
    final questions = ref.watch(questionsProvider(widget.lessonId)).value;
    final scheme = Theme.of(context).colorScheme;
    final questionCount = questions?.length ?? 0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back to lesson',
        ),
        title: Text(
          lesson?.title ?? 'Lesson',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The agenda only becomes a side rail once there is room for it
            // beside the video; below that it rides along under the player.
            final wide = constraints.maxWidth >= Breakpoints.medium;

            final agenda = _AgendaPanel(
              lesson: lesson,
              progress: progress,
              questionCount: questionCount,
              watchedFraction: _watchedFraction,
            );

            final player = Column(
              children: [
                _playerFrame(constraints.maxHeight),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _watchProgress(progress),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          child: progress.videoCompleted
                              ? _QuizUnlockedCard(
                                  key: const ValueKey('unlocked'),
                                  questionCount: questionCount,
                                )
                              : _KeepWatchingCard(
                                  key: const ValueKey('watching'),
                                ),
                        ),
                        if (!wide) ...[const SizedBox(height: 20), agenda],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return ContentWidth(
              maxWidth: wide ? 1180 : 900,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: player),
                        if (wide) ...[
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 300,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(0, 0, 20, 20),
                              child: agenda,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _NextBar(
                    lessonId: widget.lessonId,
                    unlocked: progress.videoCompleted,
                    questionCount: questionCount,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Gives the player half the available height, within sane bounds, so the
  /// agenda and the Next bar always keep their share of the screen.
  Widget _playerFrame(double availableHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: VideoFrame(
        height: (availableHeight * 0.5).clamp(200.0, 420.0),
        aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
        child: _buildPlayer(),
      ),
    );
  }

  Widget _watchProgress(LessonProgress progress) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final value = progress.videoCompleted ? 1.0 : _watchedFraction;
    final tint = progress.videoCompleted ? colors.success : scheme.primary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.videoCompleted ? 'Video watched' : 'Watch progress',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ProgressBar(
                value: value,
                color: tint,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '${(value * 100).round()}%',
          style: theme.textTheme.titleMedium?.copyWith(color: tint),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white70,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    if (_initialising || _chewie == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 3),
      );
    }
    return Chewie(controller: _chewie!);
  }
}

class _KeepWatchingCard extends StatelessWidget {
  const _KeepWatchingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Watch to the end to unlock the practice quiz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The lesson's running order, derived from the lesson itself rather than
/// authored: what there is to do, and how far through it you are. Sits in the
/// right-hand rail on a wide viewport and under the player on a narrow one.
class _AgendaPanel extends StatelessWidget {
  const _AgendaPanel({
    required this.lesson,
    required this.progress,
    required this.questionCount,
    required this.watchedFraction,
  });

  final Lesson? lesson;
  final LessonProgress progress;
  final int questionCount;
  final double watchedFraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasQuiz = questionCount > 0;
    final watched = progress.videoCompleted;
    final percent = ((watched ? 1.0 : watchedFraction) * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agenda', style: theme.textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            'Where you are in this lesson.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _AgendaStep(
            number: 1,
            title: 'Watch the video',
            subtitle: lesson?.durationLabel ?? '—',
            trailing: '$percent%',
            done: watched,
            active: !watched,
          ),
          _AgendaStep(
            number: 2,
            title: hasQuiz ? 'Take the quiz' : 'No quiz yet',
            subtitle: hasQuiz
                ? '$questionCount question${questionCount == 1 ? '' : 's'}'
                : 'Nothing to answer for this lesson',
            done: progress.quizPassed,
            active: watched && hasQuiz && !progress.quizPassed,
            locked: hasQuiz && !watched,
          ),
          _AgendaStep(
            number: 3,
            title: 'Pass at ${AppConstants.passThresholdPercent}%',
            subtitle: progress.attemptCount == 0
                ? 'Not attempted yet'
                : 'Best ${progress.bestScorePercent}% · '
                      '${progress.attemptCount} '
                      'attempt${progress.attemptCount == 1 ? '' : 's'}',
            done: progress.quizPassed,
            active: false,
            isLast: true,
          ),
          if (lesson != null) ...[
            const SizedBox(height: 6),
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              '${lesson!.category} · ${lesson!.difficulty}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaStep extends StatelessWidget {
  const _AgendaStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    this.locked = false,
    this.trailing,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool locked;
  final String? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    final markerColor = done
        ? colors.success
        : active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? colors.success : Colors.transparent,
              border: Border.all(color: markerColor, width: 1.6),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : locked
                ? Icon(Icons.lock_outline_rounded, size: 12, color: markerColor)
                : Text(
                    '$number',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: markerColor,
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? scheme.onSurface : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.labelMedium?.copyWith(color: markerColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// The persistent bottom bar carrying the forward action.
///
/// It stays disabled until the video is watched, so it can't be used to skip
/// past the rule the rest of the screen is built on.
class _NextBar extends StatelessWidget {
  const _NextBar({
    required this.lessonId,
    required this.unlocked,
    required this.questionCount,
  });

  final String lessonId;
  final bool unlocked;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasQuiz = questionCount > 0;
    final enabled = unlocked && hasQuiz;

    final hint = !hasQuiz
        ? 'This lesson has no quiz yet.'
        : enabled
        ? 'Quiz unlocked — $questionCount '
              'question${questionCount == 1 ? '' : 's'}.'
        : 'Watch to the end to unlock the quiz.';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SoundFilledButton(
            onPressed: enabled
                ? () => context.push(Routes.quiz(lessonId))
                : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            child: const Text('Next: Quiz'),
          ),
        ],
      ),
    );
  }
}

class _QuizUnlockedCard extends StatelessWidget {
  const _QuizUnlockedCard({super.key, required this.questionCount});

  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open_rounded,
                color: colors.success,
              ).animate().scale(
                begin: const Offset(0.4, 0.4),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionCount == 0
                      ? 'Nice work — this lesson has no quiz yet.'
                      : 'Quiz unlocked: $questionCount '
                            'question${questionCount == 1 ? '' : 's'} to go.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          // No button here on purpose: the Next bar at the bottom of the screen
          // is the single forward action, so the two don't compete.
        ],
      ),
    );
  }
}
