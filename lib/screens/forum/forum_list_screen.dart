import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/forum_post.dart';
import '../../providers/auth_providers.dart';
import '../../providers/forum_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/mention_field.dart';
import 'channel_composer.dart';
import 'channel_rail.dart';
import 'channels.dart';
import 'mentions.dart';

/// The community, laid out like a chat client: channels down the side, the
/// selected channel's messages beside them.
///
/// The rail is persistent from tablet width up and lives in a drawer below it.
class ForumListScreen extends ConsumerWidget {
  const ForumListScreen({super.key});

  /// Below this there isn't room for a rail and a readable message column side
  /// by side, so the rail becomes a drawer.
  static const railBreakpoint = 840.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(forumPostsProvider);
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;

    return Scaffold(
      drawer: wide
          ? null
          : Drawer(
              width: 262,
              child: ChannelRail(
                width: 262,
                onPick: () => Navigator.of(context).maybePop(),
              ),
            ),
      body: posts.when(
        loading: () => const LoadingView(message: 'Loading the community'),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(forumPostsProvider),
        ),
        data: (all) => Row(
          children: [
            if (wide) const ChannelRail(),
            Expanded(
              child: _Channel(all: all, showMenuButton: !wide),
            ),
          ],
        ),
      ),
    );
  }
}

class _Channel extends ConsumerWidget {
  const _Channel({required this.all, required this.showMenuButton});

  final List<ForumPost> all;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(forumChannelProvider);
    final uid = ref.watch(currentUidProvider);
    final people = ref.watch(forumPeopleProvider);

    final (title, blurb, visible) = switch (selected) {
      null => ('All messages', 'Everything, newest first', all),
      mentionsChannel => (
        'Mentions',
        'Messages that name you',
        ref.watch(myMentionsProvider),
      ),
      final topic => (
        Channel(topic: topic).label,
        _blurbFor(topic),
        postsIn(all, topic),
      ),
    };

    return Column(
      children: [
        _ChannelHeader(
          title: title,
          blurb: blurb,
          count: visible.length,
          showMenuButton: showMenuButton,
        ),
        Expanded(
          child: visible.isEmpty
              ? _EmptyChannel(isMentions: selected == mentionsChannel)
              // Reversed, so the newest message sits at the bottom against the
              // composer and the view opens already scrolled to it — the list
              // itself stays newest-first.
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => ContentWidth(
                    maxWidth: 820,
                    child: _Message(
                      post: visible[i],
                      // The message drawn above this one is the next index,
                      // because the list is reversed.
                      previous: i + 1 < visible.length ? visible[i + 1] : null,
                      people: people,
                      viewerUid: uid,
                    ),
                  ),
                ),
        ),
        const ChannelComposer(),
      ],
    );
  }

  static String _blurbFor(String topic) => switch (topic) {
    'General' => 'Anything that does not fit elsewhere',
    'Question' => 'Stuck on a sign? Ask here',
    'Practice Tips' => 'What is working for you',
    'Introductions' => 'Say hello — in writing or in signs',
    'Resources' => 'Links, books, people worth following',
    _ => 'Messages in this channel',
  };
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.title,
    required this.blurb,
    required this.count,
    required this.showMenuButton,
  });

  final String title;
  final String blurb;
  final int count;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 18, 14),
          child: Row(
            children: [
              if (showMenuButton)
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.tag_rounded),
                    tooltip: 'Channels',
                  ),
                )
              else
                const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(
                      blurb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One message in the transcript.
///
/// No card: a chat is a column of text, and a box per message turns five lines
/// of conversation into five competing objects. Consecutive messages from the
/// same person inside a few minutes drop their header and sit under the first,
/// which is what makes a back-and-forth read as one.
class _Message extends StatelessWidget {
  const _Message({
    required this.post,
    required this.previous,
    required this.people,
    required this.viewerUid,
  });

  final ForumPost post;

  /// The message drawn directly above this one, if any.
  final ForumPost? previous;

  final List<ForumPerson> people;
  final String? viewerUid;

  /// Long enough that a quick follow-up joins the one before it, short enough
  /// that a reply hours later gets its own header and timestamp.
  static const _groupWindow = Duration(minutes: 5);

  bool get _startsGroup {
    final p = previous;
    if (p == null || p.authorId != post.authorId) return true;
    final a = p.createdAt;
    final b = post.createdAt;
    if (a == null || b == null) return true;
    return b.difference(a).abs() > _groupWindow;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final aboutYou = post.mentions(viewerUid);
    const gutter = 52.0;

    return Padding(
      padding: EdgeInsets.only(top: _startsGroup ? 14 : 2),
      child: Material(
        color: aboutYou
            // A message that names you gets a wash across the row rather than a
            // border, so it reads as highlighted text, not as a separate card.
            ? scheme.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.push(Routes.post(post.id)),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gutter,
                  child: _startsGroup
                      ? Avatar(name: post.authorName, size: 38)
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_startsGroup) ...[
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: authorColor(post.authorName),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgo(post.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                            if (aboutYou) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 12,
                                color: scheme.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      MentionText(
                        body: post.body,
                        people: people,
                        viewerUid: viewerUid,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (post.replyCount > 0 || post.topics.length > 1) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (post.replyCount > 0) ...[
                              Icon(
                                Icons.mode_comment_rounded,
                                size: 12,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.replyCount} '
                                '${post.replyCount == 1 ? 'reply' : 'replies'}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            // Only worth saying when it is somewhere else too:
                            // inside #general, "#general" is noise.
                            if (post.topics.length > 1) ...[
                              if (post.replyCount > 0)
                                const SizedBox(width: 10),
                              Text(
                                post.topics
                                    .map((t) => Channel(topic: t).label)
                                    .join(' '),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
}

class _EmptyChannel extends StatelessWidget {
  const _EmptyChannel({required this.isMentions});

  final bool isMentions;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: isMentions ? Icons.alternate_email_rounded : Icons.forum_outlined,
    title: isMentions ? 'Nobody has named you yet' : 'Quiet in here',
    message: isMentions
        ? 'When someone writes @you in a message, it lands here.'
        : 'Nothing in this channel yet. Ask a question or share what you '
              'are practising — it shows up for everyone instantly.',
  );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = authorColor(name);
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: size * 0.36,
          color: Color.alphaBlend(
            color.withValues(alpha: 0.85),
            scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Deterministic tint per author, so the same person keeps the same colour
/// everywhere they appear.
Color authorColor(String name) {
  final hue = name.codeUnits.fold<int>(0, (a, b) => a + b) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.62).toColor();
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
