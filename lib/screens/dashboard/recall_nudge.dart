import '../../models/lesson.dart';
import '../../models/lesson_progress.dart';

/// Picks a finished lesson worth revisiting, or null when nothing is due.
///
/// Signs decay fast when they aren't used, and the dashboard is otherwise
/// silent on days with no new progress — which are most days. This gives it
/// something warm to say that is also pedagogically honest: spaced repetition,
/// framed as a question rather than a demand.
///
/// Pure so the thresholds are testable without Firestore or a widget tree, the
/// same way [authRedirect] is.
Lesson? recallCandidate({
  required List<Lesson> lessons,
  required Map<String, LessonProgress> progress,
  required DateTime today,
  int afterDays = 4,
}) {
  Lesson? oldest;
  DateTime? oldestAt;

  for (final lesson in lessons) {
    final p = progress[lesson.id];
    final at = p?.completedAt;
    // Only finished lessons: nudging someone to revisit something they never
    // got through in the first place is just nagging.
    if (p == null || !p.isCompleted || at == null) continue;

    if (daysBetween(at, today) < afterDays) continue;
    if (oldestAt == null || at.isBefore(oldestAt)) {
      oldest = lesson;
      oldestAt = at;
    }
  }
  return oldest;
}

/// Whole days between two instants, counted on calendar dates so a lesson
/// finished last night at 23:00 doesn't read as "0 days ago" this morning.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// "4 days ago", phrased for the middle of a sentence.
String agoLabel(int days) => switch (days) {
  <= 0 => 'today',
  1 => 'yesterday',
  < 14 => '$days days ago',
  < 60 => '${(days / 7).round()} weeks ago',
  _ => 'a while back',
};
