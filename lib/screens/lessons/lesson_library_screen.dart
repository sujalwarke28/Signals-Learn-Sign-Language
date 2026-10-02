import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sound/sound_service.dart';
import '../../models/lesson_progress.dart';
import '../../providers/auth_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/screen_canopy.dart';

class LessonLibraryScreen extends ConsumerStatefulWidget {
  const LessonLibraryScreen({super.key});

  @override
  ConsumerState<LessonLibraryScreen> createState() =>
      _LessonLibraryScreenState();
}

class _LessonLibraryScreenState extends ConsumerState<LessonLibraryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonsProvider);
    final filtered = ref.watch(filteredLessonsProvider);
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(lessonFilterProvider);
    final progressMap = ref.watch(progressMapProvider).value ?? const {};
    final isAdmin = ref.watch(isAdminProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.playSfx(Sfx.tap);
                context.push(Routes.addLesson);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New lesson'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: lessons.when(
          loading: () => const LoadingView(message: 'Fetching lessons'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(lessonsProvider),
          ),
          data: (all) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenCanopy(
                  title: 'Library',
                  subtitle: all.isEmpty
                      ? 'Nothing published yet'
                      : '${all.length} lessons · '
                            '${all.where((l) => (progressMap[l.id] ?? LessonProgress.notStarted(l.id)).isCompleted).length} learned',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (v) =>
                            ref.read(lessonSearchProvider.notifier).set(v),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search lessons',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _search.clear();
                                    ref
                                        .read(lessonSearchProvider.notifier)
                                        .set('');
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: [
                              TintedChip(
                                label: 'All',
                                selected: selected == null,
                                onTap: () {
                                  ref.playSfx(Sfx.tap);
                                  ref
                                      .read(lessonFilterProvider.notifier)
                                      .select(null);
                                },
                              ),
                              for (final c in categories) ...[
                                const SizedBox(width: 8),
                                TintedChip(
                                  label: c,
                                  tint: AppPalette.categoryTint(c, scheme),
                                  selected: selected == c,
                                  onTap: () {
                                    ref.playSfx(Sfx.tap);
                                    ref
                                        .read(lessonFilterProvider.notifier)
                                        .select(selected == c ? null : c);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.video_library_outlined,
                    title: 'The library is empty',
                    message: isAdmin
                        ? 'Tap "New lesson" to upload the first video and write its quiz.'
                        : 'An admin hasn\'t published any lessons yet. They\'ll appear '
                              'here automatically — no app update needed.',
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message:
                        'Try a different search or clear the category filter.',
                    action: OutlinedButton(
                      onPressed: () {
                        _search.clear();
                        ref.read(lessonSearchProvider.notifier).set('');
                        ref.read(lessonFilterProvider.notifier).select(null);
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, 48),
                      ),
                      child: const Text('Reset filters'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverToBoxAdapter(
                    child: ContentWidth(
                      maxWidth: 1180,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // One column on a phone, widening to three on a big
                          // browser window.
                          final columns = Breakpoints.lessonColumns(
                            constraints.maxWidth,
                          );
                          if (columns == 1) {
                            return Column(
                              children: [
                                for (var i = 0; i < filtered.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _AnimatedCard(
                                      index: i,
                                      child: LessonCard(
                                        lesson: filtered[i],
                                        progress:
                                            progressMap[filtered[i].id] ??
                                            LessonProgress.notStarted(
                                              filtered[i].id,
                                            ),
                                        onTap: () => context.push(
                                          Routes.lesson(filtered[i].id),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 170,
                                ),
                            itemBuilder: (context, i) => _AnimatedCard(
                              index: i,
                              child: LessonCard(
                                lesson: filtered[i],
                                progress:
                                    progressMap[filtered[i].id] ??
                                    LessonProgress.notStarted(filtered[i].id),
                                onTap: () =>
                                    context.push(Routes.lesson(filtered[i].id)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggers cards in as the list builds. Capped so a long library doesn't
/// leave the last card waiting seconds to appear.
class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => child
      .animate()
      .fadeIn(delay: (40 * (index.clamp(0, 8))).ms, duration: 320.ms)
      .moveY(begin: 16, end: 0, curve: Curves.easeOutCubic);
}
