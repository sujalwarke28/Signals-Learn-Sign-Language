import 'lesson.dart';
import 'lesson_progress.dart';
import 'quiz_attempt.dart';

/// Stats for one category.
class CategoryStats {
  const CategoryStats({
    required this.category,
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.averageScorePercent,
    required this.hasAttempts,
  });

  final String category;
  final int totalLessons;
  final int completedLessons;
  final int inProgressLessons;
  final int averageScorePercent;
  final bool hasAttempts;

  double get completionFraction =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
  int get completionPercent => (completionFraction * 100).round();
}

/// Everything the Dashboard and Progress screens display, derived on the fly
/// from the learner's real Firestore documents.
///
/// Nothing in here is stored or hardcoded: [ProgressSummary.from] is called
/// with the latest lessons, progress docs and quiz attempts every time any of
/// those three streams emits, so the numbers move the moment a quiz is
/// submitted.
class ProgressSummary {
  const ProgressSummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.averageScorePercent,
    required this.totalAttempts,
    required this.passedAttempts,
    required this.perfectQuizzes,
    required this.categories,
    required this.dayStreak,
    required this.recentAttempts,
    required this.nextLesson,
    required this.continueLesson,
  });

  final int totalLessons;
  final int completedLessons;
  final int inProgressLessons;
  final int averageScorePercent;
  final int totalAttempts;
  final int passedAttempts;
  final int perfectQuizzes;
  final List<CategoryStats> categories;

  /// Consecutive days, counting back from today, with at least one attempt.
  final int dayStreak;
  final List<QuizAttempt> recentAttempts;

  /// First lesson the learner hasn't completed — the "up next" suggestion.
  final Lesson? nextLesson;

  /// A lesson already started but not finished; beats [nextLesson] on the
  /// dashboard's continue card when present.
  final Lesson? continueLesson;

  static const empty = ProgressSummary(
    totalLessons: 0,
    completedLessons: 0,
    inProgressLessons: 0,
    averageScorePercent: 0,
    totalAttempts: 0,
    passedAttempts: 0,
    perfectQuizzes: 0,
    categories: [],
    dayStreak: 0,
    recentAttempts: [],
    nextLesson: null,
    continueLesson: null,
  );

  double get completionFraction =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
  int get completionPercent => (completionFraction * 100).round();

  /// Badges are purely derived from the stats above, so they light up live too.
  List<EarnedBadge> get badges => [
        EarnedBadge(
          id: 'first_steps',
          label: 'First Steps',
          description: 'Finish your first lesson',
          icon: BadgeIcon.footprints,
          earned: completedLessons >= 1,
        ),
        EarnedBadge(
          id: 'quiz_taker',
          label: 'Quiz Taker',
          description: 'Complete 3 quizzes',
          icon: BadgeIcon.quiz,
          earned: totalAttempts >= 3,
        ),
        EarnedBadge(
          id: 'flawless',
          label: 'Flawless',
          description: 'Score 100% on any quiz',
          icon: BadgeIcon.star,
          earned: perfectQuizzes >= 1,
        ),
        EarnedBadge(
          id: 'on_a_roll',
          label: 'On a Roll',
          description: 'Practise 3 days in a row',
          icon: BadgeIcon.flame,
          earned: dayStreak >= 3,
        ),
        EarnedBadge(
          id: 'halfway',
          label: 'Halfway There',
          description: 'Complete half the library',
          icon: BadgeIcon.mountain,
          earned: totalLessons > 0 && completedLessons * 2 >= totalLessons,
        ),
        EarnedBadge(
          id: 'graduate',
          label: 'Graduate',
          description: 'Complete every lesson',
          icon: BadgeIcon.trophy,
          earned: totalLessons > 0 && completedLessons == totalLessons,
        ),
      ];

  int get earnedBadgeCount => badges.where((b) => b.earned).length;

  factory ProgressSummary.from({
    required List<Lesson> lessons,
    required Map<String, LessonProgress> progress,
    required List<QuizAttempt> attempts,
    DateTime? today,
  }) {
    if (lessons.isEmpty && attempts.isEmpty) return empty;

    // Passed in by [todayProvider] in production so the streak re-derives when
    // the clock rolls past midnight. Defaults to the real clock for callers
    // that don't care (tests of the other stats).
    final day = today ?? dayOf(DateTime.now());

    LessonProgress progressFor(String id) =>
        progress[id] ?? LessonProgress.notStarted(id);

    final completed =
        lessons.where((l) => progressFor(l.id).isCompleted).toList();
    final inProgress =
        lessons.where((l) => progressFor(l.id).isInProgress).toList();

    // Average score uses each lesson's *best* attempt so retries improve the
    // number rather than dragging it down.
    final bestByLesson = <String, int>{};
    for (final a in attempts) {
      final current = bestByLesson[a.lessonId];
      if (current == null || a.percent > current) bestByLesson[a.lessonId] = a.percent;
    }
    final average = bestByLesson.isEmpty
        ? 0
        : (bestByLesson.values.reduce((a, b) => a + b) / bestByLesson.length).round();

    // Per-category rollup, ordered the way the lessons are ordered.
    final categoryOrder = <String>[];
    final byCategory = <String, List<Lesson>>{};
    for (final l in lessons) {
      if (!byCategory.containsKey(l.category)) categoryOrder.add(l.category);
      byCategory.putIfAbsent(l.category, () => []).add(l);
    }
    final categories = categoryOrder.map((name) {
      final group = byCategory[name]!;
      final scores = group
          .map((l) => bestByLesson[l.id])
          .whereType<int>()
          .toList();
      return CategoryStats(
        category: name,
        totalLessons: group.length,
        completedLessons: group.where((l) => progressFor(l.id).isCompleted).length,
        inProgressLessons: group.where((l) => progressFor(l.id).isInProgress).length,
        averageScorePercent: scores.isEmpty
            ? 0
            : (scores.reduce((a, b) => a + b) / scores.length).round(),
        hasAttempts: scores.isNotEmpty,
      );
    }).toList();

    final sortedAttempts = [...attempts]..sort((a, b) {
        final at = a.createdAt, bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return ProgressSummary(
      totalLessons: lessons.length,
      completedLessons: completed.length,
      inProgressLessons: inProgress.length,
      averageScorePercent: average,
      totalAttempts: attempts.length,
      passedAttempts: attempts.where((a) => a.passed).length,
      perfectQuizzes: attempts.where((a) => a.total > 0 && a.score == a.total).length,
      categories: categories,
      dayStreak: _streak(attempts: attempts, progress: progress, today: day),
      recentAttempts: sortedAttempts.take(5).toList(),
      nextLesson: lessons.where((l) => !progressFor(l.id).isCompleted).firstOrNull,
      continueLesson: inProgress.firstOrNull,
    );
  }

  /// Midnight on the day [t] falls in. Streak maths compares whole days, so
  /// every timestamp is flattened to one of these first.
  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  /// The day before [d]. Built by field rather than by subtracting 24 hours so
  /// it stays exactly midnight across a daylight-saving boundary, where a
  /// `Duration(days: 1)` step lands on 23:00 or 01:00 and stops matching.
  static DateTime _previousDay(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1);

  /// Consecutive days ending today (or yesterday) on which the learner did
  /// something that counts: sat a quiz, or watched or advanced a lesson.
  ///
  /// Pure, and takes [today] instead of reading the clock, so the midnight
  /// rollover is testable without waiting for one.
  static int _streak({
    required List<QuizAttempt> attempts,
    required Map<String, LessonProgress> progress,
    required DateTime today,
  }) {
    final days = <DateTime>{};

    // Null means two different things here, so there are two recorders.

    // For a field that is always written: the value is null only while the
    // local cache holds an unresolved server timestamp. That write happened on
    // this device, just now, so today is the right day — this is what stops the
    // streak lagging a submitted quiz by a network round-trip.
    void recordWritten(DateTime? stamp) =>
        days.add(stamp == null ? today : dayOf(stamp));

    // For a field that may legitimately be absent (an unfinished lesson has no
    // `completedAt`): null means the event never happened, and crediting today
    // for it would pin every streak at one or more forever.
    void recordIfSet(DateTime? stamp) {
      if (stamp != null) days.add(dayOf(stamp));
    }

    for (final a in attempts) {
      recordWritten(a.createdAt);
    }
    for (final p in progress.values) {
      // `notStarted` docs carry no activity worth crediting.
      if (p.status == LessonStatus.notStarted) continue;
      // A progress doc keeps one `updatedAt`, overwritten on every write, so a
      // lesson revisited daily remembers only the last visit. `startedAt` and
      // `completedAt` are each written once and survive, which recovers a
      // little of the history that overwrite loses.
      recordIfSet(p.startedAt);
      recordIfSet(p.completedAt);
      recordWritten(p.updatedAt);
    }

    if (days.isEmpty) return 0;

    var cursor = today;
    // A streak stays alive if the learner practised today or yesterday, so an
    // unfinished day never looks like a broken one.
    if (!days.contains(cursor)) {
      cursor = _previousDay(cursor);
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = _previousDay(cursor);
    }
    return streak;
  }
}

enum BadgeIcon { footprints, quiz, star, flame, mountain, trophy }

class EarnedBadge {
  const EarnedBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.earned,
  });

  final String id;
  final String label;
  final String description;
  final BadgeIcon icon;
  final bool earned;
}
