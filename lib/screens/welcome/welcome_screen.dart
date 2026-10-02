import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/reveal.dart';
import '../../widgets/signing_space.dart';

/// The public landing page — the only screen a signed-out visitor sees first.
///
/// The argument it makes, in order: you have someone in mind; the hard part is
/// the embarrassment, not the hands; here is how practice works; here is what
/// you'd learn; you won't be alone; this is a real language with a real culture
/// behind it. Features come fourth on purpose. Nobody learns to sign because an
/// app has quizzes.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RevealScope(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _TopBar()),
            const SliverToBoxAdapter(child: _Hero()),
            SliverToBoxAdapter(child: _Beats()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- chrome

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: ContentWidth(
          maxWidth: 1100,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.sign_language_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                'Signals',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 21),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ hero

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= Breakpoints.compact;

    // A *minimum* height, not a fixed one. Pinning the height and centring a
    // column inside it overflows the moment the text needs more room than the
    // viewport allows — which is every short phone in landscape, and every
    // phone once the OS font scale goes up. The content sets the height; this
    // only stops it collapsing into something that doesn't read as a hero.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (size.height * 0.78).clamp(440.0, 720.0),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const Positioned.fill(child: SigningSpace()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 32 : 22,
              40,
              wide ? 32 : 22,
              48,
            ),
            child: ContentWidth(
              maxWidth: 1100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Say',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: wide ? 58 : 40,
                      height: 1.04,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const _CyclingWord(),
                  Text(
                    'with your hands.',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: wide ? 58 : 40,
                      height: 1.04,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 26),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(
                      'Learn sign language through short video lessons. '
                      'At your pace, in your own time, with nobody watching.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: wide ? 18 : 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => context.go(Routes.signup),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('Learn your first sign'),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(Routes.login),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('I have an account'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Free, and it takes about four minutes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The object of the sentence, swapped on a timer.
///
/// Shows range without a feature list: the point is that "hello" is only the
/// first of these, and the reader works that out on their own.
class _CyclingWord extends StatefulWidget {
  const _CyclingWord();

  @override
  State<_CyclingWord> createState() => _CyclingWordState();
}

class _CyclingWordState extends State<_CyclingWord> {
  // Every one of these has to complete "Say ___ with your hands."
  static const _words = <String>[
    'hello',
    'thank you',
    'good morning',
    'I love you',
    'nice to meet you',
    'see you tomorrow',
  ];

  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact;

    final style = theme.textTheme.displaySmall?.copyWith(
      fontSize: wide ? 58 : 40,
      height: 1.04,
      color: scheme.primary,
    );

    return SizedBox(
      // Fixed height: the words differ in length, and letting the box resize
      // would shove the line below it up and down on every swap. Reduced
      // motion uses the same box so the hero is the same height either way.
      height: (wide ? 58 : 40) * 1.18,
      child: Align(
        alignment: Alignment.centerLeft,
        // A word that stops moving is a word that can be read.
        child: MediaQuery.disableAnimationsOf(context)
            ? Text(_words.first, style: style)
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 460),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.42),
                    end: Offset.zero,
                  ).animate(animation);
                  return ClipRect(
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    ),
                  );
                },
                child: Text(_words[_i], key: ValueKey(_i), style: style),
              ),
      ),
    );
  }
}

// ----------------------------------------------------------------- beats

class _Beats extends StatelessWidget {
  const _Beats();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: ContentWidth(
        maxWidth: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _TheFace(),
            _SectionGap(),
            _TheFear(),
            _SectionGap(),
            _HowItWorks(),
            _SectionGap(),
            _Inside(),
            _SectionGap(),
            _NotAlone(),
            _SectionGap(),
            _Respect(),
            _SectionGap(),
            _Close(),
          ],
        ),
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 84);
}

/// Shared section heading + body, so every beat has the same rhythm.
class _Beat extends StatelessWidget {
  const _Beat({required this.heading, required this.paragraphs, this.child});

  final String heading;
  final List<String> paragraphs;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Text(
            heading,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: wide ? 34 : 27,
              height: 1.16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < paragraphs.length; i++) ...[
          Reveal(
            delay: Duration(milliseconds: 60 + i * 50),
            child: Text(
              paragraphs[i],
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: wide ? 17.5 : 16,
                height: 1.62,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (i != paragraphs.length - 1) const SizedBox(height: 14),
        ],
        if (child != null) ...[const SizedBox(height: 28), child!],
      ],
    );
  }
}

class _TheFace extends StatelessWidget {
  const _TheFace();

  @override
  Widget build(BuildContext context) => const _Beat(
    heading: "There's probably someone\nyou have in mind.",
    paragraphs: [
      'A friend. A student. Someone two desks over. A grandchild you have '
          'never properly been able to talk to.',
      'Almost nobody sets out to learn sign language in the abstract. They '
          'learn it for one particular person — and they usually start long '
          'after they wish they had.',
      "You don't need to be fluent to change that. You need a handful of "
          'signs and the nerve to try the first one.',
    ],
  );
}

class _TheFear extends StatelessWidget {
  const _TheFear();

  @override
  Widget build(BuildContext context) => const _Beat(
    heading: "The hard part isn't your hands.",
    paragraphs: [
      "It's doing it in front of somebody. Getting the shape wrong. Moving "
          'too slowly. Meaning one thing and signing another.',
      'So get it wrong here first. Every lesson is a short video you can '
          'replay as many times as you like. Watch it twice. Watch it forty '
          'times. Nothing is timed, nothing is scored against anyone else, '
          'and no one is watching you practise.',
    ],
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (
      Icons.play_circle_fill_rounded,
      'Watch',
      'A short video for every sign, shot close up and slowed down where it '
          'matters.',
    ),
    (
      Icons.back_hand_rounded,
      'Copy',
      'Mirror it back. Your hands, your pace, your kitchen — as many attempts '
          'as it takes.',
    ),
    (
      Icons.task_alt_rounded,
      'Check',
      'A short quiz afterwards, so you find out what stuck and what to revisit.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact;

    final cards = [
      for (var i = 0; i < _steps.length; i++)
        Reveal(
          delay: Duration(milliseconds: i * 70),
          child: _StepCard(
            index: i + 1,
            icon: _steps[i].$1,
            title: _steps[i].$2,
            body: _steps[i].$3,
          ),
        ),
    ];

    return _Beat(
      heading: 'Three minutes, three steps.',
      paragraphs: const [
        'One lesson is one sign, start to finish. Short enough to do while the '
            'kettle boils, which is the only reason anyone keeps doing it.',
      ],
      child: wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 14),
                  ],
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  cards[i],
                  if (i != cards.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: scheme.primary),
              const Spacer(),
              Text(
                '0$index',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.52,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Inside extends StatelessWidget {
  const _Inside();

  /// Mirrors the lesson categories the library actually ships, so the promise
  /// here and the content behind the sign-up are the same thing.
  static const _groups = <(String, String)>[
    ('Alphabet', 'Fingerspell anything — including names.'),
    ('Numbers', 'Counting, prices, phone numbers, time.'),
    ('Greetings', 'Hello, goodbye, how are you, see you soon.'),
    ('Common Phrases', 'Please, sorry, again slower, I understand.'),
    ('Family', 'Mother, brother, partner, the people you talk about most.'),
    ('Colors', 'Small, concrete, and satisfying to get right.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Beat(
      heading: 'Start where it is useful.',
      paragraphs: const [
        'Six groups of lessons, ordered so the first things you learn are the '
            'first things you will actually need to say.',
      ],
      child: Column(
        children: [
          for (var i = 0; i < _groups.length; i++) ...[
            Reveal(
              delay: Duration(milliseconds: i * 45),
              child: _GroupRow(name: _groups[i].$1, blurb: _groups[i].$2),
            ),
            if (i != _groups.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.name, required this.blurb});

  final String name;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(name, scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  blurb,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAlone extends StatelessWidget {
  const _NotAlone();

  @override
  Widget build(BuildContext context) => const _Beat(
    heading: 'You are not practising alone.',
    paragraphs: [
      'There is a question board inside, for when a sign will not click or '
          'you want someone to tell you whether you have got it right.',
      'Ask anything, however basic. Everyone there started exactly where '
          'you are about to.',
    ],
  );
}

class _Respect extends StatelessWidget {
  const _Respect();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: const _Beat(
        heading: 'A language, not a workaround.',
        paragraphs: [
          'Sign language is not English with gestures. It has its own grammar, '
              'its own regional accents, its own humour and its own poetry — '
              'built and carried by Deaf communities, who are still its first '
              'speakers and its best teachers.',
          'Signals teaches it as the living language it is. Learn here, then '
              'learn from Deaf teachers and Deaf friends wherever you can. '
              'This is somewhere to begin, not somewhere to stop.',
        ],
      ),
    );
  }
}

class _Close extends StatelessWidget {
  const _Close();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact;

    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            child: Text(
              'Say hello with your hands.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: wide ? 36 : 28,
                height: 1.14,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 60),
            child: Text(
              'One sign is enough to start a conversation. Everything after '
              'that is just more signs.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: wide ? 17.5 : 16,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go(Routes.signup),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text('Start with hello'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 18),
          Text(
            'Signals — learn sign language through video lessons, quizzes and '
            'a community.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
