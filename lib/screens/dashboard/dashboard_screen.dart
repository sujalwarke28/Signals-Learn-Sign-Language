import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/lesson_providers.dart';
import '../../providers/progress_providers.dart';
import '../../widgets/common.dart';
import 'admin_dashboard.dart';
import 'learner_dashboard.dart';

/// Picks which home the signed-in user gets.
///
/// Admins and learners want genuinely different things from this screen — one
/// is maintaining the library, the other is working through it — so rather than
/// one screen with an extra card bolted on, they are two screens that happen to
/// share a route. The role is read from the Firestore user document, the same
/// field the security rules enforce on, so the UI can't disagree with what the
/// backend will actually allow.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;

    if (user?.isAdmin ?? false) {
      return Scaffold(
        body: SafeArea(bottom: false, child: AdminDashboard(user: user)),
      );
    }

    final summary = ref.watch(progressSummaryProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const LoadingView(message: 'Loading your progress'),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () {
              ref.invalidate(lessonsProvider);
              ref.invalidate(progressMapProvider);
              ref.invalidate(attemptsProvider);
            },
          ),
          data: (stats) => LearnerDashboard(user: user, stats: stats),
        ),
      ),
    );
  }
}
