import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sound/sound_service.dart';
import '../data/auth_repository.dart';
import '../data/cloudinary_service.dart';
import '../data/forum_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_repository.dart';
import '../data/seed_service.dart';

/// Overridden in `main()` once SharedPreferences has loaded, so settings are
/// readable synchronously everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider was not overridden'),
);

/// Overridden in `main()` with an already-initialised service.
final soundServiceProvider = Provider<SoundService>(
  (ref) => throw UnimplementedError('soundServiceProvider was not overridden'),
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  ),
);

final lessonRepositoryProvider =
    Provider<LessonRepository>((ref) => LessonRepository(ref.watch(firestoreProvider)));

final progressRepositoryProvider = Provider<ProgressRepository>(
    (ref) => ProgressRepository(ref.watch(firestoreProvider)));

final forumRepositoryProvider =
    Provider<ForumRepository>((ref) => ForumRepository(ref.watch(firestoreProvider)));

final seedServiceProvider = Provider<SeedService>(
  (ref) => SeedService(
    db: ref.watch(firestoreProvider),
    lessons: ref.watch(lessonRepositoryProvider),
    forum: ref.watch(forumRepositoryProvider),
  ),
);

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  final service = CloudinaryService();
  ref.onDispose(service.dispose);
  return service;
});
