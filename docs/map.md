# Repository map

What every folder and important file does, and where to find the code for any
given thing. Written for navigating the project under pressure — in a viva, or
when you come back to it in three months.

**Contents**

1. [The ten-second version](#1-the-ten-second-version)
2. [`lib/` — all the app code](#2-lib--all-the-app-code)
3. [`test/` — the tests](#3-test--the-tests)
4. [`android/` — the native Android wrapper](#4-android--the-native-android-wrapper)
5. [`web/` — the web shell](#5-web--the-web-shell)
6. [`assets/` — bundled files](#6-assets--bundled-files)
7. [`build/` — generated output](#7-build--generated-output)
8. [Other folders](#8-other-folders)
9. [Important files, one by one](#9-important-files-one-by-one)
10. [Where is the code for…?](#10-where-is-the-code-for)
11. [Housekeeping notes](#11-housekeeping-notes)

---

## 1. The ten-second version

| Folder | What it is | Committed? |
| --- | --- | --- |
| `lib/` | **All the app code.** Everything you wrote | Yes |
| `test/` | Automated tests | Yes |
| `android/` | Native Android wrapper and build config | Yes |
| `web/` | The HTML page Flutter injects the app into | Yes |
| `assets/` | Fonts, sounds, animation, images bundled into the app | Yes |
| `docs/` | Documentation | Yes |
| `tool/` | Python scripts that generate the sound and animation assets | Yes |
| `build/` | **Generated.** Compiled output — APKs, the web bundle | No |
| `release/` | Built APKs kept for sharing | No |
| `.dart_tool/`, `.gradle/`, `.idea/` | Tool and editor caches | No |

**The one-line answer if asked:** *"`lib/` is the application; everything else is
either configuration, tests, assets, or generated output."*

---

## 2. `lib/` — all the app code

78 Dart files, ~16,300 lines. This is the project.

```
lib/
├── main.dart              entry point — starts Firebase, then the app
├── firebase_options.dart  generated Firebase config (gitignored)
├── core/                  cross-cutting concerns
├── models/                data classes
├── data/                  everything that talks to Firestore or the network
├── providers/             state wiring (Riverpod)
├── router/                routes and the auth redirect
├── screens/               one folder per feature area
└── widgets/               shared UI components
```

The layering rule that holds the whole thing together:

```
screens / widgets  →  providers  →  data (repositories)  →  Firebase / Cloudinary
```

**A widget never imports `cloud_firestore`.** A screen watches a provider; a
provider calls a repository; a repository is the only thing holding a database
handle.

### `lib/core/` — cross-cutting concerns

Things used everywhere that belong to no single feature.

| Path | Holds |
| --- | --- |
| `core/constants.dart` | Tunable numbers: 70% pass mark, 95% video-watched threshold, category list, forum topics, upload size limits |
| `core/theme/app_theme.dart` | The whole visual system — colours generated from one seed, text styles, component themes, the category tints for light and dark |
| `core/sound/sound_service.dart` | Plays the six interaction sounds, with pooling and debounce |
| `core/config/app_config.dart` | Cloudinary cloud name and upload preset (**gitignored**) |
| `core/config/app_config.example.dart` | The template you copy to create the above |

### `lib/models/` — data classes

7 files. Plain Dart objects with `fromDoc()` to read from Firestore and
`toMap()` to write back. Almost no logic — **except one**.

| File | Represents |
| --- | --- |
| `app_user.dart` | A user: uid, email, displayName, role |
| `lesson.dart` | A lesson: title, category, videoUrl, duration |
| `question.dart` | One quiz question with its options and correct index |
| `lesson_progress.dart` | Per-lesson state: status, videoCompleted, quizPassed |
| `quiz_attempt.dart` | One finished quiz run |
| `forum_post.dart` | A post and a reply |
| **`progress_summary.dart`** | **The only file that computes a number.** Pure Dart, no Firebase import — which is exactly why it is directly unit-testable |

### `lib/data/` — the only code that touches the outside world

8 files. Every Firestore read and write, and the Cloudinary upload.

| File | Responsibility |
| --- | --- |
| `firestore_refs.dart` | Every collection path, named once. Change a path here, not in forty places |
| `auth_repository.dart` | Sign up, sign in, Google sign-in, profile creation, the public directory |
| `lesson_repository.dart` | Reading lessons and questions; admin writes |
| `progress_repository.dart` | The three transactional writes that move a lesson's state |
| `forum_repository.dart` | Posts, replies, the reply counter |
| `cloudinary_service.dart` | Unsigned multipart video upload |
| `seed_data.dart` | The demo lessons, questions and forum threads |
| `seed_service.dart` | Writes the above through the repositories |

### `lib/providers/` — state wiring

6 files. No business logic here — this layer connects repositories to screens.

| File | Provides |
| --- | --- |
| `app_providers.dart` | Firebase instances, the repositories, injected singletons |
| `auth_providers.dart` | Who is signed in, their profile, whether they are admin |
| `lesson_providers.dart` | The lesson list, filters, search |
| `progress_providers.dart` | **`progressSummaryProvider`** — the live progress engine |
| `forum_providers.dart` | Posts, channels, mentions, unread counts |
| `settings_providers.dart` | Theme mode, sound on/off |

### `lib/router/`

One file, `app_router.dart`. Every route, the `StatefulShellRoute` that drives
the tabs, the `authRedirect()` function, and the `popOr()` extension.

### `lib/screens/` — one folder per feature

36 files.

| Folder | Screens |
| --- | --- |
| `welcome/` | The public landing page |
| `auth/` | Login, sign-up, the shared form scaffold, Google button, sign-out |
| `shell/` | The tab bar / navigation rail, and the splash screen |
| `dashboard/` | **Two homes behind one route** — see below |
| `lessons/` | Library, lesson detail, video player |
| `quiz/` | Quiz and results |
| `progress/` | The stats screen, and the practice-history calculation |
| `forum/` | Channel list, thread view, composer, channels and mentions logic |
| `admin/` | Add-lesson form, seed-content sheet |
| `settings/` | Theme, sound, sign out |

**`dashboard/` is worth knowing in detail**, because it holds two entirely
different screens plus pure logic:

| File | What it is |
| --- | --- |
| `dashboard_screen.dart` | The role switch, and nothing else — ~50 lines |
| `learner_dashboard.dart` | The learner's home |
| `admin_dashboard.dart` | The admin console |
| `lesson_path.dart` | The winding path visual |
| `dashboard_canopy.dart` | The learner's gradient header |
| `recall_nudge.dart` | **Pure** — which finished lesson is worth revisiting |
| `library_snapshot.dart` | **Pure** — what the admin console flags |

### `lib/widgets/` — shared UI

13 files used across several screens.

| File | What it draws |
| --- | --- |
| `common.dart` | Status pills, stat tiles, badges, section headers, empty and error states |
| `pressable.dart` | The tap-and-sound wrapper used on every card |
| `progress_ring.dart` | The circular ring and the progress bar |
| `lesson_card.dart` | The library card and lesson artwork |
| `screen_canopy.dart` | The gradient header on Lessons, Progress and Community |
| `signing_space.dart` | The drawn motion trail on the landing page |
| `practice_strip.dart` | The 14-day activity chart |
| `medallion.dart` | Badges as lit circles |
| `count_up.dart` | A number that counts up to its value |
| `reveal.dart` | Scroll-triggered entrance animations |
| `mention_field.dart` | `@` autocomplete and mention rendering |
| `celebration.dart` | The confetti overlay |
| `video_frame.dart` | Letterboxing so a portrait clip does not overflow |

---

## 3. `test/` — the tests

16 files, 154 tests. Run with `flutter test`.

Two kinds:

**Unit tests on pure functions** — the majority, and the fast ones. No Firebase,
no UI, no emulator.

| File | Tests |
| --- | --- |
| `widget_test.dart` | `ProgressSummary` derivation, theme, responsive grid |
| `streak_test.dart` | The day-streak rule and its gaps |
| `auth_redirect_test.dart` | Every routing decision |
| `watch_route_test.dart` | The rewatch flag surviving a URL round-trip |
| `watch_action_test.dart` | Which action a lesson offers |
| `resume_point_test.dart` | Where a part-watched video resumes |
| `dashboard_logic_test.dart` | Recall nudge and admin library snapshot |
| `forum_mentions_test.dart` | Handles, channels, unread rules, title derivation |
| `practice_history_test.dart` | Attempts bucketed by calendar day |
| `pop_or_test.dart` | A back link on a cold-opened route |

**Widget tests** — render a screen and check it lays out.

| File | Tests |
| --- | --- |
| `welcome_screen_layout_test.dart` | The landing page at five sizes, and reduced motion |
| `main_screens_layout_test.dart` | Library, Progress, Community at four sizes |
| `dashboard_role_test.dart` | Learner and admin get different screens |
| `lesson_path_test.dart` | Path geometry at 0, 1 and many lessons |
| `video_screen_layout_test.dart` | The video screen when the player cannot load |
| `hero_tag_test.dart` | A regression: two tabs colliding on one Hero tag |

---

## 4. `android/` — the native Android wrapper

Flutter needs a real Android project to compile into. You rarely edit this.

| Path | What it is |
| --- | --- |
| `android/app/build.gradle.kts` | **The important one.** `applicationId`, `minSdk`, `targetSdk`, signing |
| `android/build.gradle.kts` | Top-level Gradle config shared by all modules |
| `android/settings.gradle.kts` | Which modules and plugins the build includes |
| `android/gradle.properties` | JVM memory, AndroidX flags |
| `android/local.properties` | **Your machine's** SDK path. Not committed |
| `android/app/google-services.json` | Tells the Firebase SDK which project to use. **Gitignored** |
| `android/app/src/main/AndroidManifest.xml` | Permissions, the app name under the icon, the launcher activity |
| `android/app/src/main/res/` | App icons and launch screen |
| `android/.gradle/`, `android/.kotlin/` | **Build caches.** Generated, not committed |

**Things you actually changed in here:** `applicationId` is
`com.signals.signals`, and `android:label` is `Signals`. `minSdk` is *not*
hardcoded — it uses `flutter.minSdkVersion`, which Flutter 3.47 sets to 24.

---

## 5. `web/` — the web shell

The HTML page Flutter injects the compiled app into.

| File | What it does |
| --- | --- |
| `web/index.html` | The page. Sets the title, viewport, and loads `flutter_bootstrap.js` |
| `web/manifest.json` | Progressive-web-app metadata — name, icons, theme colour |
| `web/favicon.png`, `web/icons/` | Browser tab and install icons |

Flutter does **not** render HTML elements. It paints the entire UI onto a canvas,
which is why the web version looks identical to Android.

---

## 6. `assets/` — bundled files

Everything shipped inside the app. Declared in `pubspec.yaml`; anything not
declared there is not bundled, even if the file exists.

| Folder | Contents |
| --- | --- |
| `assets/fonts/` | `NunitoVariable.ttf` (body) and `OutfitVariable.ttf` (headings) |
| `assets/sounds/` | Six WAV cues — tap, correct, incorrect, complete, post, celebrate |
| `assets/lottie/` | `confetti.json`, the celebration animation |
| `assets/images/` | `google_g.png` for the sign-in button |

**Worth saying out loud:** the sounds and the Lottie file are **generated by the
Python scripts in `tool/`**, not downloaded — so there is no licensing question
about any bundled media. The landing-page trail, lesson path and practice chart
are not assets at all; they are drawn in code with `CustomPaint`.

---

## 7. `build/` — generated output

**Nothing here is yours.** It is all produced by `flutter build` and is
gitignored. Deleting it costs you a rebuild and nothing else.

| Path | What it is |
| --- | --- |
| `build/web/` | The compiled web app — this is what gets deployed |
| `build/app/outputs/flutter-apk/` | The compiled APKs |
| `build/<plugin-name>/` | Intermediate output for each Firebase and plugin module |
| `build/flutter_assets/` | Assets packed for bundling |

**The APKs:**

| File | Use |
| --- | --- |
| `app-arm64-v8a-release.apk` | ~23 MB. **Share this one** — every modern phone |
| `app-release.apk` | ~60 MB universal. Fallback |
| `app-armeabi-v7a-release.apk` | Old 32-bit devices |
| `app-x86_64-release.apk` | Emulators |
| `app-debug.apk` | ~210 MB. **Never share** |

`flutter clean` empties this folder. It is the first thing to try when a build
behaves strangely.

---

## 8. Other folders

| Folder | What it is |
| --- | --- |
| `docs/` | Documentation — 17 numbered guides plus the viva prep and this map |
| `tool/` | `generate_sounds.py` and `generate_lottie.py`, which produce the audio and animation assets |
| `release/` | Renamed APK copies for sharing. Gitignored |
| `.dart_tool/` | Dart's package resolution cache. Generated |
| `.firebase/` | Firebase CLI deploy cache — records what was last uploaded |
| `.idea/`, `.vscode/`, `signals.iml` | Editor settings |
| `.git/` | Git's own storage |

---

## 9. Important files, one by one

### `pubspec.yaml`

The project manifest — Flutter's `package.json`. Declares four things:

1. **Name and version** — `version: 1.0.0+1` is version name + build number
2. **SDK constraint** — `sdk: ^3.13.2`
3. **Dependencies** — every package, with version constraints
4. **Assets and fonts** — which folders get bundled

The `^` in `^4.15.0` means "this or any later version that does not change the
major number" — 4.9 is fine, 5.0 is not, because a major bump may break the API.

### `pubspec.lock`

The **exact** version of every package actually resolved, including transitive
ones. `pubspec.yaml` says "4.15.0 or compatible"; the lock file says "exactly
4.15.2".

**Committed**, because this is an application and you want reproducible builds.
(For a library you would not commit it.)

### `.gitignore`

What Git ignores. Four groups:

| Group | Why |
| --- | --- |
| `build/`, `.dart_tool/`, `android/.gradle/` | Generated and rebuildable |
| `*.iml`, `.idea/` | Editor settings, personal to your machine |
| `firebase_options.dart`, `app_config.dart`, `google-services.json`, `.firebaserc` | Project config. Not secrets — identifiers — but a clone should not point at your accounts |
| `release/` | Built APKs |

### `analysis_options.yaml`

Static analysis config. Includes `flutter_lints`, excludes generated folders, and
disables two specific rules, each with a comment explaining why. `flutter
analyze` reports zero issues.

### `firebase.json`

Firebase CLI config. Declares the deploy folder (`build/web`), the SPA rewrite
sending every URL to `index.html`, the **cache headers**, and where the rules and
index files live.

The cache headers matter: Flutter's filenames have no content hash, so marking
`main.dart.js` immutable would pin returning visitors to an old build. They use
`no-cache, must-revalidate` for that reason.

### `firestore.rules`

**The backend logic.** Runs on Google's servers on every read and write. Enforces
the admin-only lesson writes, data ownership, no self-promotion to admin, and
append-only quiz attempts.

### `firestore.indexes.json`

Composite indexes. Firestore auto-indexes single fields; a query that filters on
one and sorts by another needs one declared. There is one: `attempts` on
`lessonId` + `createdAt`.

### `.firebaserc`

Maps the local folder to the Firebase project ID. Gitignored.

### `.metadata`

Generated by Flutter. Records which version created the project so upgrades can
apply migrations. Committed, never hand-edited.

### `README.md` / `SETUP.md`

The front door, and the zero-to-running guide.

---

## 10. Where is the code for…?

### Q. Where is your code for storing data in Firebase?

**`lib/data/` — the repositories.** That is the *only* place in the entire
codebase that writes to Firestore.

Specifically:

| What gets stored | File | Method |
| --- | --- | --- |
| A new lesson and its quiz | `lesson_repository.dart` | `createLesson()` — one batch write |
| Video progress | `progress_repository.dart` | `markVideoStarted()`, `markVideoCompleted()` |
| A quiz result | `progress_repository.dart` | `submitAttempt()` — one transaction |
| A forum post | `forum_repository.dart` | `createPost()` |
| A reply | `forum_repository.dart` | `addReply()` — batched with the counter |
| A user profile | `auth_repository.dart` | `ensureProfile()` |
| A video file | `cloudinary_service.dart` | Uploads to Cloudinary, not Firebase |

**The collection paths themselves** are all in `firestore_refs.dart`, named once.

### Q. Where is the code that reads data from Firebase?

Same files. Reads use `.snapshots()`, which subscribes rather than fetching once
— for example `lesson_repository.dart` line 18. That is why the app updates live.

### Q. Where is the code for authentication?

`lib/data/auth_repository.dart` — sign up, sign in, Google sign-in, sign out,
password reset. The "who is signed in right now" state is in
`lib/providers/auth_providers.dart`.

### Q. Where is the business logic?

Deliberately split out of the UI into pure functions:

| Logic | File |
| --- | --- |
| Every progress statistic | `models/progress_summary.dart` |
| Routing decisions | `router/app_router.dart` → `authRedirect()` |
| The lesson state machine | `data/progress_repository.dart` |
| Which lesson to revisit | `screens/dashboard/recall_nudge.dart` |
| Admin library analysis | `screens/dashboard/library_snapshot.dart` |
| Channels, unread, titles | `screens/forum/channels.dart` |
| Mention parsing | `screens/forum/mentions.dart` |
| Practice history | `screens/progress/practice_history.dart` |

### Q. Where is the security enforced?

`firestore.rules`, in the **project root** — not in `lib/`. That is the point:
it runs on Google's servers, so modifying the app cannot bypass it.

### Q. Where does the app start?

`lib/main.dart`. It initialises Firebase, loads SharedPreferences and the sound
service, injects both into Riverpod, then runs `SignalsApp`. It also has a
fallback error screen, so a startup failure shows the reason instead of a blank
white page.

### Q. Where are the colours and fonts defined?

`lib/core/theme/app_theme.dart`. The whole palette generates from one seed
colour (`#6C5CE7`). Category tints have separate light and dark values, because
the light ones are too bright to stay distinguishable on a dark surface.

### Q. Where is the admin-only functionality?

- **UI:** `lib/screens/admin/` and `lib/screens/dashboard/admin_dashboard.dart`
- **Enforcement:** `firestore.rules` — the `isAdmin()` function

The UI hiding admin screens is cosmetic. The rules are what actually stop a
learner writing a lesson.

### Q. Where is the video upload code?

`lib/data/cloudinary_service.dart` — an unsigned multipart POST. The admin form
that calls it is `lib/screens/admin/add_lesson_screen.dart`.

### Q. Where are the quiz questions stored?

Firestore, as a **subcollection** of their lesson:
`lessons/{lessonId}/questions/{questionId}`. The paths are in
`firestore_refs.dart`; the model is `models/question.dart`.

### Q. Where is the @mention logic?

`lib/screens/forum/mentions.dart` — parsing, resolution and rendering, all pure.
The UI is `lib/widgets/mention_field.dart`.

### Q. Where is the navigation defined?

`lib/router/app_router.dart` — one file holds every route, the tab shell and the
auth redirect.

### Q. Where would I add a new screen?

1. Create the file in `lib/screens/<feature>/`
2. Add a `GoRoute` in `lib/router/app_router.dart`
3. If it needs data, add or reuse a provider in `lib/providers/`
4. If that data is new, add a method to a repository in `lib/data/`

Never call Firestore from the screen directly.

### Q. Where are the app icon and name set?

- **Android:** `android/app/src/main/AndroidManifest.xml` (`android:label`) and
  `android/app/src/main/res/` for the icon
- **Web:** `web/index.html`, `web/manifest.json`, `web/favicon.png`
- **In-app:** `lib/main.dart` (`title:`) and the wordmark on the splash and
  landing screens

### Q. Where is the deployed web build?

`build/web/` locally, and Firebase Hosting serves it at
`signals-app-a7b29.web.app`. The folder is gitignored because it is generated.

---

## 11. Housekeeping notes

Two things in the tree that are untidy rather than wrong. Better to know than to
be asked about them:

- **`assets/fonts/Baloo2Variable.ttf` is no longer used.** It was the display
  font before the switch to Outfit, and it is no longer declared in
  `pubspec.yaml` — so it is not bundled into any build, but the 667 KB file is
  still sitting in the repository. Safe to delete.
- **`lib/core/util/` is an empty directory.** Git does not track empty folders,
  so it exists only on this machine.
- **`error.md` in the project root** is a captured debug log from a web run, not
  documentation. It was committed with the initial import.
