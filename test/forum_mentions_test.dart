import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/models/forum_post.dart';
import 'package:signals/providers/forum_providers.dart' show mentionsChannel;
import 'package:signals/screens/forum/channels.dart';
import 'package:signals/screens/forum/mentions.dart';
import 'package:signals/widgets/mention_field.dart';

const _ada = ForumPerson(uid: 'u-ada', name: 'Ada Lovelace');
const _bo = ForumPerson(uid: 'u-bo', name: 'Bo');
const _people = [_ada, _bo];

ForumPost _post(
  String id, {
  List<String> topics = const ['General'],
  String author = 'u1',
  DateTime? at,
  List<String> mentioned = const [],
}) => ForumPost(
  id: id,
  authorId: author,
  authorName: 'Someone',
  title: 'Title $id',
  body: 'Body',
  topics: topics,
  createdAt: at,
  mentionedUids: mentioned,
);

void main() {
  _titleTests();

  group('handles', () {
    test('a handle is the first name, stripped and lowercased', () {
      expect(_ada.handle, 'ada');
      expect(_ada.fullHandle, 'adalovelace');
      expect(ForumPerson.handleFor("D'Arcy O'Neill"), 'darcy');
    });
  });

  group('parsing mentions', () {
    test('picks up each distinct handle once', () {
      expect(parseMentions('@ada and @bo and @ada again'), ['ada', 'bo']);
    });

    test('an email address is not two mentions', () {
      // The @ in ada@example.com does not start a word.
      expect(parseMentions('mail ada@example.com'), isEmpty);
    });

    test('punctuation after a handle ends it', () {
      expect(parseMentions('@ada, did you practise?'), ['ada']);
    });
  });

  group('resolving mentions', () {
    test('maps handles to uids', () {
      expect(resolveMentions('thanks @ada!', _people), ['u-ada']);
    });

    test('the full name works when first names would collide', () {
      expect(resolveMentions('@adalovelace', _people), ['u-ada']);
    });

    test('a handle nobody owns resolves to nobody', () {
      expect(resolveMentions('@nobody here', _people), isEmpty);
    });

    test('a shared first name notifies everyone who answers to it', () {
      // Picking one at random would be worse than telling both.
      const twins = [
        ForumPerson(uid: 'u1', name: 'Sam Okafor'),
        ForumPerson(uid: 'u2', name: 'Sam Reyes'),
      ];
      expect(resolveMentions('@sam', twins), ['u1', 'u2']);
    });
  });

  group('rendering spans', () {
    test('only known handles are marked up', () {
      final spans = mentionSpans('hi @ada and @ghost', people: _people);
      expect(spans.where((s) => s.isMention).map((s) => s.text), ['@ada']);
      // The unknown handle survives as plain text rather than disappearing.
      expect(spans.map((s) => s.text).join(), 'hi @ada and @ghost');
    });

    test('the reader learns which mention is theirs', () {
      final spans = mentionSpans(
        '@ada @bo',
        people: _people,
        viewerUid: 'u-bo',
      );
      final mine = spans
          .where((s) => s.isMention && s.isYou)
          .map((s) => s.text);
      expect(mine, ['@bo']);
    });
  });

  group('composer autocomplete', () {
    ({int start, String query})? active(String text) =>
        MentionSuggestions.activeMention(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );

    test('offers everyone right after a bare @', () {
      expect(active('hello @')?.query, '');
    });

    test('narrows as the handle is typed', () {
      expect(active('hello @ad')?.query, 'ad');
    });

    test('stops once the handle is finished', () {
      expect(active('hello @ada and'), isNull);
    });

    test('does not fire inside an email address', () {
      expect(active('ada@exa'), isNull);
    });
  });

  group('channels', () {
    test('a topic becomes a slug', () {
      expect(Channel(topic: 'Practice Tips').label, '#practice-tips');
      expect(Channel(topic: 'General').label, '#general');
    });

    test('a post in two channels appears in both', () {
      final posts = [
        _post('a', topics: ['General', 'Question']),
      ];
      expect(postsIn(posts, 'General').length, 1);
      expect(postsIn(posts, 'Question').length, 1);
      expect(postsIn(posts, 'Resources'), isEmpty);
      expect(postsIn(posts, null).length, 1);
    });

    test('legacy posts with a single topic still land in a channel', () {
      // Written before channels existed: `topic`, no `topics`.
      final post = ForumPost(
        id: 'old',
        authorId: 'u1',
        authorName: 'Someone',
        title: 'Old',
        body: 'Body',
        topics: const ['Resources'],
      );
      expect(post.topic, 'Resources');
      expect(postsIn([post], 'Resources').length, 1);
    });
  });

  group('unread counts', () {
    final now = DateTime(2026, 10, 2, 12);

    test('a never-opened channel counts everything', () {
      final posts = [
        _post('a', at: now.subtract(const Duration(days: 3))),
        _post('b', at: now.subtract(const Duration(days: 1))),
      ];
      expect(
        unreadIn(
          posts: posts,
          topic: 'General',
          lastSeen: null,
          viewerUid: 'me',
        ),
        2,
      );
    });

    test('only what landed since the last visit', () {
      final posts = [
        _post('old', at: now.subtract(const Duration(days: 3))),
        _post('new', at: now.subtract(const Duration(hours: 1))),
      ];
      expect(
        unreadIn(
          posts: posts,
          topic: 'General',
          lastSeen: now.subtract(const Duration(days: 1)),
          viewerUid: 'me',
        ),
        1,
      );
    });

    test('your own messages are never unread to you', () {
      final posts = [_post('mine', author: 'me', at: now)];
      expect(
        unreadIn(
          posts: posts,
          topic: 'General',
          lastSeen: null,
          viewerUid: 'me',
        ),
        0,
      );
    });

    test('other channels do not leak into the count', () {
      final posts = [
        _post('q', topics: ['Question'], at: now),
      ];
      expect(
        unreadIn(
          posts: posts,
          topic: 'General',
          lastSeen: null,
          viewerUid: 'me',
        ),
        0,
      );
    });
  });

  group('mentions view', () {
    test('shows only posts naming the reader', () {
      final posts = [
        _post('a', mentioned: ['me']),
        _post('b', mentioned: ['someone-else']),
        _post('c'),
      ];
      expect(postsMentioning(posts, 'me').map((p) => p.id), ['a']);
      expect(postsMentioning(posts, null), isEmpty);
    });
  });

  group('forum people', () {
    test('de-duplicates by uid and leaves the reader out', () {
      final posts = [
        ForumPost(
          id: 'a',
          authorId: 'u-ada',
          authorName: 'Ada Lovelace',
          title: 't',
          body: 'b',
        ),
        ForumPost(
          id: 'b',
          authorId: 'u-ada',
          authorName: 'Ada Lovelace',
          title: 't',
          body: 'b',
        ),
        ForumPost(
          id: 'c',
          authorId: 'me',
          authorName: 'Me',
          title: 't',
          body: 'b',
        ),
      ];
      final people = forumPeople(posts: posts, excludeUid: 'me');
      expect(people.map((p) => p.uid), ['u-ada']);
    });
  });
}

/// The composer is a single box, so a post's title has to come out of the
/// message itself — and the security rules reject an empty one or anything
/// over 120 characters.
void _titleTests() {
  group('title from a chat message', () {
    test('a short message is its own title', () {
      expect(titleFromMessage('Hello everyone'), 'Hello everyone');
    });

    test('the first sentence wins when there are several', () {
      expect(
        titleFromMessage('I learned the alphabet. It took three weeks.'),
        'I learned the alphabet.',
      );
    });

    test('the first line wins over the rest', () {
      expect(
        titleFromMessage('Quick question\nHow do I sign Thursday?'),
        'Quick question',
      );
    });

    test('an early full stop is not treated as the end of a sentence', () {
      // "Hi." would make a uselessly short title, so the cut needs a minimum.
      expect(titleFromMessage('Hi. I am new here'), 'Hi. I am new here');
    });

    test('a long message is cut on a word boundary and never exceeds 120', () {
      final body = List.filled(60, 'word').join(' ');
      final title = titleFromMessage(body);
      expect(title.length, lessThanOrEqualTo(121)); // 120 plus the ellipsis
      expect(title, endsWith('…'));
      expect(title, isNot(contains('wor…')));
    });

    test('whitespace alone still produces a usable title', () {
      // The rules reject an empty title, so this must never return ''.
      expect(titleFromMessage('   '), 'Message');
      expect(titleFromMessage('').isNotEmpty, isTrue);
    });
  });

  group('where a message lands', () {
    test('a channel takes its own messages', () {
      expect(targetChannel('Resources'), 'Resources');
    });

    test('the firehose and mentions are readable, not writable', () {
      // Neither is a real channel, so a message typed there goes to General.
      expect(targetChannel(null), 'General');
      expect(targetChannel(mentionsChannel), 'General');
    });
  });
}
