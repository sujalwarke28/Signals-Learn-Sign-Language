import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sound/sound_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/forum_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/mention_field.dart';
import 'channels.dart';
import 'mentions.dart';

/// The message bar at the foot of a channel.
///
/// Sends straight into whichever channel is open, so posting is one box and one
/// key rather than a trip through a form. The longer composer is still a tap
/// away for anything that wants a title of its own or several channels at once.
class ChannelComposer extends ConsumerStatefulWidget {
  const ChannelComposer({super.key});

  @override
  ConsumerState<ChannelComposer> createState() => _ChannelComposerState();
}

class _ChannelComposerState extends ConsumerState<ChannelComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;

    final user = ref.read(appUserProvider).value;
    final uid = ref.read(currentUidProvider);
    if (user == null || uid == null) return;

    final channel = targetChannel(ref.read(forumChannelProvider));

    setState(() => _sending = true);
    try {
      await ref
          .read(forumRepositoryProvider)
          .createPost(
            authorId: uid,
            authorName: user.displayName.isEmpty ? 'Learner' : user.displayName,
            title: titleFromMessage(body),
            body: body,
            topics: [channel],
            mentionedUids: resolveMentions(body, ref.read(forumPeopleProvider)),
          );
      if (!mounted) return;
      _text.clear();
      ref.playSfx(Sfx.post);
      // Keep the caret where it was: in a chat you send several in a row.
      _focus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send that: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final channel = targetChannel(ref.watch(forumChannelProvider));
    final canSend = _text.text.trim().isNotEmpty && !_sending;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MentionSuggestions(
                controller: _text,
                people: ref.watch(forumPeopleProvider),
                onChanged: () => setState(() {}),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => context.push(Routes.newPost),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    tooltip: 'Longer post, or several channels',
                    color: scheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      // Grows with the message, then scrolls — a chat bar that
                      // can swallow the whole screen is worse than one that
                      // stops.
                      constraints: const BoxConstraints(maxHeight: 132),
                      child: TextField(
                        controller: _text,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: null,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
                        // Enter sends, Shift+Enter breaks the line. On a phone
                        // the key is a newline anyway, so this only affects
                        // anyone with a keyboard.
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Message #${Channel.slugFor(channel)}',
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: scheme.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(enabled: canSend, busy: _sending, onTap: _send),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: enabled
            ? scheme.primary
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: enabled ? onTap : null,
        tooltip: 'Send',
        icon: busy
            ? SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            : Icon(
                Icons.send_rounded,
                size: 19,
                color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
