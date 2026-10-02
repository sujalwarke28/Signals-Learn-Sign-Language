import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forum_post.dart';
import 'app_providers.dart';

/// All posts, newest first, live for every signed-in user.
final forumPostsProvider = StreamProvider<List<ForumPost>>((ref) {
  ref.keepAlive();
  return ref.watch(forumRepositoryProvider).watchPosts();
});

final forumPostProvider = StreamProvider.family<ForumPost?, String>(
    (ref, id) => ref.watch(forumRepositoryProvider).watchPost(id));

final forumRepliesProvider = StreamProvider.family<List<ForumReply>, String>(
    (ref, postId) => ref.watch(forumRepositoryProvider).watchReplies(postId));

/// Selected topic filter on the forum list. `null` means "All".
class ForumTopicFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? topic) => state = topic;
}

final forumTopicFilterProvider =
    NotifierProvider<ForumTopicFilter, String?>(ForumTopicFilter.new);

final filteredForumPostsProvider = Provider<List<ForumPost>>((ref) {
  final posts = ref.watch(forumPostsProvider).value ?? const [];
  final topic = ref.watch(forumTopicFilterProvider);
  if (topic == null) return posts;
  return posts.where((p) => p.topic == topic).toList();
});
