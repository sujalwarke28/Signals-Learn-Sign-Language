import '../../models/forum_post.dart';

/// Someone who has posted or replied in the community, and can therefore be
/// mentioned.
///
/// The mentionable set is deliberately "people who have spoken here" rather
/// than "every user": the security rules restrict `users/{uid}` reads to the
/// owner and admins, so a learner has no directory to look anybody up in. Post
/// and reply documents already carry `authorId` and `authorName`, so the
/// community can address itself without widening what anyone can read.
class ForumPerson {
  const ForumPerson({required this.uid, required this.name});

  final String uid;
  final String name;

  /// What you type after the @. First name, lowercased, punctuation removed —
  /// "Ada Lovelace" is `@ada`.
  String get handle => handleFor(name);

  /// The whole name compacted, so `@adalovelace` also finds her when two
  /// people share a first name.
  String get fullHandle => name.toLowerCase().replaceAll(_strip, '');

  static final _strip = RegExp(r'[^a-z0-9]');

  static String handleFor(String name) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.toLowerCase().replaceAll(_strip, '');
  }
}

/// Everyone who has written something, newest contribution first, de-duplicated
/// by uid.
List<ForumPerson> forumPeople({
  required List<ForumPost> posts,
  List<ForumReply> replies = const [],
  String? excludeUid,
}) {
  final seen = <String, ForumPerson>{};
  void add(String uid, String name) {
    if (uid.isEmpty || uid == excludeUid) return;
    if (name.trim().isEmpty) return;
    seen.putIfAbsent(uid, () => ForumPerson(uid: uid, name: name.trim()));
  }

  for (final p in posts) {
    add(p.authorId, p.authorName);
  }
  for (final r in replies) {
    add(r.authorId, r.authorName);
  }
  return seen.values.toList();
}

/// The `@handle` tokens written in [body], lowercased and de-duplicated.
List<String> parseMentions(String body) {
  final out = <String>{};
  for (final m in _mentionPattern.allMatches(body)) {
    final handle = m.group(1)!.toLowerCase();
    if (handle.isNotEmpty) out.add(handle);
  }
  return out.toList();
}

/// An @ only starts a mention at a word boundary, so an email address does not
/// turn half of itself into one.
final _mentionPattern = RegExp(r'(?<![\w@])@([a-zA-Z0-9_.-]{1,30})');

/// Which uids a body actually addresses.
///
/// A handle shared by two people resolves to both. That is rare, and notifying
/// one person at random would be worse than notifying both.
List<String> resolveMentions(String body, List<ForumPerson> people) {
  final handles = parseMentions(body).toSet();
  if (handles.isEmpty) return const [];
  return [
    for (final p in people)
      if (handles.contains(p.handle) || handles.contains(p.fullHandle)) p.uid,
  ];
}

/// A run of body text, flagged as a mention or not, for rendering.
class MentionSpan {
  const MentionSpan({
    required this.text,
    required this.isMention,
    this.isYou = false,
  });

  final String text;
  final bool isMention;

  /// True when the mention resolves to the person reading it.
  final bool isYou;
}

/// Splits [body] so an @mention of a real participant can be drawn differently
/// from the words around it.
///
/// Unknown handles stay plain text: highlighting `@nobody` would promise a
/// notification that was never sent.
List<MentionSpan> mentionSpans(
  String body, {
  required List<ForumPerson> people,
  String? viewerUid,
}) {
  if (body.isEmpty) return const [];

  final byHandle = <String, List<ForumPerson>>{};
  for (final p in people) {
    byHandle.putIfAbsent(p.handle, () => []).add(p);
    byHandle.putIfAbsent(p.fullHandle, () => []).add(p);
  }

  final spans = <MentionSpan>[];
  var cursor = 0;
  for (final m in _mentionPattern.allMatches(body)) {
    final matched = byHandle[m.group(1)!.toLowerCase()];
    if (matched == null || matched.isEmpty) continue;

    if (m.start > cursor) {
      spans.add(
        MentionSpan(text: body.substring(cursor, m.start), isMention: false),
      );
    }
    spans.add(
      MentionSpan(
        text: body.substring(m.start, m.end),
        isMention: true,
        isYou: viewerUid != null && matched.any((p) => p.uid == viewerUid),
      ),
    );
    cursor = m.end;
  }
  if (cursor < body.length) {
    spans.add(MentionSpan(text: body.substring(cursor), isMention: false));
  }
  return spans;
}
