import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/sound/sound_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _topic = AppConstants.forumTopics.first;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(appUserProvider).value;
    final uid = ref.read(currentUidProvider);
    if (user == null || uid == null) return;

    setState(() => _sending = true);
    try {
      final id = await ref.read(forumRepositoryProvider).createPost(
            authorId: uid,
            authorName: user.displayName.isEmpty ? 'Learner' : user.displayName,
            title: _title.text,
            body: _body.text,
            topic: _topic,
          );
      if (!mounted) return;
      ref.playSfx(Sfx.post);
      // Straight into the new thread, replacing the form.
      context.pushReplacement(Routes.post(id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish the post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('New post'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ContentWidth(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Topic', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in AppConstants.forumTopics)
                        ChoiceChip(
                          label: Text(t),
                          selected: _topic == t,
                          showCheckmark: false,
                          onSelected: (_) {
                            ref.playSfx(Sfx.tap);
                            setState(() => _topic = t);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 90,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What\'s your question or update?',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Give your post a title';
                      if (value.length < 6) return 'A few more words, please';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _body,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 6,
                    maxLines: 12,
                    maxLength: 1200,
                    decoration: const InputDecoration(
                      labelText: 'Your post',
                      alignLabelWithHint: true,
                      hintText: 'Add the details. What have you tried so far?',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Write something first';
                      if (value.length < 15) {
                        return 'At least 15 characters so others can help';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.public_rounded, size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Posted under your name and visible to every learner '
                          'straight away.',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SoundFilledButton(
                    sfx: null,
                    onPressed: _sending ? null : _submit,
                    icon: _sending ? null : const Icon(Icons.send_rounded),
                    child: _sending
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Publish post'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
