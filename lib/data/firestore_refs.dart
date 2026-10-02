import 'package:cloud_firestore/cloud_firestore.dart';

/// Every Firestore path the app touches, named once.
///
/// Layout:
/// ```
/// users/{uid}
/// users/{uid}/progress/{lessonId}
/// users/{uid}/attempts/{attemptId}
/// lessons/{lessonId}
/// lessons/{lessonId}/questions/{questionId}
/// forum_posts/{postId}
/// forum_posts/{postId}/replies/{replyId}
/// ```
class Refs {
  Refs(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  DocumentReference<Map<String, dynamic>> user(String uid) => users.doc(uid);

  CollectionReference<Map<String, dynamic>> progress(String uid) =>
      user(uid).collection('progress');
  DocumentReference<Map<String, dynamic>> lessonProgress(String uid, String lessonId) =>
      progress(uid).doc(lessonId);

  CollectionReference<Map<String, dynamic>> attempts(String uid) =>
      user(uid).collection('attempts');

  CollectionReference<Map<String, dynamic>> get lessons => _db.collection('lessons');
  DocumentReference<Map<String, dynamic>> lesson(String id) => lessons.doc(id);
  CollectionReference<Map<String, dynamic>> questions(String lessonId) =>
      lesson(lessonId).collection('questions');

  CollectionReference<Map<String, dynamic>> get posts => _db.collection('forum_posts');
  DocumentReference<Map<String, dynamic>> post(String id) => posts.doc(id);
  CollectionReference<Map<String, dynamic>> replies(String postId) =>
      post(postId).collection('replies');
}
