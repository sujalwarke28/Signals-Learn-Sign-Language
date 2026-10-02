import 'package:flutter_test/flutter_test.dart';

import 'package:signals/models/forum_post.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/screens/dashboard/library_snapshot.dart';
import 'package:signals/screens/dashboard/recall_nudge.dart';

final _today = DateTime(2026, 10, 2, 9);

Lesson _lesson(
  String id, {
  String category = 'Alphabet',
  bool placeholder = false,
  DateTime? createdAt,
}) =>
    Lesson(
      id: id,
      title: 'Lesson $id',
      description: '',
      category: category,
      durationSeconds: 60,
      videoUrl: 'https://example.com/$id.mp4',
      isPlaceholderVideo: placeholder,
      createdAt: createdAt,
    );

LessonProgress _done(String id, DateTime completedAt) => LessonProgress(
      lessonId: id,
      status: LessonStatus.completed,
      completedAt: completedAt,
    );

ForumPost _post(String id, {int replies = 0}) => ForumPost(
      id: id,
      authorId: 'u1',
      authorName: 'Ada',
      title: 'Question $id',
      body: '',
      replyCount: replies,
    );

void main() {
  group('recall nudge', () {
    test('stays quiet when everything was learned recently', () {
      expect(
        recallCandidate(
          lessons: [_lesson('a')],
          progress: {'a': _done('a', _today.subtract(const Duration(days: 1)))},
          today: _today,
        ),
        isNull,
      );
    });

    test('offers the lesson left longest since it was finished', () {
      final candidate = recallCandidate(
        lessons: [_lesson('a'), _lesson('b'), _lesson('c')],
        progress: {
          'a': _done('a', _today.subtract(const Duration(days: 6))),
          'b': _done('b', _today.subtract(const Duration(days: 20))),
          'c': _done('c', _today.subtract(const Duration(days: 9))),
        },
        today: _today,
      );
      expect(candidate?.id, 'b');
    });

    test('never nudges a lesson that was never finished', () {
      // Nagging someone about something they already gave up on is the exact
      // opposite of the tone this card is for.
      expect(
        recallCandidate(
          lessons: [_lesson('a')],
          progress: {
            'a': const LessonProgress(
              lessonId: 'a',
              status: LessonStatus.inProgress,
            ),
          },
          today: _today,
        ),
        isNull,
      );
    });

    test('counts calendar days, not elapsed hours', () {
      // Finished at 23:00 four nights ago: 4 days by the calendar even though
      // fewer than 4*24 hours have passed.
      expect(daysBetween(DateTime(2026, 9, 28, 23), _today), 4);
    });

    test('phrases the gap for the middle of a sentence', () {
      expect(agoLabel(0), 'today');
      expect(agoLabel(1), 'yesterday');
      expect(agoLabel(6), '6 days ago');
      expect(agoLabel(21), '3 weeks ago');
      expect(agoLabel(400), 'a while back');
    });
  });

  group('library snapshot', () {
    test('counts lessons per category, thinnest first', () {
      final snap = LibrarySnapshot.from(
        lessons: [
          _lesson('a', category: 'Alphabet'),
          _lesson('b', category: 'Alphabet'),
          _lesson('c', category: 'Alphabet'),
          _lesson('d', category: 'Colors'),
        ],
        posts: const [],
      );
      expect(snap.totalLessons, 4);
      expect(snap.categoryCount, 2);
      // The gap leads, because the gap is the actionable part.
      expect(snap.coverage.first.category, 'Colors');
      expect(snap.thinCategories.map((c) => c.category), ['Colors']);
    });

    test('flags placeholder footage and unanswered questions', () {
      final snap = LibrarySnapshot.from(
        lessons: [_lesson('a', placeholder: true), _lesson('b')],
        posts: [_post('p1'), _post('p2', replies: 3)],
      );
      expect(snap.placeholderLessons.map((l) => l.id), ['a']);
      expect(snap.unansweredPosts.map((p) => p.id), ['p1']);
      expect(snap.allClear, isFalse);
    });

    test('is all clear when there is nothing to fix', () {
      final snap = LibrarySnapshot.from(
        lessons: [_lesson('a'), _lesson('b'), _lesson('c')],
        posts: [_post('p1', replies: 1)],
      );
      expect(snap.allClear, isTrue);
    });

    test('recent lessons are newest first and survive a missing timestamp', () {
      final snap = LibrarySnapshot.from(
        lessons: [
          _lesson('old', createdAt: DateTime(2026, 1, 1)),
          _lesson('new', createdAt: DateTime(2026, 9, 1)),
          // Seeded before createdAt existed: must sort last, not crash.
          _lesson('undated'),
        ],
        posts: const [],
      );
      expect(snap.recentLessons.map((l) => l.id), ['new', 'old', 'undated']);
    });

    test('an empty library reports nothing rather than dividing by zero', () {
      final snap = LibrarySnapshot.from(lessons: const [], posts: const []);
      expect(snap.totalLessons, 0);
      expect(snap.categoryCount, 0);
      expect(snap.allClear, isTrue);
    });
  });
}
