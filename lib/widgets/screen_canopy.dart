import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common.dart';
import 'signing_space.dart';

/// The header every main screen opens with.
///
/// Extracted from the dashboard so Lessons, Progress and Community arrive with
/// the same weight rather than a bare headline over a list. The drifting trail
/// behind it is the same motif as the landing page hero, which is what makes
/// the product read as one thing instead of four screens that share a palette.
class ScreenCanopy extends StatelessWidget {
  const ScreenCanopy({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.accent,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Search fields, filter rows, stat strips — whatever the screen needs
  /// directly under its name, inside the tinted area.
  final Widget? child;

  /// Defaults to the scheme's primary. Each screen tints its own canopy so they
  /// are distinguishable at a glance when swiping between tabs.
  final Color? accent;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = accent ?? scheme.primary;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact;

    return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(34),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.16),
                  scheme.tertiary.withValues(alpha: 0.08),
                  scheme.surface.withValues(alpha: 0),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -80,
                  top: -50,
                  width: 300,
                  height: 280,
                  child: IgnorePointer(
                    child: SigningSpace(
                      intensity: 0.34,
                      period: const Duration(seconds: 17),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                    child: ContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            fontSize: wide ? 36 : 31,
                                            height: 1.05,
                                          ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        subtitle!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              ?trailing,
                            ],
                          ),
                          if (child != null) ...[
                            const SizedBox(height: 18),
                            child!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms)
        .moveY(begin: -12, end: 0, curve: Curves.easeOutQuart);
  }
}

/// A tinted filter pill. Replaces Material's [FilterChip] on the library and
/// community rows so a selected category carries its own colour rather than a
/// uniform theme fill.
class TintedChip extends StatelessWidget {
  const TintedChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = tint ?? scheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tint != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? color : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
