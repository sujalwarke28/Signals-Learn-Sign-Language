/// Tunable rules of the app, in one place.
class AppConstants {
  const AppConstants._();

  /// Percentage needed to pass a lesson quiz.
  static const int passThresholdPercent = 70;

  /// How much of a video counts as "watched". Trailing frames are often
  /// unreachable on some codecs, so we don't demand 100%.
  static const double videoCompleteFraction = 0.95;

  /// Categories offered in the admin lesson form.
  static const List<String> categories = [
    'Alphabet',
    'Numbers',
    'Common Phrases',
    'Greetings',
    'Family',
    'Colors',
  ];

  static const List<String> difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  static const List<String> forumTopics = [
    'General',
    'Question',
    'Practice Tips',
    'Introductions',
    'Resources',
  ];

  /// Max video size the admin uploader accepts, matching Cloudinary's free
  /// tier single-file limit.
  static const int maxVideoBytes = 100 * 1024 * 1024;

  /// Max size for the optional image on a quiz question. Well under
  /// Cloudinary's limit — a photo this large is already far more than a
  /// handshape reference needs, and it keeps the quiz quick to load.
  static const int maxQuestionImageBytes = 10 * 1024 * 1024;
}
