import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/progress_summary.dart';
import 'common.dart';
import 'pressable.dart';

/// A badge as a lit medallion rather than a flat chip.
///
/// Shared by the dashboard's scrolling row and the progress screen's grid, so
/// an earned badge looks identical wherever it is seen.
class Medallion extends StatelessWidget {
  const Medallion({super.key, required this.badge, required this.onTap});

  final EarnedBadge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final earned = badge.earned;
    final tint = earned ? colors.streak : scheme.onSurfaceVariant;

    return Pressable(
      borderRadius: 100,
      onTap: onTap,
      semanticLabel: '${badge.label}. ${badge.description}',
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: earned
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: 0.28),
                          tint.withValues(alpha: 0.10),
                        ],
                      )
                    : null,
                color: earned
                    ? null
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                border: Border.all(
                  color: earned
                      ? tint.withValues(alpha: 0.55)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1.6,
                ),
                boxShadow: [
                  if (earned)
                    BoxShadow(
                      color: tint.withValues(alpha: 0.28),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                earned ? BadgeTile.iconFor(badge.icon) : Icons.lock_rounded,
                size: earned ? 27 : 20,
                color: earned ? tint : tint.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: earned ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
