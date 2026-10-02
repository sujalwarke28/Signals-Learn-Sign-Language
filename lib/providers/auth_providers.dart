import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'app_providers.dart';

/// Raw Firebase Auth state.
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// The signed-in learner's profile document, including their role.
///
/// Emits `null` while signed out, and re-emits if the role is changed in the
/// Firebase console, so promoting yourself to admin takes effect live.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  final repo = ref.watch(authRepositoryProvider);
  // An Auth account with no profile doc (created in the console, say) gets one
  // backfilled rather than leaving the app in a broken half-signed-in state.
  return repo.watchAppUser(user.uid).asyncMap((appUser) async {
    if (appUser != null) return appUser;
    await repo.ensureProfile(user);
    return null;
  });
});

/// True once we know who is signed in (or that nobody is).
final authResolvedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return false;
  if (auth.value == null) return true;
  return !ref.watch(appUserProvider).isLoading;
});

final currentUidProvider =
    Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final isAdminProvider =
    Provider<bool>((ref) => ref.watch(appUserProvider).value?.isAdmin ?? false);
