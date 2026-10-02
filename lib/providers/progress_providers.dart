import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lesson_progress.dart';
import '../models/progress_summary.dart';
import '../models/quiz_attempt.dart';
import 'app_providers.dart';
import 'auth_providers.dart';
import 'lesson_providers.dart';

/// Today's date at midnight, re-emitted once the clock passes into tomorrow.
///
/// The streak is a function of "what day is it", so something has to tell
/// Riverpod when that answer changes. Without this the dashboard holds
/// yesterday's streak until one of the Firestore streams happens to emit —
/// which, for a learner who left the app open overnight, may be never.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  // A second past midnight, so the rebuild never lands on 23:59:59.999 and
  // re-derive the day it was already showing.
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(
    tomorrow.difference(now) + const Duration(seconds: 1),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return ProgressSummary.dayOf(now);
});

/// Every progress doc for the signed-in learner, keyed by lesson id.
final progressMapProvider = StreamProvider<Map<String, LessonProgress>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  ref.keepAlive();
  return ref.watch(progressRepositoryProvider).watchProgress(uid);
});

final lessonProgressProvider = Provider.family<LessonProgress, String>((ref, lessonId) {
  final map = ref.watch(progressMapProvider).value ?? const {};
  return map[lessonId] ?? LessonProgress.notStarted(lessonId);
});

/// Every quiz attempt the learner has ever submitted.
final attemptsProvider = StreamProvider<List<QuizAttempt>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  ref.keepAlive();
  return ref.watch(progressRepositoryProvider).watchAttempts(uid);
});

/// The single derived stat object the Dashboard and Progress screens render.
///
/// It watches three live Firestore streams — lessons, progress docs, quiz
/// attempts — and recomputes from scratch whenever any of them emits. That's
/// what makes the numbers move the instant a quiz is submitted: the transaction
/// in [ProgressRepository.submitAttempt] writes an attempt and a progress doc,
/// both streams fire, and this provider re-runs. Nothing is cached, stored or
/// faked.
final progressSummaryProvider = Provider<AsyncValue<ProgressSummary>>((ref) {
  // Signed out there is nothing to summarise, and any Firestore stream still
  // tearing down is about to report permission-denied. That is the sign-out
  // itself, not a fault worth showing a learner on their way to the login
  // screen, so hold on the loading state instead of surfacing it.
  if (ref.watch(currentUidProvider) == null) return const AsyncValue.loading();

  final lessons = ref.watch(lessonsProvider);
  final progress = ref.watch(progressMapProvider);
  final attempts = ref.watch(attemptsProvider);

  // Surface the first real error rather than silently showing zeroes.
  for (final v in [lessons, progress, attempts]) {
    if (v.hasError) return AsyncValue.error(v.error!, v.stackTrace!);
  }
  if (lessons.isLoading || progress.isLoading || attempts.isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    ProgressSummary.from(
      lessons: lessons.requireValue,
      progress: progress.requireValue,
      attempts: attempts.requireValue,
      today: ref.watch(todayProvider),
    ),
  );
});
