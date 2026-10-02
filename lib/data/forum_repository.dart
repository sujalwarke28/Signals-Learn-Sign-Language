import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/forum_post.dart';
import 'firestore_refs.dart';

class ForumRepository {
  ForumRepository(FirebaseFirestore db)
      : _db = db,
        _refs = Refs(db);

  final FirebaseFirestore _db;
  final Refs _refs;

  /// Newest first. Sorted client-side so a brand-new post whose
  /// `serverTimestamp` hasn't resolved yet still appears immediately (its local
  /// snapshot has a null timestamp, which we float to the top).
  Stream<List<ForumPost>> watchPosts() => _refs.posts.snapshots().map((snap) {
        final posts = snap.docs.map(ForumPost.fromDoc).toList();
        posts.sort((a, b) {
          final at = a.createdAt, bt = b.createdAt;
          if (at == null && bt == null) return 0;
          if (at == null) return -1;
          if (bt == null) return 1;
          return bt.compareTo(at);
        });
        return posts;
      });

  Stream<ForumPost?> watchPost(String id) =>
      _refs.post(id).snapshots().map((d) => d.exists ? ForumPost.fromDoc(d) : null);

  Stream<List<ForumReply>> watchReplies(String postId) =>
      _refs.replies(postId).snapshots().map((snap) {
        final replies =
            snap.docs.map((d) => ForumReply.fromDoc(d, postId: postId)).toList();
        replies.sort((a, b) {
          final at = a.createdAt, bt = b.createdAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return at.compareTo(bt);
        });
        return replies;
      });

  /// [topics] is the set of channels the post lands in; [mentionedUids] the
  /// people its body addresses, resolved before writing so the mentions view is
  /// a filter over the existing stream rather than a second indexed query.
  ///
  /// `topic` is still written next to `topics` so a build from before channels
  /// existed keeps reading these posts.
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String title,
    required String body,
    required List<String> topics,
    List<String> mentionedUids = const [],
  }) async {
    final channels = topics.isEmpty ? const ['General'] : topics;
    final ref = _refs.posts.doc();
    await ref.set({
      'authorId': authorId,
      'authorName': authorName,
      'title': title.trim(),
      'body': body.trim(),
      'topics': channels,
      'topic': channels.first,
      'replyCount': 0,
      'mentionedUids': mentionedUids,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Adds the reply and bumps the parent's counter together, so the list badge
  /// can never drift from the actual number of replies.
  Future<void> addReply({
    required String postId,
    required String authorId,
    required String authorName,
    required String body,
    List<String> mentionedUids = const [],
  }) async {
    final batch = _db.batch();
    batch.set(_refs.replies(postId).doc(), {
      'authorId': authorId,
      'authorName': authorName,
      'body': body.trim(),
      'mentionedUids': mentionedUids,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_refs.post(postId), {'replyCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deletePost(String postId) async {
    final replies = await _refs.replies(postId).get();
    final batch = _db.batch();
    for (final d in replies.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_refs.post(postId));
    await batch.commit();
  }
}
