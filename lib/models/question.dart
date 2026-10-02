import 'package:cloud_firestore/cloud_firestore.dart';

/// One multiple-choice quiz question, stored at
/// `lessons/{lessonId}/questions/{questionId}`.
class Question {
  const Question({
    required this.id,
    required this.lessonId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.imageUrl,
    this.explanation,
    this.order = 0,
  });

  final String id;
  final String lessonId;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Optional Cloudinary image shown with the prompt — a handshape photo, say.
  /// Null on text-only questions, which is most of them.
  final String? imageUrl;
  final String? explanation;
  final int order;

  /// Guards against the empty string as well as null: an admin who attaches and
  /// then removes an image would otherwise leave `''` behind and the quiz would
  /// try to render a broken image.
  bool get hasImage => (imageUrl ?? '').isNotEmpty;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  String get correctOption =>
      correctIndex >= 0 && correctIndex < options.length ? options[correctIndex] : '';

  factory Question.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String lessonId,
  }) {
    final data = doc.data() ?? const {};
    return Question(
      id: doc.id,
      lessonId: lessonId,
      prompt: (data['prompt'] as String?) ?? '',
      options: ((data['options'] as List?) ?? const []).map((e) => '$e').toList(),
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      explanation: data['explanation'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'imageUrl': imageUrl,
        'explanation': explanation,
        'order': order,
      };
}
