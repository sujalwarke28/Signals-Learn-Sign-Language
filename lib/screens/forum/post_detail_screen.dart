import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sound/sound_service.dart';
import '../../models/forum_post.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/forum_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mention_field.dart';
import 'forum_list_screen.dart' show timeAgo;
import 'mentions.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  /// Mentionable people: everyone who has posted on the board, plus everyone
  /// in this thread, so a reply can name someone who only appears here.
  List<ForumPerson> _people() => forumPeople(
    posts: ref.read(forumPostsProvider).value ?? const [],
    replies: ref.read(forumRepliesProvider(widget.postId)).value ?? const [],
    excludeUid: ref.read(currentUidProvider),
  );

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty) return;
    final user = ref.read(appUserProvider).value;
    final uid = ref.read(currentUidProvider);
    if (user == null || uid == null) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(forumRepositoryProvider)
          .addReply(
            postId: widget.postId,
            authorId: uid,
            authorName: user.displayName.isEmpty ? 'Learner' : user.displayName,
            body: body,
            mentionedUids: resolveMentions(body, _people()),
          );
      if (!mounted) return;
      _reply.clear();
      _replyFocus.unfocus();
      ref.playSfx(Sfx.post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not post the reply: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(forumPostProvider(widget.postId));
    final replies = ref.watch(forumRepliesProvider(widget.postId));
    final scheme = Theme.of(context).colorScheme;
    final viewerUid = ref.watch(currentUidProvider);
    final people = forumPeople(
      posts: ref.watch(forumPostsProvider).value ?? const [],
      replies: replies.value ?? const [],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Discussion'),
      ),
      body: SafeArea(
        child: post.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (p) => p == null
              ? const EmptyState(
                  icon: Icons.help_outline_rounded,
                  title: 'Post not found',
                  message: 'It may have been deleted.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        children: [
                          ContentWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PostHeader(
                                  post: p,
                                  people: people,
                                  viewerUid: viewerUid,
                                ),
                                const SizedBox(height: 24),
                                Divider(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                replies.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                  error: (e, _) =>
                                      Text('Could not load replies: $e'),
                                  data: (list) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        list.isEmpty
                                            ? 'No replies yet'
                                            : '${list.length} '
                                                  '${list.length == 1 ? 'reply' : 'replies'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      if (list.isEmpty)
                                        Text(
                                          'Be the first to help out.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        )
                                      else
                                        for (var i = 0; i < list.length; i++)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: _ReplyCard(
                                              people: people,
                                              viewerUid: viewerUid,
                                              reply: list[i],
                                              isAuthor:
                                                  list[i].authorId ==
                                                  p.authorId,
                                              index: i,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReplyComposer(
                      controller: _reply,
                      focusNode: _replyFocus,
                      sending: _sending,
                      onSend: _send,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.people,
    required this.viewerUid,
  });

  final List<ForumPerson> people;
  final String? viewerUid;

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            post.topic,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(post.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.person_rounded,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              post.authorName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '·',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              timeAgo(post.createdAt),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        MentionText(
          body: post.body,
          people: people,
          viewerUid: viewerUid,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0);
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.isAuthor,
    required this.index,
    required this.people,
    required this.viewerUid,
  });

  final List<ForumPerson> people;
  final String? viewerUid;

  final ForumReply reply;
  final bool isAuthor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(reply.authorName, style: theme.textTheme.titleSmall),
                  if (isAuthor) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'author',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    timeAgo(reply.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MentionText(
                body: reply.body,
                people: people,
                viewerUid: viewerUid,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (35 * index.clamp(0, 8)).ms, duration: 280.ms)
        .moveY(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.viewInsetsOf(context).bottom * 0,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: ContentWidth(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                maxLength: 600,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a reply…',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => sending ? null : onSend(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              width: 52,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
