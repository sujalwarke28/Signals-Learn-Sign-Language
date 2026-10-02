# 15 · Tech stack

Everything this project is built from, with the version actually resolved on the
machine it was developed on, and what each piece does here.

This is an inventory. For *how the code is organised* and why it's shaped that
way, read [doc 12](12-architecture.md) instead — the two are meant to be read
together and this one deliberately doesn't repeat it.

Figures below were read off the project on **2 October 2026**, not from memory.

---

## 15.1 At a glance

| Layer | Choice |
| --- | --- |
| Language | Dart 3.13.2 |
| UI framework | Flutter 3.47.2 (stable) |
| State management | Riverpod 3 (`flutter_riverpod` 3.4.3) |
| Navigation | `go_router` 18.0.1 |
| Authentication | Firebase Auth (email/password + Google) |
| Database | Cloud Firestore |
| Video hosting | Cloudinary (unsigned client upload) |
| Web hosting | Firebase Hosting |
| Android build | Gradle 9.3.1 · AGP 9.1.0 · Kotlin 2.4.0 · JDK 17 |
| Target platforms | Android 7.0+ and web. No iOS. |
| Tests | `flutter_test` — 154 tests across 16 files |
| Lints | `flutter_lints` 6.0.0 |

Size: **78 Dart files, ~16,300 lines** under `lib/`, plus **~2,260 lines** of
tests. The release APK is ~63 MB universal, or ~24 MB built per-ABI.

---

## 15.2 Language and framework

| | Version | Notes |
| --- | --- | --- |
| Flutter | 3.47.2, stable channel | Engine revision `a804b26164` |
| Dart | 3.13.2 | `pubspec.yaml` pins `sdk: ^3.13.2` |
| DevTools | 2.60.0 | Used for the widget inspector while building the UI |

Flutter was chosen for the obvious reason: one Dart codebase produces the
Android app that is the graded deliverable *and* a web build that serves as a
backup demo, which a native Android project would not.

Dart language features this project leans on, in case they look unfamiliar:
pattern-matching `switch` expressions (the theme and status labels), records and
`sealed`-style enums with fields (`Sfx`), null-safety throughout, and
`AsyncValue` for the three loading/error/data states every screen handles.

---

## 15.3 Dart packages

All of these are direct dependencies in [`pubspec.yaml`](../pubspec.yaml). The
version column is what `pubspec.lock` actually resolved, so this is the set that
built the APK.

### State, routing, storage

| Package | Version | What it does here |
| --- | --- | --- |
| `flutter_riverpod` | 3.4.3 | Every provider in `lib/providers/`. Uses the Riverpod 3 `Notifier` API (not the legacy `StateNotifier`). Firestore streams enter the app as `StreamProvider`s, and derived stats are plain `Provider`s that recompute when those emit. |
| `go_router` | 18.0.1 | All navigation, in [`lib/router/app_router.dart`](../lib/router/app_router.dart). A `StatefulShellRoute` with four branches keeps each bottom-nav tab's scroll position and navigation stack alive. Auth redirects are a pure function so they're unit-testable. |
| `shared_preferences` | 2.5.5 | Two local settings only — `settings.themeMode` and `settings.soundEnabled`. Nothing about progress is stored on-device; that all lives in Firestore. |

### Firebase

| Package | Version | What it does here |
| --- | --- | --- |
| `firebase_core` | 4.15.0 | Initialises Firebase from the generated [`lib/firebase_options.dart`](../lib/firebase_options.dart). |
| `firebase_auth` | 6.7.0 | Email/password sign-up and sign-in, plus the Google credential exchange. This is what forces `minSdk 23`+ on Android. |
| `cloud_firestore` | 6.10.0 | Every read and write. Used as live streams rather than one-shot fetches, which is why the dashboard updates the instant a quiz is submitted. |
| `google_sign_in` | 7.2.0 | The Google provider. On Android it needs the signing certificate's SHA-1 registered in Firebase — see [doc 14](14-google-sign-in.md). |

### Video and media

| Package | Version | What it does here |
| --- | --- | --- |
| `video_player` | 2.14.0 | The platform video surface. |
| `chewie` | 1.17.2 | Player controls on top of `video_player`, so there's no hand-rolled scrubber. |
| `audioplayers` | 6.8.1 | The six interaction sound cues (see 15.9). |
| `file_picker` | 13.1.0 | Admin picking a video file to upload. |
| `http` | 1.6.0 | The multipart POST to Cloudinary's upload endpoint. Nothing else — all other I/O goes through the Firebase SDKs. |

### Look and feel

| Package | Version | What it does here |
| --- | --- | --- |
| `flutter_animate` | 4.5.2 | Entrance and scroll-reveal animations, declared inline rather than via explicit `AnimationController`s. The hand-written painters (the landing-page trail, the lesson path, the current-node halo) use real controllers, because they drive custom geometry rather than a widget property. |
| `lottie` | 3.6.1 | The confetti burst on passing a quiz, and on the dashboard once every lesson is done. |
| `cupertino_icons` | 1.0.9 | Icon font (tree-shaken to 1.8 KB at build time). |
| `intl` | 0.20.3 | Date formatting on the progress screen and forum list. |

### Development only

| Package | Version | What it does here |
| --- | --- | --- |
| `flutter_test` | SDK | All 154 tests. |
| `flutter_lints` | 6.0.0 | The rule set behind `analysis_options.yaml`. The project analyzes clean — zero issues. |

---

## 15.4 Backend and cloud services

Two external accounts, both on free tiers. Neither requires a server we run.

### Firebase

| Service | Used for |
| --- | --- |
| Authentication | Email/password and Google sign-in |
| Cloud Firestore | The entire data model (15.6) |
| Hosting | The web build, with cache headers set in [`firebase.json`](../firebase.json) |

Configuration lives in `.firebaserc` and `lib/firebase_options.dart`, both
gitignored so a clone doesn't point at someone else's project. Set-up steps are
in [doc 1](01-firebase-setup.md).

### Cloudinary

Lesson videos are uploaded straight from the client to Cloudinary via an
**unsigned upload preset**, in
[`lib/data/cloudinary_service.dart`](../lib/data/cloudinary_service.dart).

The reason this is not Firebase Storage: Storage now requires a paid Blaze plan.
The reason the upload is unsigned: a signed upload needs the Cloudinary API
secret, and anything compiled into an APK or a web bundle can be extracted from
it. The preset is the only credential the app carries, and it permits nothing
beyond adding a file to one folder. Values live in
`lib/core/config/app_config.dart` (gitignored) or are passed at build time with
`--dart-define`. See [doc 2](02-cloudinary-setup.md).

### Not used, deliberately

**Firebase Storage** (paid plan), **Cloud Functions** (nothing needs a trusted
server; security rules do the enforcing), and **any backend of our own**. There
is no API layer — the app talks to Firestore directly and the rules are the
authorisation boundary.

---

## 15.5 Android build toolchain

| | Version |
| --- | --- |
| Gradle | 9.3.1 |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
| `google-services` plugin | 4.4.4 |
| JDK | 17.0.12 LTS (source, target and JVM target all 17) |

SDK levels, from [`android/app/build.gradle.kts`](../android/app/build.gradle.kts):

| | Value | Meaning |
| --- | --- | --- |
| `minSdk` | 24 | Android 7.0 Nougat and up |
| `targetSdk` | 36 | Android 16 |
| `compileSdk` | 36 | Android 16 |

Release build specifics:

* **R8** is on — `isMinifyEnabled` and `isShrinkResources`. Firebase and Flutter
  ship their own consumer ProGuard rules, so `proguard-rules.pro` only guards
  reflective entry points R8 can't see.
* **Signed with the debug keystore.** Enough to sideload for a demo or a
  submission; not enough for the Play Store, which needs a real upload key.
  Consequence: a rebuild on a different machine produces a different signature
  and won't install over the old app. Detail in [doc 7](07-android-apk.md).
* **Universal APK** carrying `arm64-v8a`, `armeabi-v7a` and `x86_64`, so one
  file installs on any phone.
* The **NDK** is required even though no Dart dependency compiles native code —
  AGP uses it to strip debug symbols from the Flutter engine's bundled `.so`
  files.

No Android Studio is involved; the SDK was installed as command-line tools only
([doc 3](03-android-sdk-setup.md)).

---

## 15.6 Firestore data model

Eight collections, enforced by [`firestore.rules`](../firestore.rules):

```
users/{uid}
users/{uid}/progress/{lessonId}
users/{uid}/attempts/{attemptId}
public_profiles/{uid}                 <- display name only
lessons/{lessonId}
lessons/{lessonId}/questions/{questionId}
forum_posts/{postId}
forum_posts/{postId}/replies/{replyId}
```

`public_profiles` exists because `users/{uid}` holds an email and a role, and
Firestore rules cannot restrict a read to particular fields — so "everyone may
read everyone's display name" is only expressible as a second collection. It is
what the `@mention` picker reads. Posts additionally carry `topics[]` (a post
can sit in several channels) and `mentionedUids[]`, resolved when the message is
written so the Mentions view needs no extra query. See
[doc 16](16-community-and-mentions.md).

One composite index, in [`firestore.indexes.json`](../firestore.indexes.json):
`attempts` on `lessonId` ascending + `createdAt` descending, which backs the
"most recent attempt for this lesson" query.

The rules enforce that a learner can read and write only their own `users/{uid}`
subtree; that a learner may publish a display name only under their own uid in
`public_profiles`, which anyone signed in may read; that `lessons` and their
`questions` are readable by any signed-in user but writable only by an admin; and that a forum post may be edited or deleted
only by its author or an admin — with one carve-out, so any signed-in user may
change `replyCount` alone, which is how replying works. Nothing is readable
while signed out. Field-by-field explanation is in
[doc 9](09-firestore-rules.md); the shape of each document is in
[doc 12, §12.2](12-architecture.md).

---

## 15.7 Code layout

| Directory | Files | Holds |
| --- | --- | --- |
| `lib/models/` | 7 | Plain data classes with `fromDoc`/`toMap`. No logic beyond derived getters. |
| `lib/data/` | 8 | Repositories — the only code that touches Firestore or Cloudinary. |
| `lib/providers/` | 6 | Riverpod wiring: streams in, derived state out. |
| `lib/screens/` | 36 | One directory per feature area: welcome, auth, dashboard, lessons, quiz, progress, forum, settings, admin, shell. |
| `lib/widgets/` | 13 | Shared UI — cards, tiles, rings, the press-and-sound wrapper, and the hand-drawn motifs. |
| `lib/core/` | 5 | Theme, sound service, config, constants. |
| `lib/router/` | 1 | All routes and the auth redirect. |

The rule the layout follows: screens never import `cloud_firestore`. Widgets
never read providers they weren't given. Models hold no I/O. See
[doc 12, §12.1](12-architecture.md).

---

## 15.8 Assets

| Asset | Count | Source |
| --- | --- | --- |
| Sound cues | 6 WAV | Generated by [`tool/generate_sounds.py`](../tool/generate_sounds.py) |
| Confetti animation | 1 Lottie JSON | Generated by [`tool/generate_lottie.py`](../tool/generate_lottie.py) |
| Fonts | 2 variable TTF | Nunito (body), Outfit (headings) |
| Images | 1 PNG | The Google "G" for the sign-in button |

The sound cues are `tap`, `correct`, `incorrect`, `complete`, `post` and
`celebrate`, declared as an enum in
[`lib/core/sound/sound_service.dart`](../lib/core/sound/sound_service.dart).

Both the sounds and the Lottie file are **generated by committed Python
scripts** rather than downloaded, so there is no licensing question about any
bundled media and either can be regenerated or replaced. Details and the
regeneration commands are in [doc 10](10-assets-sound-animation.md).

Fonts are bundled rather than fetched from Google Fonts at runtime, so the app
renders correctly offline and on first launch.

**The distinctive visuals are not assets.** The landing-page trail
(`signing_space.dart`), the lesson path (`lesson_path.dart`) and the practice
chart (`practice_strip.dart`) are drawn with `CustomPaint` and `PathMetric`.
Nothing to license, nothing to download, and they re-colour themselves from the
theme in either brightness.

---

## 15.9 Testing and quality

154 tests in 16 files, all passing, with the analyzer reporting zero issues.

| File | Covers |
| --- | --- |
| `widget_test.dart` | `ProgressSummary` derivation, theme extensions, responsive grid, status pills |
| `streak_test.dart` | The day-streak rule: what counts as activity, midnight rollover, gaps |
| `auth_redirect_test.dart` | The router's redirect rules, as a pure function |
| `watch_route_test.dart` | The rewatch intent surviving a round-trip through the URL |
| `watch_action_test.dart` | Which action a lesson offers given its progress |
| `resume_point_test.dart` | Where a part-watched video resumes |
| `hero_tag_test.dart` | A regression: shell branches colliding on one Hero tag |
| `video_screen_layout_test.dart` | The video screen laying out even when the player can't load |
| `dashboard_logic_test.dart` | Which finished lesson is worth revisiting; what the admin console flags |
| `dashboard_role_test.dart` | A learner never sees the console, an admin never sees the badges |
| `lesson_path_test.dart` | Path geometry: 0 and 1 lessons, and nodes staying inside the column |
| `forum_mentions_test.dart` | Handles, the email that isn't a mention, shared first names, channels, unread rules, derived titles |
| `practice_history_test.dart` | Attempts bucketed by calendar day, including either side of midnight |
| `main_screens_layout_test.dart` | Library, progress and community at four viewport sizes |
| `welcome_screen_layout_test.dart` | The landing page at five viewport sizes, and with reduced motion |
| `pop_or_test.dart` | A back link on a route that was opened cold |

The pattern worth noting: the logic that would be awkward to test through a
widget is extracted into pure functions — `authRedirect`, `watchActionFor`,
`Routes.isRewatch`, `ProgressSummary.from`, and more recently `recallCandidate`,
`LibrarySnapshot.from`, `practiceHistory`, `resolveMentions`, `unreadIn` and
`titleFromMessage` — so the tests need neither a live Firebase nor a mounted
navigator.

The layout tests exist because this project has repeatedly shipped unbounded-
constraint bugs that only appear at viewport sizes nobody develops at. Two were
caught by these tests rather than by a user: a hero that overflowed by 61px on a
360×640 phone, and a badge tile that overflowed its row by 9px whenever its
label wrapped to a third line.

Run them with `flutter test`, and `flutter analyze` for the lints.

---

## 15.10 Platform support

| Platform | Status |
| --- | --- |
| Android | **Primary.** 7.0+ (API 24). The graded deliverable. |
| Web | **Supported.** Deployed to Firebase Hosting as a backup demo. |
| iOS | **Not configured.** No `ios/` directory; `firebase_options.dart` throws for iOS. |
| macOS / Windows / Linux | Not configured. |

iOS was left out on purpose. It would need Xcode (10+ GB), a separate Firebase
iOS app, CocoaPods, a URL-scheme entry for Google Sign-In, and either a paid
Apple Developer account or a free certificate that expires after seven days —
taking the app offline mid-assessment. The web build covers anyone on an iPhone.

---

## 15.11 Reproducing this build

```bash
flutter --version          # expect 3.47.2 / Dart 3.13.2
flutter pub get
flutter analyze            # expect: No issues found!
flutter test               # expect: 154 tests passed
flutter build apk --release
```

Two files are gitignored and must be supplied before the app will run —
`lib/firebase_options.dart` and `lib/core/config/app_config.dart`. Both are
covered in [`../SETUP.md`](../SETUP.md).
