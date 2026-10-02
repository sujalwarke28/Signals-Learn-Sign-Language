import 'package:cloud_firestore/cloud_firestore.dart';

/// A video lesson. Written by admins, read by everyone.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationSeconds,
    required this.videoUrl,
    this.thumbnailUrl,
    this.order = 0,
    this.difficulty = 'Beginner',
    this.isPlaceholderVideo = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int durationSeconds;
  final String videoUrl;
  final String? thumbnailUrl;
  final int order;
  final String difficulty;

  /// True for seeded lessons whose clip stands in for real sign-language
  /// footage. Surfaced in the UI so a demo never misrepresents the content.
  final bool isPlaceholderVideo;
  final DateTime? createdAt;

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return s == 0 ? '$m min' : '$m min ${s}s';
  }

  factory Lesson.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Lesson(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled lesson',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      videoUrl: (data['videoUrl'] as String?) ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
      difficulty: (data['difficulty'] as String?) ?? 'Beginner',
      isPlaceholderVideo: (data['isPlaceholderVideo'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'durationSeconds': durationSeconds,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'order': order,
        'difficulty': difficulty,
        'isPlaceholderVideo': isPlaceholderVideo,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
