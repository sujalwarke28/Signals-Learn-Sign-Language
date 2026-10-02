import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_refs.dart';
import 'forum_repository.dart';
import 'lesson_repository.dart';
import 'seed_data.dart';

class SeedReport {
  const SeedReport({
    required this.lessons,
    required this.questions,
    required this.posts,
    required this.replies,
  });

  final int lessons;
  final int questions;
  final int posts;
  final int replies;

  String get summary =>
      '$lessons lessons, $questions questions, $posts posts, $replies replies';
}

/// Loads the demo content in [SeedData] into Firestore.
///
/// Runs from inside the app as the signed-in admin, so it needs no service
/// account key and is validated by the same security rules as any other write —
/// which also makes it a useful check that the rules are deployed correctly.
class SeedService {
  SeedService({
    required FirebaseFirestore db,
    required LessonRepository lessons,
    required ForumRepository forum,
  })  : _refs = Refs(db),
        _lessons = lessons,
        _forum = forum;

  final Refs _refs;
  final LessonRepository _lessons;
  final ForumRepository _forum;

  Future<bool> hasLessons() async {
    final snap = await _refs.lessons.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> hasPosts() async {
    final snap = await _refs.posts.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Writes the lessons, their questions, and the forum threads.
  ///
  /// [authorId] must be the calling admin's uid — the forum rules require the
  /// author to match the signed-in user. The display names come from the seed
  /// data so the demo forum reads like several people talking.
  Future<SeedReport> seed({
    required String authorId,
    bool includeLessons = true,
    bool includeForum = true,
  }) async {
    var lessonCount = 0;
    var questionCount = 0;
    var postCount = 0;
    var replyCount = 0;

    if (includeLessons) {
      for (final seed in SeedData.lessons()) {
        final questions = seed.toQuestions();
        await _lessons.createLesson(lesson: seed.lesson, questions: questions);
        lessonCount++;
        questionCount += questions.length;
      }
    }

    if (includeForum) {
      for (final post in SeedData.posts()) {
        final id = await _forum.createPost(
          authorId: authorId,
          authorName: post.authorName,
          title: post.title,
          body: post.body,
          topics: post.topics,
        );
        postCount++;
        for (final reply in post.replies) {
          await _forum.addReply(
            postId: id,
            authorId: authorId,
            authorName: reply.authorName,
            body: reply.body,
          );
          replyCount++;
        }
      }
    }

    return SeedReport(
      lessons: lessonCount,
      questions: questionCount,
      posts: postCount,
      replies: replyCount,
    );
  }

  /// Removes every seeded lesson and forum thread. Used by the admin screen's
  /// "clear demo content" action so a demo can be reset cleanly.
  ///
  /// Learner progress documents are left alone: they live under `users/{uid}`
  /// and an admin has no rule permission to touch another learner's data.
  Future<void> clearContent() async {
    final lessons = await _refs.lessons.get();
    for (final doc in lessons.docs) {
      await _lessons.deleteLesson(doc.id);
    }
    final posts = await _refs.posts.get();
    for (final doc in posts.docs) {
      await _forum.deletePost(doc.id);
    }
  }
}
