import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';
export 'rewatch_flag.dart';

/// What the primary "watch" button on the lesson detail screen should do.
///
/// Kept as a pure value so the rules are unit-testable without standing up the
/// video plugin, which cannot initialise in a widget test.
@immutable
class WatchAction {
  const WatchAction({
    required this.label,
    required this.enabled,
    required this.icon,
    required this.rewatch,
  });

  final String label;
  final bool enabled;
  final IconData icon;

  /// Whether activating this should restart the video from the beginning
  /// rather than pick up where the learner left off.
  final bool rewatch;
}

/// Resolves the button state for [lesson] at [progress].
///
/// [allowRewatch] gates re-entry once the video is finished.
WatchAction watchActionFor({
  required Lesson lesson,
  required LessonProgress progress,
  required bool allowRewatch,
}) {
  if (lesson.videoUrl.isEmpty) {
    return const WatchAction(
      label: 'No video yet',
      enabled: false,
      icon: Icons.videocam_off_rounded,
      rewatch: false,
    );
  }

  if (progress.videoCompleted) {
    return WatchAction(
      label: allowRewatch ? 'Rewatch video' : 'Video completed',
      enabled: allowRewatch,
      icon: allowRewatch ? Icons.replay_rounded : Icons.check_circle_rounded,
      rewatch: allowRewatch,
    );
  }

  return WatchAction(
    label: progress.status == LessonStatus.notStarted
        ? 'Start lesson'
        : 'Continue watching',
    enabled: true,
    icon: Icons.play_arrow_rounded,
    rewatch: false,
  );
}

/// Where playback should begin for this entry into the video screen.
///
/// Resuming is deliberately conservative: a saved position that sits at (or
/// within a whisker of) the end would otherwise drop the learner onto a frozen
/// last frame, so those restart instead.
Duration resumePointFor({
  required bool rewatch,
  required LessonProgress progress,
  required Duration duration,
}) {
  // An explicit rewatch always starts over, whatever was saved.
  if (rewatch) return Duration.zero;

  // A finished video has nothing to resume into.
  if (progress.videoCompleted) return Duration.zero;

  final saved = Duration(seconds: progress.lastPositionSeconds);
  if (saved <= Duration.zero) return Duration.zero;

  // Unknown duration: trust the saved position rather than guess.
  if (duration <= Duration.zero) return saved;

  // Past the end, or close enough that resuming is pointless.
  if (saved >= duration - const Duration(seconds: 1)) return Duration.zero;

  return saved;
}
