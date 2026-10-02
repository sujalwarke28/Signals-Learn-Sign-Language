import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/forum_post.dart';
import '../../models/lesson.dart';
import '../../providers/forum_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';
import '../auth/sign_out_action.dart';
import 'dashboard_header.dart';
import 'library_snapshot.dart';

/// The admin's home — a console, not a course.
///
/// An admin never takes the lessons, so a screen built around streaks, badges
/// and "keep going" is addressed to the wrong person. This answers the only
/// questions the job actually raises: what is in the library, where are the
/// holes, and what needs fixing before a learner trips over it.
///
/// Visually it is the learner dashboard's opposite number on purpose — same
/// palette, same type, tighter corners, flat surfaces instead of gradients,
/// tabular figures, and a tertiary accent rather than the warm violet. It
/// should feel like instrumentation while still obviously belonging to Signals.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({required this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider).value ?? const <Lesson>[];
    final posts = ref.watch(forumPostsProvider).value ?? const <ForumPost>[];
    final snap = LibrarySnapshot.from(lessons: lessons, posts: posts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConsoleHeader(user: user),
              const SizedBox(height: 22),
              _PublishCard(lessonCount: snap.totalLessons),
              const SizedBox(height: 18),
              _MetricRow(snap: snap),
              const SizedBox(height: 26),
              _NeedsAttention(snap: snap),
              const SizedBox(height: 26),
              _Coverage(snap: snap),
              if (snap.recentLessons.isNotEmpty) ...[
                const SizedBox(height: 26),
                _RecentlyPublished(lessons: snap.recentLessons),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens cold where the learner's header opens warm: a role label and a rule,
/// not a greeting.
class _ConsoleHeader extends ConsumerWidget {
  const _ConsoleHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.tertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Library console',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ADMIN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Signed in as ${user?.displayName ?? user?.email ?? 'admin'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AvatarButton(user: user, size: 40),
        IconButton(
          onPressed: () => confirmSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded),
          color: scheme.onSurfaceVariant,
          tooltip: 'Sign out',
          visualDensity: VisualDensity.compact,
        ),
      ],
    ).animate().fadeIn(duration: 320.ms).moveY(begin: -8, end: 0);
  }
}

/// The one thing an admin is here to do.
class _PublishCard extends StatelessWidget {
  const _PublishCard({required this.lessonCount});

  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        // 16, against the learner side's 24–30. Tighter corners read as tooling.
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_call_rounded, color: scheme.tertiary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Publish a lesson',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lessonCount == 0
                ? 'The library is empty. Everything a learner sees starts here.'
                : 'Upload the clip, write its quiz, and it is live for every '
                      'learner immediately.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SoundFilledButton(
            onPressed: () => context.push(Routes.addLesson),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            child: const Text('New lesson'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 380.ms).moveY(begin: 12, end: 0);
  }
}

/// Three figures, set as data rather than as scoreboard tiles.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.snap});

  final LibrarySnapshot snap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    final cells = [
      _Metric(value: '${snap.totalLessons}', label: 'Lessons'),
      _Metric(value: '${snap.categoryCount}', label: 'Categories'),
      _Metric(
        value:
            '${snap.placeholderLessons.length + snap.unansweredPosts.length}',
        label: 'Need attention',
        color: snap.allClear ? scheme.onSurface : colors.streak,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            Expanded(child: cells[i]),
            if (i != cells.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    ).animate(delay: 70.ms).fadeIn(duration: 380.ms).moveY(begin: 12, end: 0);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              color: color ?? scheme.onSurface,
              // Tabular figures so the three cells stay optically aligned as
              // the numbers change underneath them.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The queue. Placeholder footage first, because that is what a learner would
/// notice and an admin would not.
class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.snap});

  final LibrarySnapshot snap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    if (snap.allClear) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.success.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: colors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing needs attention. Every lesson has real footage and '
                'every question has an answer.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Needs attention',
          subtitle: 'Things a learner would notice before you do',
        ),
        const SizedBox(height: 12),
        for (final lesson in snap.placeholderLessons.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AttentionRow(
              icon: Icons.movie_filter_outlined,
              tint: colors.streak,
              title: lesson.title,
              detail: 'Still using stand-in footage',
              onTap: () => context.push(Routes.lesson(lesson.id)),
            ),
          ),
        for (final post in snap.unansweredPosts.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AttentionRow(
              icon: Icons.forum_outlined,
              tint: scheme.primary,
              title: post.title,
              detail: 'No reply yet — asked by ${post.authorName}',
              onTap: () => context.go(Routes.post(post.id)),
            ),
          ),
      ],
    ).animate(delay: 120.ms).fadeIn(duration: 380.ms).moveY(begin: 12, end: 0);
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      borderRadius: 14,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the library is thin. Sorted so the gaps are at the top.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.snap});

  final LibrarySnapshot snap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (snap.coverage.isEmpty) {
      return const SizedBox.shrink();
    }

    final busiest = snap.coverage
        .map((c) => c.lessonCount)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Coverage',
          subtitle: snap.thinCategories.isEmpty
              ? 'Every category has enough to be worth opening'
              : '${snap.thinCategories.length} '
                    '${snap.thinCategories.length == 1 ? 'category is' : 'categories are'} '
                    'thin — under three lessons',
        ),
        const SizedBox(height: 14),
        for (final c in snap.coverage)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.category,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.isThin)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'thin',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.of(context).streak,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      '${c.lessonCount}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ProgressBar(
                  value: c.lessonCount / busiest,
                  color: AppPalette.categoryTint(c.category, scheme),
                  height: 6,
                ),
              ],
            ),
          ),
      ],
    ).animate(delay: 170.ms).fadeIn(duration: 380.ms).moveY(begin: 12, end: 0);
  }
}

class _RecentlyPublished extends StatelessWidget {
  const _RecentlyPublished({required this.lessons});

  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Recently published'),
        const SizedBox(height: 12),
        for (final lesson in lessons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              borderRadius: 14,
              onTap: () => context.push(Routes.lesson(lesson.id)),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    LessonArtwork(
                      lesson: lesson,
                      size: 42,
                      borderRadius: 10,
                      tint: AppPalette.categoryTint(lesson.category, scheme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lesson.category} · ${lesson.durationLabel}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ).animate(delay: 210.ms).fadeIn(duration: 380.ms).moveY(begin: 12, end: 0);
  }
}
