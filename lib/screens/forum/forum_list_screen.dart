import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/sound/sound_service.dart';
import '../../models/forum_post.dart';
import '../../providers/forum_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class ForumListScreen extends ConsumerWidget {
  const ForumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(forumPostsProvider);
    final filtered = ref.watch(filteredForumPostsProvider);
    final topic = ref.watch(forumTopicFilterProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.playSfx(Sfx.tap);
          context.push(Routes.newPost);
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New post'),
      ),
      body: SafeArea(
        bottom: false,
        child: posts.when(
          loading: () => const LoadingView(message: 'Loading the community'),
          error: (e, _) =>
              ErrorView(error: e, onRetry: () => ref.invalidate(forumPostsProvider)),
          data: (all) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          all.isEmpty
                              ? 'Be the first to post'
                              : '${all.length} post${all.length == 1 ? '' : 's'} · '
                                  'updates live',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: topic == null,
                                showCheckmark: false,
                                onSelected: (_) {
                                  ref.playSfx(Sfx.tap);
                                  ref
                                      .read(forumTopicFilterProvider.notifier)
                                      .select(null);
                                },
                              ),
                              for (final t in AppConstants.forumTopics) ...[
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text(t),
                                  selected: topic == t,
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    ref.playSfx(Sfx.tap);
                                    ref
                                        .read(forumTopicFilterProvider.notifier)
                                        .select(topic == t ? null : t);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.forum_outlined,
                    title: all.isEmpty ? 'Quiet in here' : 'Nothing in this topic',
                    message: all.isEmpty
                        ? 'Ask a question or share what you\'re practising — posts '
                            'show up for everyone instantly.'
                        : 'Try another topic, or start the conversation yourself.',
                    action: OutlinedButton.icon(
                      onPressed: () => context.push(Routes.newPost),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Write a post'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ContentWidth(
                      child: _PostCard(post: filtered[i], index: i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.index});

  final ForumPost post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      onTap: () => context.push(Routes.post(post.id)),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: post.authorName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName, style: theme.textTheme.titleSmall),
                        Text(
                          timeAgo(post.createdAt),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post.topic,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(post.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.mode_comment_outlined,
                      size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    post.replyCount == 0
                        ? 'No replies yet'
                        : '${post.replyCount} ${post.replyCount == 1 ? 'reply' : 'replies'}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'Read',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          delay: (40 * index.clamp(0, 8)).ms,
          duration: 300.ms,
        ).moveY(begin: 14, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Deterministic tint per author so the same person keeps the same colour.
    final hue = name.codeUnits.fold<int>(0, (a, b) => a + b) % 360;
    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.62).toColor();
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Color.alphaBlend(
                color.withValues(alpha: 0.85),
                scheme.onSurface,
              ),
            ),
      ),
    );
  }
}

/// Shared by the list and the detail screen.
String timeAgo(DateTime? when) {
  if (when == null) return 'just now';
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(when);
}
