import 'package:flutter/material.dart';

import '../screens/forum/mentions.dart';

/// The autocomplete row that appears under a composer while an @handle is being
/// typed.
///
/// Deliberately a strip under the field rather than a floating overlay: the
/// composer is a plain [TextFormField] inside a scroll view, and an overlay
/// anchored to a moving caret inside a scrolling form is a lot of machinery for
/// a list that is at most a handful of names.
class MentionSuggestions extends StatelessWidget {
  const MentionSuggestions({
    super.key,
    required this.controller,
    required this.people,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<ForumPerson> people;

  /// Called after the text is rewritten, so the host can rebuild.
  final VoidCallback onChanged;

  /// The @word immediately before the caret, if the caret is inside one.
  static ({int start, String query})? activeMention(TextEditingValue value) {
    final caret = value.selection.baseOffset;
    if (caret < 0 || caret > value.text.length) return null;
    final upto = value.text.substring(0, caret);
    final at = upto.lastIndexOf('@');
    if (at < 0) return null;
    // Must start a word, or "name@host" offers suggestions mid-email.
    if (at > 0 && RegExp(r'[\w@]').hasMatch(upto[at - 1])) return null;
    final query = upto.substring(at + 1);
    if (query.contains(RegExp(r'[\s@]'))) return null;
    return (start: at, query: query.toLowerCase());
  }

  List<ForumPerson> _matches(String query) {
    if (query.isEmpty) return people.take(6).toList();
    return people
        .where(
          (p) =>
              p.handle.startsWith(query) ||
              p.fullHandle.startsWith(query) ||
              p.name.toLowerCase().contains(query),
        )
        .take(6)
        .toList();
  }

  void _insert(ForumPerson person, int start) {
    final caret = controller.selection.baseOffset;
    final replacement = '@${person.handle} ';
    final text = controller.text.replaceRange(start, caret, replacement);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final active = activeMention(controller.value);
    if (active == null) return const SizedBox.shrink();

    final matches = _matches(active.query);

    // Silence after typing @ reads as a broken feature. Say why the list is
    // empty instead.
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          people.isEmpty
              ? 'Nobody else has joined yet'
              : 'No one here matches "@${active.query}"',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mention someone',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in matches)
                GestureDetector(
                  onTap: () => _insert(p, active.start),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${p.handle}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders a body with its @mentions picked out, and the reader's own mention
/// picked out harder.
class MentionText extends StatelessWidget {
  const MentionText({
    super.key,
    required this.body,
    required this.people,
    this.viewerUid,
    this.style,
    this.maxLines,
  });

  final String body;
  final List<ForumPerson> people;
  final String? viewerUid;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = style ?? theme.textTheme.bodyMedium;
    final spans = mentionSpans(body, people: people, viewerUid: viewerUid);

    if (spans.isEmpty) return Text(body, style: base, maxLines: maxLines);

    return Text.rich(
      TextSpan(
        children: [
          for (final s in spans)
            TextSpan(
              text: s.text,
              style: s.isMention
                  ? base?.copyWith(
                      color: s.isYou
                          ? scheme.onPrimaryContainer
                          : scheme.primary,
                      fontWeight: FontWeight.w800,
                      backgroundColor: s.isYou
                          ? scheme.primaryContainer.withValues(alpha: 0.9)
                          : scheme.primary.withValues(alpha: 0.10),
                    )
                  : base,
            ),
        ],
      ),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }
}
