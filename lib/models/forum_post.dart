import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    this.topic = 'General',
    this.replyCount = 0,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final String topic;
  final int replyCount;
  final DateTime? createdAt;

  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ForumPost(
      id: doc.id,
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Someone',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      topic: (data['topic'] as String?) ?? 'General',
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'title': title,
        'body': body,
        'topic': topic,
        'replyCount': replyCount,
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
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime? createdAt;

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
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'body': body,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
