import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import 'app_providers.dart';
import 'auth_providers.dart';

/// The whole library, live. Kept alive so navigating between tabs doesn't
/// re-fetch and flash a loading state.
///
/// The uid dependency is load-bearing, not decoration: `/lessons` is readable
/// only to a signed-in learner, so at sign-out Firestore drops this stream with
/// permission-denied. Without something auth-shaped to rebuild on, the
/// kept-alive subscription outlives the session and stays stuck on that error —
/// which is what put "Not allowed to read that" on the dashboard instead of the
/// login screen. Rebuilding on uid also re-reads the library as the next
/// learner, rather than serving them the last one's cache.
final lessonsProvider = StreamProvider<List<Lesson>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  ref.keepAlive();
  return ref.watch(lessonRepositoryProvider).watchLessons();
});

final lessonProvider = StreamProvider.family<Lesson?, String>(
    (ref, id) => ref.watch(lessonRepositoryProvider).watchLesson(id));

final questionsProvider = StreamProvider.family<List<Question>, String>(
    (ref, lessonId) => ref.watch(lessonRepositoryProvider).watchQuestions(lessonId));

/// Distinct categories in library order, for the filter chips.
final categoriesProvider = Provider<List<String>>((ref) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  final seen = <String>[];
  for (final l in lessons) {
    if (!seen.contains(l.category)) seen.add(l.category);
  }
  return seen;
});

/// Which category chip is selected in the library. `null` means "All".
class LessonFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

final lessonFilterProvider = NotifierProvider<LessonFilter, String?>(LessonFilter.new);

class LessonSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final lessonSearchProvider = NotifierProvider<LessonSearch, String>(LessonSearch.new);

/// Lessons after the category chip and the search box are applied.
final filteredLessonsProvider = Provider<List<Lesson>>((ref) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  final category = ref.watch(lessonFilterProvider);
  final query = ref.watch(lessonSearchProvider).trim().toLowerCase();

  return lessons.where((l) {
    if (category != null && l.category != category) return false;
    if (query.isEmpty) return true;
    return l.title.toLowerCase().contains(query) ||
        l.description.toLowerCase().contains(query) ||
        l.category.toLowerCase().contains(query);
  }).toList();
});
