import '../../core/constants.dart';
import '../../models/forum_post.dart';
import '../../providers/forum_providers.dart' show mentionsChannel;

/// A channel in the community rail.
class Channel {
  const Channel({required this.topic});

  /// The stored tag, e.g. `Practice Tips`.
  final String topic;

  /// How it reads in the rail: `#practice-tips`.
  String get slug => slugFor(topic);
  String get label => '#$slug';

  static String slugFor(String topic) => topic
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static final all = [
    for (final t in AppConstants.forumTopics) Channel(topic: t),
  ];
}

/// Posts in one channel, newest first (the stream is already sorted).
List<ForumPost> postsIn(List<ForumPost> posts, String? topic) => topic == null
    ? posts
    : posts.where((p) => p.topics.contains(topic)).toList();

/// Posts that name [uid].
List<ForumPost> postsMentioning(List<ForumPost> posts, String? uid) =>
    uid == null ? const [] : posts.where((p) => p.mentions(uid)).toList();

/// How many posts in [topic] have landed since the reader last opened it.
///
/// Your own posts never count: arriving at a channel to be told you have one
/// unread message that you wrote yourself is noise, not news. A channel never
/// seen before counts everything, so a new learner sees what is waiting rather
/// than a silent rail.
int unreadIn({
  required List<ForumPost> posts,
  required String topic,
  required DateTime? lastSeen,
  required String? viewerUid,
}) {
  var n = 0;
  for (final p in posts) {
    if (!p.topics.contains(topic)) continue;
    if (p.authorId == viewerUid) continue;
    final at = p.createdAt;
    // A post whose server timestamp hasn't resolved yet is a moment old, so it
    // counts as new.
    if (lastSeen != null && at != null && !at.isAfter(lastSeen)) continue;
    n++;
  }
  return n;
}

/// A title derived from a chat message's text.
///
/// The composer at the foot of a channel is a single box, the way a chat client
/// is — but a post document needs a title, and the security rules enforce one
/// between 1 and 120 characters. Rather than force a second field that nobody
/// in a chat wants to fill in, the first sentence or line becomes the title and
/// the whole message stays as the body.
///
/// Pure, so the truncation rules are testable on their own.
String titleFromMessage(String body) {
  final text = body.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return 'Message';

  // Prefer a natural break: the first line, or the first sentence.
  final firstLine = body.trim().split('\n').first.trim();
  var candidate = firstLine.isEmpty ? text : firstLine;

  final sentenceEnd = RegExp(r'[.!?](\s|$)').firstMatch(candidate);
  if (sentenceEnd != null && sentenceEnd.start >= 8) {
    candidate = candidate.substring(0, sentenceEnd.start + 1);
  }

  if (candidate.length <= 120) return candidate;

  // Cut on a word boundary so the title doesn't end mid-word.
  final cut = candidate.substring(0, 120);
  final lastSpace = cut.lastIndexOf(' ');
  final trimmed = lastSpace > 40 ? cut.substring(0, lastSpace) : cut;
  return '${trimmed.trimRight()}…';
}

/// Which channel a message typed in [selected] should land in.
///
/// The firehose and the mentions view are both readable but not writable
/// destinations, so a message sent from either goes to General.
String targetChannel(String? selected) =>
    (selected == null || selected == mentionsChannel) ? 'General' : selected;
