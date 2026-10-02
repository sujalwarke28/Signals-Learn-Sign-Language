import '../models/lesson.dart';
import '../models/question.dart';

/// Demo content for a fresh Firestore database.
///
/// ## About the videos
/// Every seeded lesson points at a short public clip from Cloudinary's `demo`
/// cloud and is flagged `isPlaceholderVideo: true`, which makes the app show a
/// "this clip stands in for real footage" notice on the lesson. They exist so the
/// player, the watch-progress tracking and the quiz unlock can be demonstrated
/// end to end. Replace them by publishing real lessons through the admin screen.
///
/// ## About the quiz content
/// The questions are **American Sign Language** (ASL), written from general
/// knowledge of the language — handshapes, movement, and how the alphabet and
/// number systems work. They are not machine-verified against an authoritative
/// dictionary, so treat them as a solid demo rather than as teaching material of
/// record. ASL is one-handed for fingerspelling, which is why several questions
/// contrast it with two-handed systems such as BSL.
class SeedData {
  const SeedData._();

  /// Short placeholder clips (12–20s each, so a demo watch-through is quick).
  static const _dog = 'https://res.cloudinary.com/demo/video/upload/dog.mp4';
  static const _turtle =
      'https://res.cloudinary.com/demo/video/upload/sea_turtle.mp4';
  static const _horses =
      'https://res.cloudinary.com/demo/video/upload/snow_horses.mp4';
  static const _sample =
      'https://res.cloudinary.com/demo/video/upload/cld-sample-video.mp4';
  static const _dance =
      'https://res.cloudinary.com/demo/video/upload/samples/dance-2.mp4';

  static String? _poster(String videoUrl) =>
      videoUrl.replaceFirst(RegExp(r'\.mp4$'), '.jpg');

  /// The lessons, in the order learners see them.
  static List<SeedLesson> lessons() => [
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'The ASL Alphabet: A to F',
            description:
                'Your first six letters. ASL fingerspells with one hand, so each '
                'letter is a single handshape you can hold still — start by getting '
                'A, B and C crisp before adding D, E and F.',
            category: 'Alphabet',
            durationSeconds: 13,
            videoUrl: _dog,
            thumbnailUrl: _poster(_dog),
            order: 0,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'How many hands does the ASL alphabet use to fingerspell?',
              options: ['One', 'Two', 'Either, they mean different things', 'Three'],
              correctIndex: 0,
              explanation:
                  'ASL fingerspelling is one-handed. British Sign Language is the '
                  'well-known two-handed system — the two alphabets are unrelated.',
            ),
            SeedQuestion(
              prompt: 'Which description matches the ASL letter A?',
              options: [
                'A closed fist with the thumb resting alongside the index finger',
                'A flat open hand with fingers spread wide',
                'Index and middle finger extended in a V',
                'A curved hand shaped like a hook',
              ],
              correctIndex: 0,
              explanation:
                  'A is a fist with the thumb up the side of the hand, not tucked '
                  'inside it.',
            ),
            SeedQuestion(
              prompt: 'The letter B is signed with…',
              options: [
                'A flat hand, fingers together and pointing up, thumb folded across the palm',
                'A fist with the thumb between the index and middle finger',
                'Index finger pointing forward, other fingers curled',
                'All fingers curved to touch the thumb',
              ],
              correctIndex: 0,
              explanation:
                  'B is a flat "paddle": fingers straight and together, thumb tucked '
                  'in across the palm.',
            ),
            SeedQuestion(
              prompt: 'Why is C one of the easiest letters for beginners?',
              options: [
                'The hand literally curves into the shape of the letter C',
                'It is signed with both hands, so it is hard to get wrong',
                'It requires no handshape at all, only a movement',
                'It is the only letter signed at shoulder height',
              ],
              correctIndex: 0,
              explanation:
                  'Several ASL letters are iconic — C, O and L visibly resemble the '
                  'printed letter, which makes them quick to learn.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'The ASL Alphabet: G to N',
            description:
                'The middle of the alphabet, where handshapes start to look alike. '
                'This lesson focuses on the pairs learners mix up most — M and N, '
                'and K versus P.',
            category: 'Alphabet',
            durationSeconds: 15,
            videoUrl: _turtle,
            thumbnailUrl: _poster(_turtle),
            order: 1,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'What distinguishes the letter M from the letter N?',
              options: [
                'M has the thumb under three fingers, N has it under two',
                'M is signed higher than N',
                'M moves, N is held still',
                'M uses the left hand, N uses the right',
              ],
              correctIndex: 0,
              explanation:
                  'Both tuck the thumb beneath the fingers; the number of fingers '
                  'covering it is the whole difference — three for M, two for N.',
            ),
            SeedQuestion(
              prompt: 'K and P share a handshape. What changes between them?',
              options: [
                'The orientation — K points up, P points down',
                'The number of fingers extended',
                'P is fingerspelled with two hands',
                'K includes a small circular movement',
              ],
              correctIndex: 0,
              explanation:
                  'Same configuration, rotated. Palm orientation is a real '
                  'distinguishing feature in ASL, not a stylistic choice.',
            ),
            SeedQuestion(
              prompt: 'The letter I is made by extending which finger?',
              options: ['The pinky', 'The index finger', 'The thumb', 'The middle finger'],
              correctIndex: 0,
              explanation:
                  'I is a fist with only the pinky up. Add the thumb and you have the '
                  'handshape for "I love you".',
            ),
            SeedQuestion(
              prompt: 'When would a fluent signer fingerspell a word instead of signing it?',
              options: [
                'For names, places and words with no established sign',
                'Whenever the conversation is formal',
                'Only when teaching children',
                'Fingerspelling is never used in real conversation',
              ],
              correctIndex: 0,
              explanation:
                  'Fingerspelling fills gaps — proper nouns, brand names, technical '
                  'terms — rather than replacing signs.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Letters That Move: J and Z',
            description:
                'Almost every ASL letter is a still handshape. Two are not. J and Z '
                'trace their own shape in the air, and getting the path right is what '
                'makes them readable.',
            category: 'Alphabet',
            durationSeconds: 12,
            videoUrl: _horses,
            thumbnailUrl: _poster(_horses),
            order: 2,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'Which two letters of the ASL alphabet include a movement?',
              options: ['J and Z', 'A and E', 'M and N', 'Q and G'],
              correctIndex: 0,
              explanation:
                  'J and Z are the two moving letters — everything else is a held '
                  'handshape.',
            ),
            SeedQuestion(
              prompt: 'How is the letter J formed?',
              options: [
                'Start with the pinky extended, then trace the hook of a J',
                'Trace a straight line downward with the index finger',
                'Draw a full circle with a flat hand',
                'Tap the thumb against the pinky twice',
              ],
              correctIndex: 0,
              explanation:
                  'J begins from the I handshape (pinky out) and draws the letter\'s '
                  'curve.',
            ),
            SeedQuestion(
              prompt: 'The letter Z is traced with which finger?',
              options: ['The index finger', 'The pinky', 'The thumb', 'A flat whole hand'],
              correctIndex: 0,
              explanation:
                  'The index finger draws the three strokes of a Z in the air.',
            ),
            SeedQuestion(
              prompt: 'Besides handshape, which features carry meaning in ASL signs?',
              options: [
                'Movement, location, palm orientation and facial expression',
                'Only how fast the hands move',
                'Only where the hands are placed',
                'Nothing else — handshape alone is enough',
              ],
              correctIndex: 0,
              explanation:
                  'ASL signs are built from several simultaneous parameters. Change '
                  'one and you can change the word entirely.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Numbers 1 to 10',
            description:
                'Counting in ASL has a quirk that surprises beginners: the palm faces '
                'you for the small numbers, and 6 through 9 are made by touching the '
                'thumb to a specific fingertip.',
            category: 'Numbers',
            durationSeconds: 15,
            videoUrl: _sample,
            thumbnailUrl: _poster(_sample),
            order: 3,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'When counting 1 to 5 in ASL, which way does the palm normally face?',
              options: [
                'Toward the signer',
                'Toward the person being spoken to',
                'Straight down at the floor',
                'It alternates with every number',
              ],
              correctIndex: 0,
              explanation:
                  'Cardinal numbers 1–5 are signed palm-in. Turning the palm outward '
                  'is how you show numbers in other contexts, such as some addresses '
                  'and phone numbers.',
            ),
            SeedQuestion(
              prompt: 'The number 6 is made by touching the thumb to which finger?',
              options: ['The pinky', 'The index finger', 'The middle finger', 'The ring finger'],
              correctIndex: 0,
              explanation:
                  'Six through nine walk inward: pinky for 6, ring for 7, middle for '
                  '8, index for 9.',
            ),
            SeedQuestion(
              prompt: 'Following that pattern, the number 9 touches the thumb to…',
              options: ['The index finger', 'The pinky', 'The middle finger', 'The ring finger'],
              correctIndex: 0,
              explanation:
                  'The sequence ends at the index finger, so 9 looks a little like an '
                  'F handshape.',
            ),
            SeedQuestion(
              prompt: 'Which number is signed with a closed fist that twists or shakes?',
              options: ['10', '4', '7', '2'],
              correctIndex: 0,
              explanation:
                  'Ten is a fist with the thumb up, given a small shake — distinct '
                  'from the letter A, which is held still.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Counting Past Ten',
            description:
                'Numbers above ten follow patterns rather than rote memorisation. '
                'Learn the pattern once and 11 through 19 comes almost free.',
            category: 'Numbers',
            durationSeconds: 19,
            videoUrl: _dance,
            thumbnailUrl: _poster(_dance),
            order: 4,
            difficulty: 'Intermediate',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'How are the numbers 11 and 12 typically formed?',
              options: [
                'A flicking motion of one or two fingers from a closed hand',
                'By signing 1 then 1, and 1 then 2',
                'With both hands held side by side',
                'By tracing the digits in the air',
              ],
              correctIndex: 0,
              explanation:
                  'Eleven flicks the index finger up from a fist; twelve flicks index '
                  'and middle together. They are single signs, not two digits.',
            ),
            SeedQuestion(
              prompt: 'What is the general pattern for the numbers 16 through 19?',
              options: [
                'The handshape for 6–9 with a small twisting movement',
                'Signing 1 followed by 6, 7, 8 or 9',
                'Both hands showing 8 and the remainder',
                'A flat hand tapped the matching number of times',
              ],
              correctIndex: 0,
              explanation:
                  'They build on 6–9 with an added twist, which is why the 6–9 '
                  'handshapes are worth drilling first.',
            ),
            SeedQuestion(
              prompt: 'Why does number formation in ASL sometimes change with context?',
              options: [
                'Ages, times, prices and phone numbers each have their own conventions',
                'It varies randomly between signers',
                'Numbers above 10 have no standard form',
                'Only regional dialects differ',
              ],
              correctIndex: 0,
              explanation:
                  'Numeral incorporation is real grammar — AGE-5 and 5-O\'CLOCK are '
                  'not produced the same way as a bare "five".',
            ),
            SeedQuestion(
              prompt: 'A signer holds up a 3 handshape near their head while saying an age. This is an example of…',
              options: [
                'Numeral incorporation',
                'Fingerspelling',
                'A non-manual marker',
                'Classifier movement',
              ],
              correctIndex: 0,
              explanation:
                  'Numeral incorporation merges a number into another sign\'s location '
                  'or movement, rather than signing the two separately.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Hello and Goodbye',
            description:
                'The first exchange you will ever have in ASL. Greetings are also '
                'where facial expression starts doing real grammatical work, not just '
                'conveying mood.',
            category: 'Greetings',
            durationSeconds: 13,
            videoUrl: _dog,
            thumbnailUrl: _poster(_dog),
            order: 5,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'HELLO is commonly signed by…',
              options: [
                'Bringing a flat hand from near the forehead outward, like a relaxed salute',
                'Tapping the chest twice with a fist',
                'Waving both hands above the head',
                'Touching the chin and moving down',
              ],
              correctIndex: 0,
              explanation:
                  'It resembles a casual salute moving away from the head. A plain '
                  'wave is also perfectly normal and very common.',
            ),
            SeedQuestion(
              prompt: 'What role do raised eyebrows play in ASL?',
              options: [
                'They mark a yes/no question',
                'They show the signer is unsure',
                'They indicate past tense',
                'They have no grammatical role',
              ],
              correctIndex: 0,
              explanation:
                  'Raised brows mark yes/no questions; furrowed brows go with '
                  'wh-questions. These non-manual markers are grammar, and a sentence '
                  'can be wrong without them.',
            ),
            SeedQuestion(
              prompt: 'Where does eye contact sit in ASL conversation?',
              options: [
                'It is essential — breaking it signals you have stopped attending',
                'It is considered rude and generally avoided',
                'It matters only when fingerspelling',
                'It is optional and carries no meaning',
              ],
              correctIndex: 0,
              explanation:
                  'You cannot receive a signed message without watching the signer, '
                  'so sustained eye contact is both practical and expected.',
            ),
            SeedQuestion(
              prompt: 'Which statement about ASL is true?',
              options: [
                'It is its own language with grammar unlike English',
                'It is English rendered word-for-word with the hands',
                'It is universal across all countries',
                'It has no formal grammar',
              ],
              correctIndex: 0,
              explanation:
                  'ASL is a full natural language, often using topic-comment order. '
                  'It is not signed English, and sign languages differ by country.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'What\'s Your Name?',
            description:
                'Introduce yourself and ask someone else. This is also where you meet '
                'name signs — the personal signs used within the Deaf community '
                'instead of fingerspelling a name every time.',
            category: 'Greetings',
            durationSeconds: 15,
            videoUrl: _turtle,
            thumbnailUrl: _poster(_turtle),
            order: 6,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'The sign NAME is made by…',
              options: [
                'Tapping two extended fingers of each hand across one another',
                'Pointing at the other person twice',
                'Drawing a circle on the chest',
                'Touching the forehead with a flat hand',
              ],
              correctIndex: 0,
              explanation:
                  'Two "H" handshapes (index and middle extended) cross and tap — like '
                  'a small X made of fingers.',
            ),
            SeedQuestion(
              prompt: 'A "name sign" is…',
              options: [
                'A personal sign given to someone, usually by a Deaf person',
                'The fingerspelled version of a name',
                'A sign used only for famous people',
                'The sign for the word "name"',
              ],
              correctIndex: 0,
              explanation:
                  'Name signs are conferred within the Deaf community rather than '
                  'chosen for yourself — that convention matters culturally.',
            ),
            SeedQuestion(
              prompt: 'How would you typically ask "What is your name?" in ASL word order?',
              options: [
                'NAME YOU — with a questioning facial expression',
                'WHAT IS YOUR NAME, signed word for word',
                'YOU NAME WHAT IS',
                'Fingerspell the whole question',
              ],
              correctIndex: 0,
              explanation:
                  'ASL is economical and relies on non-manual markers. English '
                  'function words like "is" and "your" usually have no separate sign '
                  'here.',
            ),
            SeedQuestion(
              prompt: 'Why do learners fingerspell their own name when meeting someone new?',
              options: [
                'Because they will not have a name sign until one is given to them',
                'Because name signs are considered impolite',
                'Because fingerspelling is faster than any sign',
                'Because names cannot be signed at all',
              ],
              correctIndex: 0,
              explanation:
                  'Fingerspelling is the default until a name sign exists — which is '
                  'also good fingerspelling practice.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Please, Thank You, Sorry',
            description:
                'Three signs that carry a conversation a surprisingly long way. All '
                'three are made on or near the body, and two of them are easy to '
                'confuse until you watch the movement.',
            category: 'Common Phrases',
            durationSeconds: 12,
            videoUrl: _horses,
            thumbnailUrl: _poster(_horses),
            order: 7,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'PLEASE is signed with…',
              options: [
                'A flat hand circling on the chest',
                'A fist tapping the chin',
                'Both hands sweeping outward',
                'An index finger drawn across the palm',
              ],
              correctIndex: 0,
              explanation:
                  'Flat hand, circular rub on the chest. SORRY is also on the chest '
                  'but uses a fist — the handshape is what separates them.',
            ),
            SeedQuestion(
              prompt: 'THANK YOU begins at which location?',
              options: [
                'The chin or lips, moving forward and down',
                'The forehead, moving up',
                'The chest, moving in a circle',
                'The shoulder, moving across the body',
              ],
              correctIndex: 0,
              explanation:
                  'A flat hand starts at the chin and extends toward the person you '
                  'are thanking.',
            ),
            SeedQuestion(
              prompt: 'What separates SORRY from PLEASE?',
              options: [
                'SORRY uses a closed fist, PLEASE uses a flat hand',
                'SORRY is signed at the forehead',
                'SORRY uses both hands',
                'They are identical and context decides',
              ],
              correctIndex: 0,
              explanation:
                  'Same place, same circular movement, different handshape — a good '
                  'illustration of how handshape alone can change a word.',
            ),
            SeedQuestion(
              prompt: 'Why is facial expression especially important for courtesy signs?',
              options: [
                'It conveys sincerity and intensity, which the hands alone do not',
                'It replaces the need for the sign entirely',
                'It marks the sign as plural',
                'It indicates which hand is dominant',
              ],
              correctIndex: 0,
              explanation:
                  'A flat face on an apology reads as insincere in ASL just as a flat '
                  'voice would in speech.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Family Signs',
            description:
                'Family vocabulary reveals one of ASL\'s neat internal patterns: '
                'where on the face a sign is made tells you something about who it '
                'refers to.',
            category: 'Family',
            durationSeconds: 15,
            videoUrl: _sample,
            thumbnailUrl: _poster(_sample),
            order: 8,
            difficulty: 'Intermediate',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'MOTHER is signed by touching the thumb of an open hand to which location?',
              options: ['The chin', 'The forehead', 'The cheek', 'The chest'],
              correctIndex: 0,
              explanation:
                  'Lower face for female relatives, upper face for male — MOTHER at '
                  'the chin, FATHER at the forehead.',
            ),
            SeedQuestion(
              prompt: 'Following that same pattern, FATHER is signed at…',
              options: ['The forehead', 'The chin', 'The shoulder', 'The chest'],
              correctIndex: 0,
              explanation:
                  'The gender pattern is consistent enough across family signs to be '
                  'a genuine learning shortcut.',
            ),
            SeedQuestion(
              prompt: 'What does this high/low pattern tell you about ASL vocabulary?',
              options: [
                'Location is a meaningful building block, not an arbitrary choice',
                'Signs are placed wherever is most comfortable',
                'Only family signs have fixed locations',
                'Location changes with regional dialect only',
              ],
              correctIndex: 0,
              explanation:
                  'Location is one of the parameters that distinguishes one sign from '
                  'another, alongside handshape, movement and orientation.',
            ),
            SeedQuestion(
              prompt: 'How are signs like BROTHER and SISTER often built?',
              options: [
                'By combining the gender location with another element',
                'By fingerspelling them in full',
                'By pointing to family members present',
                'By signing FAMILY twice',
              ],
              correctIndex: 0,
              explanation:
                  'Compounding is common: the gendered location plus a second '
                  'component produces the specific relative.',
            ),
          ],
        ),
        SeedLesson(
          lesson: Lesson(
            id: '',
            title: 'Colors',
            description:
                'Most color signs are the letter the color starts with, given a small '
                'shake. Two of them break the rule — and those are the ones worth '
                'memorising properly.',
            category: 'Colors',
            durationSeconds: 19,
            videoUrl: _dance,
            thumbnailUrl: _poster(_dance),
            order: 9,
            difficulty: 'Beginner',
            isPlaceholderVideo: true,
          ),
          questions: [
            SeedQuestion(
              prompt: 'How are BLUE, GREEN and YELLOW typically signed?',
              options: [
                'The matching letter handshape, shaken or twisted',
                'By pointing at something of that color',
                'By fingerspelling the whole word',
                'With both hands tracing a circle',
              ],
              correctIndex: 0,
              explanation:
                  'Initialised signs: the B, G and Y handshapes with a small shake. '
                  'Learn the alphabet and a chunk of the color vocabulary comes with '
                  'it.',
            ),
            SeedQuestion(
              prompt: 'RED is signed by…',
              options: [
                'Brushing the index finger down across the lips',
                'Shaking an R handshape',
                'Tapping the cheek twice',
                'Drawing a circle on the palm',
              ],
              correctIndex: 0,
              explanation:
                  'RED is not initialised — it references the color of the lips, which '
                  'is why it looks nothing like the letter R.',
            ),
            SeedQuestion(
              prompt: 'BLACK is signed by drawing the index finger across…',
              options: ['The forehead or eyebrow', 'The palm', 'The chin', 'The chest'],
              correctIndex: 0,
              explanation:
                  'A single stroke across the brow. Like RED, it is motivated by the '
                  'body rather than by a letter.',
            ),
            SeedQuestion(
              prompt: 'What is an "initialised sign"?',
              options: [
                'A sign that uses the handshape of the word\'s first letter',
                'A sign invented by a beginner',
                'A sign that must be fingerspelled first',
                'A sign that only works in one region',
              ],
              correctIndex: 0,
              explanation:
                  'Initialisation borrows a fingerspelled letter into a sign. It is '
                  'common in color and name vocabulary, and much rarer in core '
                  'everyday signs.',
            ),
          ],
        ),
      ];

  /// Demo forum threads. Each has at least one reply.
  static List<SeedPost> posts() => const [
        SeedPost(
          title: 'M and N look identical to me — any tips?',
          body:
              'I have been drilling the alphabet for a week and I still cannot tell '
              'M from N when someone else fingerspells quickly. Does it get easier or '
              'am I missing something obvious?',
          topic: 'Question',
          authorName: 'Priya',
          replies: [
            SeedReply(
              authorName: 'Daniel',
              body:
                  'Count the fingers over the thumb — three for M, two for N. Once I '
                  'started looking at the thumb instead of the whole hand it clicked '
                  'in about two days.',
            ),
            SeedReply(
              authorName: 'Aisha',
              body:
                  'It genuinely gets easier. Receptive fingerspelling lags behind '
                  'producing it for everyone, so do not read it as a bad sign.',
            ),
          ],
        ),
        SeedPost(
          title: 'Practice routine that actually stuck for me',
          body:
              'Ten minutes every morning, always the same order: alphabet, numbers '
              '1-10, then whatever lesson I did last. Boring, but it is the first '
              'routine I have kept for more than two weeks.',
          topic: 'Practice Tips',
          authorName: 'Daniel',
          replies: [
            SeedReply(
              authorName: 'Priya',
              body:
                  'Stealing this. I keep trying to do 40 minutes on a Sunday and then '
                  'nothing all week, which obviously does not work.',
            ),
          ],
        ),
        SeedPost(
          title: 'New here — starting from zero',
          body:
              'Hi everyone. I am learning because a colleague is Deaf and I would '
              'like to manage more than a wave. Starting with the Alphabet lessons '
              'today. Any advice for the first month?',
          topic: 'Introductions',
          authorName: 'Aisha',
          replies: [
            SeedReply(
              authorName: 'Maya',
              body:
                  'Welcome! Honest advice: spend time on facial expression early. I '
                  'ignored it for months and my signing looked flat and was hard to '
                  'read.',
            ),
          ],
        ),
        SeedPost(
          title: 'Is ASL the same as British Sign Language?',
          body:
              'A friend told me sign language is universal. The alphabet lesson here '
              'says ASL is one-handed and BSL is two-handed, so that cannot be right. '
              'How different are they really?',
          topic: 'General',
          authorName: 'Maya',
          replies: [
            SeedReply(
              authorName: 'Aisha',
              body:
                  'Completely different languages, not dialects — different grammar '
                  'and different vocabulary. ASL is actually closer to French Sign '
                  'Language than to BSL for historical reasons.',
            ),
          ],
        ),
      ];
}

class SeedLesson {
  const SeedLesson({required this.lesson, required this.questions});
  final Lesson lesson;
  final List<SeedQuestion> questions;

  List<Question> toQuestions() => [
        for (final q in questions)
          Question(
            id: '',
            lessonId: '',
            prompt: q.prompt,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
          ),
      ];
}

class SeedQuestion {
  const SeedQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
}

class SeedPost {
  const SeedPost({
    required this.title,
    required this.body,
    required this.topic,
    required this.authorName,
    required this.replies,
  });

  final String title;
  final String body;
  final String topic;
  final String authorName;
  final List<SeedReply> replies;
}

class SeedReply {
  const SeedReply({required this.authorName, required this.body});
  final String authorName;
  final String body;
}
