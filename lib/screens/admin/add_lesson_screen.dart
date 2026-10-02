import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/sound/sound_service.dart';
import '../../data/cloudinary_service.dart';
import '../../models/lesson.dart';
import '../../models/question.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

/// Admin-only: pick a video, upload it to Cloudinary, write the quiz, publish.
///
/// Publishing is one Firestore batch (lesson + questions), so learners never see
/// a lesson whose quiz is half-written. The screen is gated on the role here
/// *and* by the Firestore rules — hiding the UI alone would not be enforcement.
class AddLessonScreen extends ConsumerStatefulWidget {
  const AddLessonScreen({super.key});

  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  String _category = AppConstants.categories.first;
  String _difficulty = AppConstants.difficulties.first;

  PlatformFile? _picked;
  Uint8List? _bytes;
  int _sizeBytes = 0;
  UploadResult? _uploaded;
  bool _uploading = false;
  bool _publishing = false;
  String? _error;

  final List<_QuestionDraft> _questions = [_QuestionDraft()];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _pickVideo() async {
    setState(() => _error = null);
    try {
      final file = await FilePicker.pickFile(type: FileType.video);
      if (file == null) return;

      // Read the bytes up front: on web there is no filesystem path, so the
      // upload needs them either way, and having them lets us check the size
      // against Cloudinary's limit before starting a doomed upload.
      final bytes = await file.readAsBytes();
      if (bytes.length > AppConstants.maxVideoBytes) {
        setState(() => _error =
            'That file is ${_mb(bytes.length)} MB. Cloudinary\'s free tier caps a '
            'single upload at ${AppConstants.maxVideoBytes ~/ (1024 * 1024)} MB.');
        return;
      }
      setState(() {
        _picked = file;
        _bytes = bytes;
        _sizeBytes = bytes.length;
        _uploaded = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not read that video: $e');
    }
  }

  Future<void> _upload() async {
    final bytes = _bytes;
    final file = _picked;
    if (bytes == null || file == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final result = await ref.read(cloudinaryServiceProvider).uploadVideo(
            bytes: bytes,
            filename: file.name,
          );
      if (!mounted) return;
      setState(() => _uploaded = result);
      ref.playSfx(Sfx.complete);
    } on UploadFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Picks an image for one question and uploads it straight away, rather than
  /// deferring to publish time. An upload that fails then surfaces here, next to
  /// the question it belongs to, instead of aborting a whole publish later.
  Future<void> _pickQuestionImage(_QuestionDraft draft) async {
    setState(() => draft.imageError = null);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > AppConstants.maxQuestionImageBytes) {
        setState(() => draft.imageError =
            'That image is ${_mb(bytes.length)} MB. Keep it under '
            '${AppConstants.maxQuestionImageBytes ~/ (1024 * 1024)} MB.');
        return;
      }

      setState(() {
        draft.imageBytes = bytes;
        draft.imageName = file.name;
        draft.imageUrl = null;
        draft.uploadingImage = true;
      });

      final url = await ref.read(cloudinaryServiceProvider).uploadImage(
            bytes: bytes,
            filename: file.name,
          );
      if (!mounted) return;
      setState(() {
        draft.imageUrl = url;
        draft.uploadingImage = false;
      });
      ref.playSfx(Sfx.complete);
    } on UploadFailure catch (e) {
      if (!mounted) return;
      setState(() {
        draft.imageError = e.message;
        draft.uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        draft.imageError = 'Could not attach that image: $e';
        draft.uploadingImage = false;
      });
    }
  }

  void _removeQuestionImage(_QuestionDraft draft) {
    ref.playSfx(Sfx.tap);
    setState(() {
      draft.imageBytes = null;
      draft.imageName = null;
      draft.imageUrl = null;
      draft.imageError = null;
    });
  }

  Future<void> _publish() async {
    final uploaded = _uploaded;
    if (!_form.currentState!.validate()) return;
    if (uploaded == null) {
      setState(() => _error = 'Upload the video before publishing.');
      return;
    }
    final questionErrors = _questions
        .asMap()
        .entries
        .map((e) => e.value.validate(e.key + 1))
        .whereType<String>()
        .toList();
    if (questionErrors.isNotEmpty) {
      setState(() => _error = questionErrors.first);
      return;
    }

    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final repo = ref.read(lessonRepositoryProvider);
      final order = await repo.nextOrder();
      final id = await repo.createLesson(
        lesson: Lesson(
          id: '',
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category,
          durationSeconds: uploaded.durationSeconds,
          videoUrl: uploaded.secureUrl,
          thumbnailUrl: uploaded.thumbnailUrl,
          order: order,
          difficulty: _difficulty,
        ),
        questions: [
          for (final q in _questions)
            Question(
              id: '',
              lessonId: '',
              prompt: q.prompt.text.trim(),
              options: q.options.map((o) => o.text.trim()).toList(),
              correctIndex: q.correctIndex,
              imageUrl: q.imageUrl,
              explanation: q.explanation.text.trim().isEmpty
                  ? null
                  : q.explanation.text.trim(),
            ),
        ],
      );
      if (!mounted) return;
      ref.playSfx(Sfx.celebrate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published "${_title.text.trim()}" — learners can see it now.',
          ),
        ),
      );
      context.pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      final message = e.toString().contains('permission-denied')
          ? 'Firestore refused the write. Your account\'s role must be "admin" '
              'and the security rules must be deployed.'
          : 'Could not publish: $e';
      setState(() => _error = message);
    }
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final cloudinaryReady = ref.watch(cloudinaryServiceProvider).isConfigured;
    final scheme = Theme.of(context).colorScheme;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Admins only',
          message: 'Your account role is "learner". Change it to "admin" in the '
              'Firebase console (users → your document → role) to publish lessons.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add a lesson'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: ContentWidth(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!cloudinaryReady) ...[
                    _Notice(
                      icon: Icons.cloud_off_rounded,
                      tone: _NoticeTone.error,
                      text: 'Cloudinary isn\'t configured. Add your cloud name and '
                          'upload preset to lib/core/config/app_config.dart — see '
                          'docs/02-cloudinary-setup.md.',
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_error != null) ...[
                    _Notice(
                      icon: Icons.error_outline_rounded,
                      tone: _NoticeTone.error,
                      text: _error!,
                    ),
                    const SizedBox(height: 18),
                  ],

                  Text('1 · The video',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _VideoPickerCard(
                    picked: _picked,
                    sizeBytes: _sizeBytes,
                    uploaded: _uploaded,
                    uploading: _uploading,
                    enabled: cloudinaryReady && !_publishing,
                    onPick: _pickVideo,
                    onUpload: _upload,
                  ),

                  const SizedBox(height: 28),
                  Text('2 · Details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 70,
                    decoration: const InputDecoration(
                      labelText: 'Lesson title',
                      hintText: 'e.g. Fingerspelling A–F',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? 'Give the lesson a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 400,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      hintText: 'What will the learner be able to do afterwards?',
                    ),
                    validator: (v) => (v ?? '').trim().length < 10
                        ? 'A sentence or two helps learners choose'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _DropdownField(
                    label: 'Category',
                    value: _category,
                    items: AppConstants.categories,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Difficulty',
                    value: _difficulty,
                    items: AppConstants.difficulties,
                    onChanged: (v) => setState(() => _difficulty = v),
                  ),
                  if (_uploaded != null) ...[
                    const SizedBox(height: 12),
                    _Notice(
                      icon: Icons.schedule_rounded,
                      tone: _NoticeTone.info,
                      text: 'Duration read from the uploaded file: '
                          '${_uploaded!.durationSeconds}s. No need to type it in.',
                    ),
                  ],

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text('3 · Quiz questions',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text(
                        '${_questions.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Four options each, one correct. Learners need '
                    '${AppConstants.passThresholdPercent}% to pass.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _questions.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _QuestionEditor(
                        key: ValueKey(_questions[i].key),
                        draft: _questions[i],
                        index: i,
                        enabled: cloudinaryReady && !_publishing,
                        onPickImage: () => _pickQuestionImage(_questions[i]),
                        onRemoveImage: () => _removeQuestionImage(_questions[i]),
                        onRemove: _questions.length == 1
                            ? null
                            : () {
                                ref.playSfx(Sfx.tap);
                                setState(() {
                                  _questions.removeAt(i).dispose();
                                });
                              },
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  SoundOutlinedButton(
                    onPressed: _publishing
                        ? null
                        : () => setState(() => _questions.add(_QuestionDraft())),
                    icon: const Icon(Icons.add_rounded),
                    child: const Text('Add another question'),
                  ),

                  const SizedBox(height: 32),
                  SoundFilledButton(
                    sfx: null,
                    onPressed: _publishing || _uploading ? null : _publish,
                    icon: _publishing ? null : const Icon(Icons.publish_rounded),
                    child: _publishing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Publish lesson'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Published lessons appear for every learner immediately — no '
                    'app rebuild needed.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

class _VideoPickerCard extends StatelessWidget {
  const _VideoPickerCard({
    required this.picked,
    required this.sizeBytes,
    required this.uploaded,
    required this.uploading,
    required this.enabled,
    required this.onPick,
    required this.onUpload,
  });

  final PlatformFile? picked;
  final int sizeBytes;
  final UploadResult? uploaded;
  final bool uploading;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = uploaded != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: done
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  done ? Icons.cloud_done_rounded : Icons.video_file_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      picked == null
                          ? 'No file chosen'
                          : picked!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      picked == null
                          ? kIsWeb
                              ? 'Pick an mp4, mov or webm from your computer'
                              : 'Pick an mp4, mov or webm from your device'
                          : done
                              ? 'Uploaded to Cloudinary'
                              : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB · not uploaded yet',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (uploading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Uploading… larger files take a while. Keep this screen open.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: SoundOutlinedButton(
                    onPressed: enabled ? onPick : null,
                    icon: const Icon(Icons.folder_open_rounded),
                    child: Text(picked == null ? 'Choose video' : 'Change'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SoundFilledButton(
                    sfx: null,
                    onPressed: enabled && picked != null && !done ? onUpload : null,
                    icon: Icon(done
                        ? Icons.check_rounded
                        : Icons.cloud_upload_rounded),
                    child: Text(done ? 'Uploaded' : 'Upload'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      borderRadius: BorderRadius.circular(18),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Mutable editing state for one question row.
class _QuestionDraft {
  _QuestionDraft();

  final key = UniqueKey();
  final prompt = TextEditingController();
  final explanation = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;

  /// The optional question image. [imageBytes] is kept for the local preview so
  /// the admin sees the picture immediately; [imageUrl] is what gets published,
  /// and is only set once Cloudinary has accepted the upload.
  Uint8List? imageBytes;
  String? imageName;
  String? imageUrl;
  bool uploadingImage = false;
  String? imageError;

  bool get hasImage => imageBytes != null;

  /// Returns an error message, or null when the draft is publishable.
  String? validate(int number) {
    if (prompt.text.trim().length < 5) {
      return 'Question $number needs a prompt.';
    }
    // Publishing mid-upload would write a question whose image URL is still
    // null, so the picture would silently vanish from the quiz.
    if (uploadingImage) {
      return 'Question $number is still uploading its image.';
    }
    if (imageBytes != null && imageUrl == null) {
      return 'Question $number has an image that failed to upload. '
          'Remove it or try again.';
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].text.trim().isEmpty) {
        return 'Question $number is missing option ${String.fromCharCode(65 + i)}.';
      }
    }
    final unique = options.map((o) => o.text.trim().toLowerCase()).toSet();
    if (unique.length != options.length) {
      return 'Question $number has duplicate options.';
    }
    return null;
  }

  void dispose() {
    prompt.dispose();
    explanation.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    super.key,
    required this.draft,
    required this.index,
    required this.enabled,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onRemove,
    required this.onChanged,
  });

  final _QuestionDraft draft;
  final int index;
  final bool enabled;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: scheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove question',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.prompt,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'e.g. Which handshape is the letter "C"?',
            ),
          ),
          const SizedBox(height: 12),
          _QuestionImageField(
            draft: draft,
            enabled: enabled,
            onPick: onPickImage,
            onRemove: onRemoveImage,
          ),
          const SizedBox(height: 14),
          Text(
            'Tap the circle to mark the correct answer',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < draft.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      draft.correctIndex = i;
                      onChanged();
                    },
                    tooltip: 'Mark as correct',
                    icon: Icon(
                      draft.correctIndex == i
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: draft.correctIndex == i
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: draft.options[i],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Option ${String.fromCharCode(65 + i)}',
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: draft.explanation,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Explanation (optional)',
              hintText: 'Shown after the learner answers',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).moveY(begin: 10, end: 0);
  }
}

/// The optional image on one question: a pick button, or a preview with its
/// upload state and a way to take it off again.
class _QuestionImageField extends StatelessWidget {
  const _QuestionImageField({
    required this.draft,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final _QuestionDraft draft;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // The error sits outside the pick/preview branch on purpose: a file rejected
    // for being too large never becomes a preview, and its reason still has to
    // be visible.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draft.hasImage) _preview(context) else _pickButton(),
        if (draft.imageError != null) ...[
          const SizedBox(height: 8),
          _Notice(
            icon: Icons.error_outline_rounded,
            tone: _NoticeTone.error,
            text: draft.imageError!,
          ),
        ],
      ],
    );
  }

  Widget _pickButton() => Align(
        alignment: Alignment.centerLeft,
        child: SoundOutlinedButton(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          child: const Text('Add an image (optional)'),
        ),
      );

  Widget _preview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = !draft.uploadingImage && draft.imageUrl == null;

    final (statusText, statusColor) = draft.uploadingImage
        ? ('Uploading…', scheme.onSurfaceVariant)
        : draft.imageUrl != null
            ? ('Uploaded', scheme.primary)
            : ('Not uploaded', scheme.error);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              draft.imageBytes!,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.imageName ?? 'Image',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  statusText,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: statusColor),
                ),
                if (failed)
                  TextButton(
                    onPressed: enabled ? onPick : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Choose again'),
                  ),
              ],
            ),
          ),
          if (draft.uploadingImage)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            IconButton(
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Remove image',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

enum _NoticeTone { info, error }

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = tone == _NoticeTone.error
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (scheme.secondaryContainer.withValues(alpha: 0.6), scheme.onSecondaryContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
