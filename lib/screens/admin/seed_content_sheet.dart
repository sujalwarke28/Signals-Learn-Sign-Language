import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound/sound_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/pressable.dart';

/// Admin-only sheet that loads (or clears) the demo lessons, quizzes and forum
/// threads. Handy for setting up a fresh Firebase project, and for resetting
/// between demo runs.
class SeedContentSheet extends ConsumerStatefulWidget {
  const SeedContentSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SeedContentSheet(),
      );

  @override
  ConsumerState<SeedContentSheet> createState() => _SeedContentSheetState();
}

class _SeedContentSheetState extends ConsumerState<SeedContentSheet> {
  bool _includeLessons = true;
  bool _includeForum = true;
  bool _busy = false;
  String? _message;
  bool _isError = false;

  Future<void> _run() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() {
      _busy = true;
      _message = null;
      _isError = false;
    });
    try {
      final report = await ref.read(seedServiceProvider).seed(
            authorId: uid,
            includeLessons: _includeLessons,
            includeForum: _includeForum,
          );
      if (!mounted) return;
      ref.playSfx(Sfx.celebrate);
      setState(() => _message = 'Loaded ${report.summary}.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = e.toString().contains('permission-denied')
            ? 'Firestore refused the write. Check your role is "admin" and that '
                'firestore.rules is deployed.'
            : 'Seeding failed: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all content?'),
        content: const Text(
          'Deletes every lesson, quiz question and forum thread in this Firebase '
          'project. Learner progress documents are not touched, so old scores may '
          'refer to lessons that no longer exist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    setState(() {
      _busy = true;
      _message = null;
      _isError = false;
    });
    try {
      await ref.read(seedServiceProvider).clearContent();
      if (!mounted) return;
      setState(() => _message = 'Content cleared.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'Could not clear content: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Demo content', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Ten ASL lessons with four questions each, plus four forum threads. '
              'The lesson videos are short placeholder clips, clearly marked as '
              'such in the app.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            CheckboxListTile(
              value: _includeLessons,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _includeLessons = v ?? true),
              title: const Text('Lessons and quiz questions'),
              subtitle: const Text('10 lessons across 6 categories'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _includeForum,
              onChanged:
                  _busy ? null : (v) => setState(() => _includeForum = v ?? true),
              title: const Text('Forum threads'),
              subtitle: const Text('4 posts with replies'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: _isError
                      ? scheme.errorContainer
                      : scheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: _isError
                          ? scheme.onErrorContainer
                          : scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _isError
                              ? scheme.onErrorContainer
                              : scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SoundFilledButton(
              sfx: null,
              onPressed:
                  _busy || (!_includeLessons && !_includeForum) ? null : _run,
              icon: _busy ? null : const Icon(Icons.download_rounded),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Load demo content'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _busy ? null : _clear,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Clear all lessons and posts'),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
            ),
            const SizedBox(height: 4),
            Text(
              'Running this twice creates a second copy of everything.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
