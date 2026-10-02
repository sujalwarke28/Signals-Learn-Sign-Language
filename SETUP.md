# Signals — Setup & Demo Guide

**Signals** is a Flutter app for learning sign language. Learners browse video
lessons, watch them, take quizzes, track real live-calculated progress, and talk
in a community forum. Admins publish new lessons and quiz questions at any time,
and learners see them immediately — no app update.

Android + Web. Firebase Auth + Cloud Firestore + Cloudinary. All on free tiers.

> Every step below has a dedicated, detailed doc in [`docs/`](docs/00-index.md).
> This file is the short path.

---

## Contents

1. [What you need](#1-what-you-need)
2. [Install the APK on an Android phone](#2-install-the-apk-on-an-android-phone)
3. [Set up and run on a MacBook](#3-set-up-and-run-on-a-macbook)
4. [First-run setup inside the app](#4-first-run-setup-inside-the-app)
5. [Demo the app end to end](#5-demo-the-app-end-to-end)
6. [Config, keys and files](#6-config-keys-and-files)
7. [What's in the box](#7-whats-in-the-box)
8. [If something breaks](#8-if-something-breaks)

---

## 1 · What you need

Two free accounts. Nothing else.

| Service | What for | Doc |
| --- | --- | --- |
| **Firebase** | Email/password auth + Firestore database | [`docs/01-firebase-setup.md`](docs/01-firebase-setup.md) |
| **Cloudinary** | Lesson video hosting | [`docs/02-cloudinary-setup.md`](docs/02-cloudinary-setup.md) |

Firebase Storage is **not** used — it now requires the paid Blaze plan, so videos
go to Cloudinary instead. Everything here works on Firebase's free Spark plan.

To build from source you also need Flutter, and for the APK the Android SDK:

| Tool | Version used | Doc |
| --- | --- | --- |
| Flutter | 3.47.2 (Dart 3.13.2) | [`docs/06-run-on-macbook.md`](docs/06-run-on-macbook.md) |
| Android SDK | platform 36, build-tools 36.0.0 | [`docs/03-android-sdk-setup.md`](docs/03-android-sdk-setup.md) |

---

## 2 · Install the APK on an Android phone

For running the finished app without building anything.

### 2a · With a USB cable (easiest)

1. On the phone: **Settings → About phone** → tap **Build number** 7 times.
2. **Settings → System → Developer options** → enable **USB debugging**.
3. Plug the phone into the Mac; on the phone tap **Always allow** → **Allow**.
4. On the Mac:

   ```bash
   adb devices     # your phone should be listed, not "unauthorized"
   adb install -r app-release.apk
   ```

   `-r` replaces an existing install without wiping its data.

### 2b · From the APK file, no cable

1. **Get the file onto the phone** — Google Drive, email it to yourself, Nearby
   Share, or USB in file-transfer mode.
2. **Open it** from wherever you put it (Files, Drive, Gmail).
3. Android will say *"your phone is not allowed to install unknown apps from this
   source"* → tap **Settings** → toggle **Allow from this source** on → go back and
   tap the APK again.

   To set this in advance: **Settings → Apps → Special app access → Install unknown
   apps** → choose the app you'll open the APK from → **Allow from this source**.
   (Older Android: **Settings → Security → Unknown sources**.)
4. Tap **Install**. Play Protect may warn *"Unsafe app blocked"* — normal for any
   app not from the Play Store. Tap **More details → Install anyway**.
5. Tap **Open**.

### 2c · Building the APK yourself

```bash
cd ~/Desktop/Signals
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

**On signing:** the release APK is signed with Flutter's debug keystore. That's
fine for installing by hand and for a demo; it is *not* valid for the Play Store,
and an APK rebuilt on a different machine won't install over an older one
(uninstall first). Full detail: [`docs/07-android-apk.md`](docs/07-android-apk.md).

---

## 3 · Set up and run on a MacBook

### 3.1 Install Flutter

```bash
xcode-select --install                    # git + clang
brew install --cask flutter               # or download the SDK zip
flutter --version
flutter doctor
```

You need ✓ on **Flutter** and **Chrome**. For the APK you also need ✓ on
**Android toolchain**. The Xcode / CocoaPods warnings don't matter — iOS is out of
scope for this project.

No Android SDK? You don't need Android Studio:

```bash
brew install --cask android-commandlinetools
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-36" "build-tools;36.0.0"
flutter config --android-sdk $ANDROID_HOME
```

Details: [`docs/03-android-sdk-setup.md`](docs/03-android-sdk-setup.md).

### 3.2 Dependencies

```bash
cd ~/Desktop/Signals
flutter pub get
```

### 3.3 Add the two config files

Neither is in the repo. Both are one-time.

**Firebase** — create the project, enable Email/Password auth, create Firestore
(see [`docs/01-firebase-setup.md`](docs/01-firebase-setup.md)), then:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
firebase login

flutterfire configure \
  --project=YOUR_FIREBASE_PROJECT_ID \
  --platforms=android,web \
  --android-package-name=com.signals.signals \
  --yes
```

This writes `lib/firebase_options.dart` and `android/app/google-services.json`.
The package name must be exactly `com.signals.signals`.

**Cloudinary** — create the account and an **unsigned** upload preset (see
[`docs/02-cloudinary-setup.md`](docs/02-cloudinary-setup.md)), then:

```bash
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
```

and put your cloud name and preset name in the copy.

### 3.4 Deploy the security rules

**Nothing in the app works until you do this** — a production-mode Firestore
denies every read until rules are published.

```bash
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes
```

### 3.5 Verify, then run

```bash
flutter analyze     # expect: No issues found
flutter test        # expect: All tests passed

flutter run -d chrome        # web — fastest loop
flutter run                  # connected phone or emulator
flutter run --release        # closer to real-world performance
```

### 3.6 Build the deliverables

```bash
flutter build apk --release      # -> build/app/outputs/flutter-apk/app-release.apk
flutter build web --release      # -> build/web/
```

Deploying the web build to Firebase Hosting:

```bash
firebase init hosting
#   public directory:                build/web
#   single-page app rewrite:         YES   <- required, go_router owns the routes
#   overwrite build/web/index.html:  NO    <- saying yes gives you a blank page
firebase deploy --only hosting
# -> https://YOUR-PROJECT-ID.web.app
```

Details: [`docs/08-web-deploy.md`](docs/08-web-deploy.md).

---

## 4 · First-run setup inside the app

A fresh Firebase project has no users and no content. Three steps, about two
minutes.

### 4.1 Create your account

Run the app, tap **Create an account**, fill in name / email / password. You land
on the dashboard as a **learner**.

### 4.2 Promote it to admin

There is deliberately no way to do this from inside the app — the security rules
reject any attempt to change your own role, so admin can only be granted from the
console.

1. [Firebase console](https://console.firebase.google.com) → your project →
   **Firestore Database → Data → `users`**.
2. Open the single document there (the long ID is your Auth UID).
3. Edit the **`role`** field: `learner` → `admin` (lowercase). **Update**.

No restart needed — the profile is streamed. Within a second the app shows an
**Admin** badge, an **Admin tools** card on the dashboard, and a **New lesson**
button on the Lessons tab.

Details: [`docs/04-admin-account.md`](docs/04-admin-account.md).

### 4.3 Load the demo content

As the admin: avatar (top-right) → **Profile & settings** → **Admin → Demo
content** → **Load demo content**.

That writes 10 ASL lessons with 4 quiz questions each, plus 4 forum threads with
replies. It runs as the signed-in admin through the normal security rules, so a
successful seed also confirms your rules and role are correct.

Two things to know before you demo it:

* **The seeded lesson videos are placeholder clips, not sign-language footage.**
  They're short public sample videos (12–20s) so the player, watch-progress and
  quiz-unlock can be shown end to end. Every seeded lesson is flagged as a
  placeholder and the app says so on the lesson screen. Replace them by publishing
  real lessons through the admin screen.
* **The quiz questions are real ASL content, not verified against an authoritative
  dictionary.** They cover the one-handed alphabet, the 6–9 thumb pattern, family
  signs' high/low gender pattern, initialised colour signs and non-manual markers —
  written from general knowledge of ASL. Say so if asked.

Details: [`docs/05-seed-data.md`](docs/05-seed-data.md).

### 4.4 Optional but recommended: a second account

Sign out and create a second account, leaving it as a **learner**. Having both
lets you demo the admin→learner flow properly, and show that the learner has no
admin UI at all. Two browser windows (one incognito) shows both at once.

---

## 5 · Demo the app end to end

The full script with what to say at each step is in
[`docs/11-demo-script.md`](docs/11-demo-script.md). The click-path:

**Admin publishes → learner sees it instantly**
1. Admin → **Lessons → New lesson** → choose a short video → **Upload** (goes to
   Cloudinary; duration is read from the file) → title, category, difficulty,
   description → write a quiz question, mark the correct option → **Publish**.
2. Switch to the learner. **The lesson is already in their library.** No update.

**Lesson → video → quiz unlock**
3. **Lessons** → note the status pill per card (not started / in progress /
   completed).
4. Tap a lesson — **the thumbnail flies from card to detail header** (Hero).
5. The detail screen shows the three steps to finish, and **the quiz button is
   locked**.
6. **Start lesson** → playback begins → the lesson flips to *in progress*.
7. At 95% watched, the **quiz unlocks** with a sound and the bar turns green.

**Quiz → results**
8. **Try to advance with nothing selected** — the button is disabled ("Pick an
   answer to continue").
9. Answer correctly → the option **bounces**, plays a bright cue, explanation
   slides in.
10. Answer wrongly → it **shakes**, plays a softer cue, the right answer turns
    green.
11. Finish → **confetti bursts** (Lottie) with a celebration sound. Score ring,
    correct / missed / percent.

**Progress updates live**
12. The results screen's **"Updated just now"** card already reflects the attempt.
13. **My progress** → overall ring, quizzes taken/passed/perfect, average of best
    attempts, day streak, per-category cards, badges, recent attempts.
14. **Home** → the completion percentage has changed. No refresh anywhere.

**Community, live**
15. **Community** → open a thread → reply.
16. **New post** → try submitting empty (validation) → publish.
17. On the other device, **the post and reply appear without a refresh**.

**Polish**
18. **Profile & settings** → flip **Theme** to dark; toggle **Interaction sounds**.
19. Open the web URL on a laptop — bottom bar becomes a side rail, lessons go
    multi-column.

### Why the progress numbers are real

There is no stored `completionPercent` anywhere. Three Firestore streams — lessons,
progress documents, quiz attempts — feed one pure computation
(`ProgressSummary.from`) that re-runs whenever any of them emits. Submitting a quiz
writes the attempt and the progress document in a single transaction; both streams
fire; every screen watching them rebuilds. That's the whole mechanism, and it's
unit-tested in `test/widget_test.dart`.

---

## 6 · Config, keys and files

### Files you create (all gitignored)

| File | Created by | Contains |
| --- | --- | --- |
| `lib/firebase_options.dart` | `flutterfire configure` | Per-platform Firebase config |
| `android/app/google-services.json` | `flutterfire configure` | Android Firebase config |
| `lib/core/config/app_config.dart` | you, from `app_config.example.dart` | Cloudinary cloud name + upload preset |
| `firebase.json`, `.firebaserc` | `firebase init` | Which project and hosting directory |

### On secrets

**None of the above holds a genuine secret**, and that's by design rather than by
accident:

* Firebase web/Android API keys **identify** a project, they don't grant access to
  it. Access is controlled entirely by the Firestore security rules. Google
  documents them as publishable.
* The Cloudinary **cloud name** appears in every delivery URL, and the **unsigned
  upload preset** only permits adding a file to the folder you configured. The
  Cloudinary **API secret is never used by this app** and must never be put in it —
  anything compiled into an APK or a web bundle can be extracted from it, which is
  exactly why the upload is unsigned.

They're gitignored anyway, so cloning this repo doesn't point at your accounts.

### Build-time overrides

Instead of keeping `app_config.dart` on disk:

```bash
flutter build apk --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=signals_unsigned
```

`--dart-define` wins over the file.

### Tunable behaviour

All in [`lib/core/constants.dart`](lib/core/constants.dart):

| Constant | Value | Meaning |
| --- | --- | --- |
| `passThresholdPercent` | 70 | Score needed to pass a lesson quiz |
| `videoCompleteFraction` | 0.95 | How much of a video counts as watched |
| `maxVideoBytes` | 100 MB | Upload cap, matching Cloudinary's free tier |
| `categories`, `difficulties`, `forumTopics` | — | Options in the admin and post forms |

---

## 7 · What's in the box

### Screens

Learning Dashboard · Lesson Library · Lesson Detail · Video Player · Practice Quiz
· Results · Progress Tracker · Community Forum (list, thread, new post) · Profile &
Settings · Admin: Add Lesson · Admin: Demo Content. Bottom navigation: Home /
Lessons / Progress / Community (a side rail at desktop width).

### Roles

One login flow, one `role` field. Learners get everything above except the admin
screens. Admins get everything plus lesson publishing. Enforced in
[`firestore.rules`](firestore.rules), not just hidden in the UI — a learner with the
raw SDK still gets `permission-denied` writing a lesson, and nobody can change
their own role.

### Source layout

```
lib/
  core/        constants, theme (seed -> M3 light/dark), sound service, config
  models/      data classes + ProgressSummary (the derived stats, pure Dart)
  data/        repositories, Cloudinary upload, seed data + seeder
  providers/   Riverpod wiring
  router/      go_router with a StatefulShellRoute for the tabs
  screens/     one folder per feature area
  widgets/     Pressable, ProgressRing, LessonCard, common kit, confetti
tool/          asset generators (sounds, Lottie)
docs/          the per-step guides
```

Full walkthrough, data model and design decisions:
[`docs/12-architecture.md`](docs/12-architecture.md).

### Assets

Fonts are bundled (Nunito + Baloo2, both SIL OFL) so nothing is fetched at
runtime. The six sound cues and the confetti animation are **generated from
scratch** by the scripts in `tool/` — original, royalty-free, and not silent stubs.
Regenerate or replace them per
[`docs/10-assets-sound-animation.md`](docs/10-assets-sound-animation.md).

### Explicitly not built

iOS build/signing · payments · push notifications · offline-first sync · i18n.

---

## 8 · If something breaks

Start with [`docs/13-troubleshooting.md`](docs/13-troubleshooting.md) — it's
grouped by symptom. The three that account for most problems:

| Symptom | Almost always |
| --- | --- |
| `Missing or insufficient permissions` | Security rules not deployed → step 3.4 |
| `Target of URI doesn't exist: 'firebase_options.dart'` | `flutterfire configure` not run → step 3.3 |
| No admin UI | `users/{uid}.role` isn't exactly `admin`, lowercase → step 4.2 |

Diagnostics:

```bash
flutter doctor -v
flutter analyze
flutter test
flutter logs
adb logcat | grep -i flutter
```

On the web, the browser console prints Firebase errors verbatim — usually the
fastest route to the cause.
