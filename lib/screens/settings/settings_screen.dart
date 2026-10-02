import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/sound/sound_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/settings_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../admin/seed_content_sheet.dart';
import '../auth/sign_out_action.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final soundOn = ref.watch(soundEnabledProvider);
    final summary = ref.watch(progressSummaryProvider).value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile & settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.8),
                          scheme.tertiaryContainer.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user?.initials ?? '?',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName.isNotEmpty == true
                                    ? user!.displayName
                                    : 'Learner',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user?.isAdmin ?? false
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.school_rounded,
                                      size: 14,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      user?.isAdmin ?? false ? 'Admin' : 'Learner',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.task_alt_rounded,
                            value: '${summary.completedLessons}',
                            label: 'Lessons done',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            icon: Icons.military_tech_rounded,
                            value: '${summary.earnedBadgeCount}',
                            label: 'Badges',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatTile(
                            icon: Icons.local_fire_department_rounded,
                            value: '${summary.dayStreak}',
                            label: 'Day streak',
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),
                  SectionHeader(title: 'Appearance'),
                  const SizedBox(height: 12),
                  _Tile(
                    icon: Icons.contrast_rounded,
                    title: 'Theme',
                    subtitle: switch (themeMode) {
                      ThemeMode.system => 'Following your device setting',
                      ThemeMode.light => 'Always light',
                      ThemeMode.dark => 'Always dark',
                    },
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                          tooltip: 'System',
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                          tooltip: 'Light',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                          tooltip: 'Dark',
                        ),
                      ],
                      selected: {themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (set) {
                        ref.playSfx(Sfx.tap);
                        ref.read(themeModeProvider.notifier).set(set.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Tile(
                    icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    title: 'Interaction sounds',
                    subtitle: soundOn
                        ? 'Short cues on taps, answers and milestones'
                        : 'Muted',
                    trailing: Switch(
                      value: soundOn,
                      onChanged: (v) =>
                          ref.read(soundEnabledProvider.notifier).set(v),
                    ),
                  ),

                  const SizedBox(height: 28),
                  SectionHeader(title: 'Learning'),
                  const SizedBox(height: 12),
                  _Tile(
                    icon: Icons.flag_rounded,
                    title: 'Passing score',
                    subtitle: '${AppConstants.passThresholdPercent}% of a lesson\'s '
                        'quiz questions',
                  ),
                  const SizedBox(height: 10),
                  _Tile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Video completion',
                    subtitle: 'A video counts as watched at '
                        '${(AppConstants.videoCompleteFraction * 100).round()}%',
                  ),

                  if (user?.isAdmin ?? false) ...[
                    const SizedBox(height: 28),
                    SectionHeader(title: 'Admin'),
                    const SizedBox(height: 12),
                    _Tile(
                      icon: Icons.add_box_rounded,
                      title: 'Add a lesson',
                      subtitle: 'Upload a video and write its quiz',
                      onTap: () => context.push(Routes.addLesson),
                    ),
                    const SizedBox(height: 10),
                    _Tile(
                      icon: Icons.dataset_rounded,
                      title: 'Demo content',
                      subtitle: 'Load or clear the sample lessons and forum posts',
                      onTap: () => SeedContentSheet.show(context),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SoundOutlinedButton(
                    onPressed: () => confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    child: const Text('Sign out'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Signals · a sign-language learning app',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (trailing == null && onTap != null)
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );

    return onTap == null
        ? content
        : Pressable(onTap: onTap, borderRadius: 20, child: content);
  }
}
