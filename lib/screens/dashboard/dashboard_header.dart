import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../router/app_router.dart';
import '../../widgets/pressable.dart';
import '../auth/sign_out_action.dart';

/// The learner's greeting: time of day, their first name, and the way out.
///
/// Warm and personal, which is the half of the distinction the learner side
/// owns — the admin console deliberately opens cold by comparison.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key, required this.user});

  final AppUser? user;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeGreeting,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                user?.firstName ?? 'there',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AvatarButton(user: user),
        // Settings holds the same action, but signing out shouldn't cost a trip
        // through another screen to find.
        IconButton(
          onPressed: () => confirmSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded),
          color: scheme.onSurfaceVariant,
          tooltip: 'Sign out',
          visualDensity: VisualDensity.compact,
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).moveY(begin: -10, end: 0);
  }
}

/// The initials circle, shared by both dashboards so the way into Settings is
/// in the same place whichever one you land on.
class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, required this.user, this.size = 46});

  final AppUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      borderRadius: 100,
      onTap: () => context.push(Routes.settings),
      semanticLabel: 'Profile and settings',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          user?.initials ?? '?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
