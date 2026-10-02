import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound/sound_service.dart';
import '../../providers/forum_providers.dart';
import '../../providers/settings_providers.dart';
import 'channels.dart';

/// The channel list down the left of the community screen.
///
/// Persistent on anything tablet-width and up; on a phone the same widget is
/// the contents of a drawer, which is how every chat client handles the same
/// problem — a fixed rail would eat a third of a phone screen.
class ChannelRail extends ConsumerWidget {
  const ChannelRail({super.key, this.onPick, this.width = 212});

  /// Called after a channel is chosen, so a drawer can close itself.
  final VoidCallback? onPick;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = ref.watch(forumChannelProvider);
    final unread = ref.watch(unreadByChannelProvider);
    final mentions = ref.watch(myMentionsProvider).length;

    void pick(String? topic) {
      ref.playSfx(Sfx.tap);
      ref.read(forumChannelProvider.notifier).select(topic);
      if (topic != null && topic != mentionsChannel) {
        ref.read(channelReadsProvider.notifier).markSeen(topic);
      }
      onPick?.call();
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              child: Text(
                'Community',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
            ),
            _RailEntry(
              label: 'All messages',
              icon: Icons.forum_rounded,
              selected: selected == null,
              onTap: () => pick(null),
            ),
            _RailEntry(
              label: 'Mentions',
              icon: Icons.alternate_email_rounded,
              selected: selected == mentionsChannel,
              badge: mentions,
              // A mention is addressed to you by name, so it is the one count
              // worth showing in the accent colour rather than the muted one.
              badgeColor: scheme.primary,
              onTap: () => pick(mentionsChannel),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Text(
                'CHANNELS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: 10,
                ),
              ),
            ),
            for (final c in Channel.all)
              _RailEntry(
                label: c.label,
                selected: selected == c.topic,
                badge: unread[c.topic] ?? 0,
                onTap: () => pick(c.topic),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.badge = 0,
    this.badgeColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = badge > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      // An unread channel is bolder as well as badged, so the
                      // state does not rest on a small coloured dot alone.
                      fontWeight: selected || unread
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: selected
                          ? scheme.primary
                          : unread
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? scheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
