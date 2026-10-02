import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    this.topics = const ['General'],
    this.replyCount = 0,
    this.createdAt,
    this.mentionedUids = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;

  /// A post can sit in more than one channel. Stored as a list; the legacy
  /// single `topic` field is still read so posts written before channels
  /// existed keep working.
  final List<String> topics;

  final int replyCount;
  final DateTime? createdAt;

  /// Uids named with an @mention in [body], resolved when the post was written.
  /// Denormalised deliberately: the client already streams every post, so the
  /// mentions view is a filter rather than a second query needing an index.
  final List<String> mentionedUids;

  /// First channel, for anywhere that can only show one.
  String get topic => topics.isEmpty ? 'General' : topics.first;

  bool mentions(String? uid) => uid != null && mentionedUids.contains(uid);

  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ForumPost(
      id: doc.id,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Someone',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      topics: _topicsFrom(data),
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      mentionedUids: _stringsFrom(data['mentionedUids']),
    );
  }

  /// Prefers the list, falls back to the old single field, and never returns
  /// empty — an untagged post belongs in General rather than nowhere.
  static List<String> _topicsFrom(Map<String, dynamic> data) {
    final list = _stringsFrom(data['topics']);
    if (list.isNotEmpty) return list;
    final single = data['topic'] as String?;
    return [if (single != null && single.isNotEmpty) single else 'General'];
  }

  static List<String> _stringsFrom(Object? raw) => raw is List
      ? raw.whereType<String>().where((s) => s.isNotEmpty).toList()
      : const [];

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'title': title,
        'body': body,
        'topics': topics,
        // Written alongside the list so an older build still reads the post.
        'topic': topic,
        'replyCount': replyCount,
        'mentionedUids': mentionedUids,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}

class ForumReply {
  const ForumReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    this.createdAt,
    this.mentionedUids = const [],
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime? createdAt;
  final List<String> mentionedUids;

  factory ForumReply.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String postId,
  }) {
    final data = doc.data() ?? const {};
    return ForumReply(
      id: doc.id,
      postId: postId,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Someone',
      body: (data['body'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      mentionedUids: ForumPost._stringsFrom(data['mentionedUids']),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'body': body,
        'mentionedUids': mentionedUids,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
