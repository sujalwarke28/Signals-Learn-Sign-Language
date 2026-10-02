import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import 'common.dart';
import 'pressable.dart';
import 'progress_ring.dart';

/// The library's lesson card. Its artwork is wrapped in a [Hero] keyed on the
/// lesson id so tapping through to the detail screen flies the thumbnail across
/// rather than cutting.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.onTap,
    this.index = 0,
  });

  final Lesson lesson;
  final LessonProgress progress;
  final VoidCallback onTap;
  final int index;

  static String heroTag(String lessonId) => 'lesson-art-$lessonId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(lesson.category, scheme);
    final colors = AppColors.of(context);
    final done = progress.isCompleted;

    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${lesson.title}, ${lesson.category}, ${progress.status.label}',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          // A wash of the category colour rather than a flat card: the library
          // then reads as grouped by subject at a glance, before any label is.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint.withValues(alpha: done ? 0.16 : 0.09),
              tint.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: tint.withValues(alpha: done ? 0.38 : 0.18),
            width: done ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: done ? 0.16 : 0.08),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: heroTag(lesson.id),
                  child: LessonArtwork(lesson: lesson, size: 76, tint: tint),
                ),
                if (done)
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: scheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          lesson.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      StatusPill(status: progress.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.2,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.durationLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lesson.difficulty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (progress.bestScorePercent > 0) ...[
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: ProgressBar(
                            value: progress.bestScorePercent / 100,
                            height: 6,
                            color: tint,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '${progress.bestScorePercent}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonArtwork extends StatelessWidget {
  const LessonArtwork({
    super.key,
    required this.lesson,
    this.size = 74,
    this.tint,
    this.borderRadius = 18,
    this.showPlayIcon = false,
  });

  final Lesson lesson;
  final double size;
  final Color? tint;
  final double borderRadius;
  final bool showPlayIcon;

  static const _glyphs = {
    'Alphabet': Icons.abc_rounded,
    'Numbers': Icons.pin_rounded,
    'Common Phrases': Icons.chat_bubble_rounded,
    'Greetings': Icons.waving_hand_rounded,
    'Family': Icons.family_restroom_rounded,
    'Colors': Icons.palette_rounded,
  };

  /// The glyph for a category, so the lesson path can draw the same one on
  /// its nodes as the library draws on its cards.
  static IconData glyphFor(String category) =>
      _glyphs[category] ?? Icons.sign_language_rounded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? AppPalette.categoryTint(lesson.category, scheme);
    final glyph = glyphFor(lesson.category);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty)
              Image.network(
                lesson.thumbnailUrl!,
                fit: BoxFit.cover,
                // A missing poster frame is normal (Cloudinary generates them
                // lazily), so fall back to the gradient rather than an error box.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
              ),
            Center(
              child: Icon(
                showPlayIcon ? Icons.play_arrow_rounded : glyph,
                color: Colors.white.withValues(alpha: 0.92),
                size: size * (showPlayIcon ? 0.42 : 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
