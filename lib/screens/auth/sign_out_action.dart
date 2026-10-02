import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../router/app_router.dart';

/// Asks first, then signs out. Shared so the dashboard header button and the
/// settings screen can't drift apart on wording or on whether they confirm.
///
/// The router's auth redirect would normally handle the trip back to /login on
/// its own, but it only re-runs when its refresh notifier fires. Navigating
/// here as well makes leaving the signed-in screens a direct consequence of the
/// tap rather than something inferred from an auth stream — the redirect still
/// runs and still agrees, so the extra `go` is a no-op when it worked anyway.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('Your progress stays saved to your account.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref.read(authRepositoryProvider).signOut();
    // The dialog's await means this context may be gone by now.
    if (context.mounted) context.go(Routes.login);
  }
}
