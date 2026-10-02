import '../../models/forum_post.dart';
import '../../models/lesson.dart';

/// One category's slice of the library, from the admin's side of the glass.
class CategoryCoverage {
  const CategoryCoverage({required this.category, required this.lessonCount});

  final String category;
  final int lessonCount;

  /// Below this a category reads as a stub to a learner browsing it — one
  /// lesson under "Colors" is worse than no "Colors" tab at all.
  bool get isThin => lessonCount < 3;
}

/// What an admin needs to know about the library, derived from the same two
/// streams the rest of the app already watches.
///
/// Pure, so the thresholds that drive "needs attention" can be tested without
/// standing up Firestore.
class LibrarySnapshot {
  const LibrarySnapshot({
    required this.totalLessons,
    required this.coverage,
    required this.placeholderLessons,
    required this.unansweredPosts,
    required this.recentLessons,
  });

  final int totalLessons;
  final List<CategoryCoverage> coverage;

  /// Lessons still pointing at stand-in footage. These are the ones that will
  /// embarrass you in a demo, so they lead the attention list.
  final List<Lesson> placeholderLessons;

  /// Questions nobody has replied to yet.
  final List<ForumPost> unansweredPosts;

  /// Newest first, for a sense of what landed recently.
  final List<Lesson> recentLessons;

  int get categoryCount => coverage.length;
  List<CategoryCoverage> get thinCategories =>
      coverage.where((c) => c.isThin).toList();

  bool get allClear => placeholderLessons.isEmpty && unansweredPosts.isEmpty;

  factory LibrarySnapshot.from({
    required List<Lesson> lessons,
    required List<ForumPost> posts,
  }) {
    final counts = <String, int>{};
    for (final l in lessons) {
      counts[l.category] = (counts[l.category] ?? 0) + 1;
    }

    final coverage =
        counts.entries
            .map((e) => CategoryCoverage(category: e.key, lessonCount: e.value))
            .toList()
          // Thinnest first: the gaps are the actionable part, not the full shelves.
          ..sort((a, b) => a.lessonCount.compareTo(b.lessonCount));

    final recent = [...lessons]
      ..sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        // Lessons predating the createdAt field sort last rather than crashing.
        if (at == null && bt == null) return a.title.compareTo(b.title);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return LibrarySnapshot(
      totalLessons: lessons.length,
      coverage: coverage,
      placeholderLessons: lessons.where((l) => l.isPlaceholderVideo).toList(),
      unansweredPosts: posts.where((p) => p.replyCount == 0).toList(),
      recentLessons: recent.take(4).toList(),
    );
  }
}
