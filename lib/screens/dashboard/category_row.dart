import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/progress_summary.dart';
import '../../providers/lesson_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';

/// One category line: a tinted dot, the done/total count and a bar.
///
/// Lifted out of the dashboard when it split in two — the learner view
/// still shows these, and keeping one copy means the tint and the tap
/// behaviour cannot drift apart.
class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key, required this.stats});

  final CategoryStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = AppPalette.categoryTint(stats.category, scheme);

    // Preselect the library's category chip before switching tabs, so the tap
    // lands on just this category instead of the whole catalogue.
    void openCategory() {
      ref.read(lessonFilterProvider.notifier).select(stats.category);
      context.go(Routes.lessons);
    }

    return Pressable(
      borderRadius: 16,
      onTap: openCategory,
      semanticLabel:
          '${stats.category}: ${stats.completedLessons} of '
          '${stats.totalLessons} lessons done',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: tint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stats.category,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${stats.completedLessons}/${stats.totalLessons}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 7),
            ProgressBar(
              value: stats.completionFraction,
              color: tint,
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
