import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forum_post.dart';
import 'app_providers.dart';
import '../screens/forum/channels.dart';
import '../screens/forum/mentions.dart';
import 'auth_providers.dart';

/// All posts, newest first, live for every signed-in user.
final forumPostsProvider = StreamProvider<List<ForumPost>>((ref) {
  ref.keepAlive();
  return ref.watch(forumRepositoryProvider).watchPosts();
});

final forumPostProvider = StreamProvider.family<ForumPost?, String>(
  (ref, id) => ref.watch(forumRepositoryProvider).watchPost(id),
);

final forumRepliesProvider = StreamProvider.family<List<ForumReply>, String>(
  (ref, postId) => ref.watch(forumRepositoryProvider).watchReplies(postId),
);

/// Selected topic filter on the forum list. `null` means "All".
class ForumTopicFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? topic) => state = topic;
}

final forumTopicFilterProvider = NotifierProvider<ForumTopicFilter, String?>(
  ForumTopicFilter.new,
);

final filteredForumPostsProvider = Provider<List<ForumPost>>((ref) {
  final posts = ref.watch(forumPostsProvider).value ?? const [];
  final topic = ref.watch(forumTopicFilterProvider);
  if (topic == null) return posts;
  return posts.where((p) => p.topic == topic).toList();
});

// ---------------------------------------------------------------- channels

/// Which channel the community screen is showing. Null is the firehose; the
/// [mentionsChannel] sentinel is the "addressed to me" view.
class ForumChannel extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? topic) => state = topic;
}

final forumChannelProvider = NotifierProvider<ForumChannel, String?>(
  ForumChannel.new,
);

/// Not a real topic — a pseudo-channel for posts naming the reader.
const mentionsChannel = '\u0000mentions';

/// Everyone who has posted, so the composer can offer them after an @.
final forumPeopleProvider = Provider<List<ForumPerson>>((ref) {
  final posts = ref.watch(forumPostsProvider).value ?? const [];
  return forumPeople(posts: posts, excludeUid: ref.watch(currentUidProvider));
});

/// Posts addressed to the reader.
final myMentionsProvider = Provider<List<ForumPost>>((ref) {
  final posts = ref.watch(forumPostsProvider).value ?? const [];
  return postsMentioning(posts, ref.watch(currentUidProvider));
});

/// The last time the reader opened each channel, persisted locally.
///
/// Deliberately device-local: syncing it would mean a `users/{uid}` subcollection,
/// and the rules grant only `progress` and `attempts` there — so a server-side
/// version could not be read or written until new rules were deployed.
class ChannelReads extends Notifier<Map<String, DateTime>> {
  static const _key = 'forum.channelReads';

  @override
  Map<String, DateTime> build() {
    final raw =
        ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
    final out = <String, DateTime>{};
    for (final entry in raw) {
      final at = entry.indexOf('|');
      if (at <= 0) continue;
      final ms = int.tryParse(entry.substring(at + 1));
      if (ms == null) continue;
      out[entry.substring(0, at)] = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return out;
  }

  Future<void> markSeen(String topic) async {
    final next = {...state, topic: DateTime.now()};
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, [
      for (final e in next.entries)
        '${e.key}|${e.value.millisecondsSinceEpoch}',
    ]);
  }
}

final channelReadsProvider =
    NotifierProvider<ChannelReads, Map<String, DateTime>>(ChannelReads.new);

/// Unread count per channel topic.
final unreadByChannelProvider = Provider<Map<String, int>>((ref) {
  final posts = ref.watch(forumPostsProvider).value ?? const [];
  final reads = ref.watch(channelReadsProvider);
  final uid = ref.watch(currentUidProvider);
  return {
    for (final c in Channel.all)
      c.topic: unreadIn(
        posts: posts,
        topic: c.topic,
        lastSeen: reads[c.topic],
        viewerUid: uid,
      ),
  };
});
