# Signals

A Flutter app for learning sign language. A public landing page, video lessons,
quizzes, real live-calculated progress, and a community laid out like a chat
client — with an admin role that can publish new lessons and quiz questions at
any time, without an app rebuild.

Android + Web · Riverpod · go_router · Material 3 · Firebase Auth + Firestore ·
Cloudinary video hosting.

## Start here

**[`SETUP.md`](SETUP.md)** — setup and demo, for Android and macOS.

Per-step guides live in **[`docs/`](docs/00-index.md)**, one file per process:

| | |
| --- | --- |
| [Firebase setup](docs/01-firebase-setup.md) | [Cloudinary setup](docs/02-cloudinary-setup.md) |
| [Android SDK on macOS](docs/03-android-sdk-setup.md) | [Admin account](docs/04-admin-account.md) |
| [Demo content](docs/05-seed-data.md) | [Running on a MacBook](docs/06-run-on-macbook.md) |
| [Building the APK](docs/07-android-apk.md) | [Deploying the web build](docs/08-web-deploy.md) |
| [Security rules](docs/09-firestore-rules.md) | [Assets, sound, animation](docs/10-assets-sound-animation.md) |
| [Demo script](docs/11-demo-script.md) | [Architecture](docs/12-architecture.md) |
| [Troubleshooting](docs/13-troubleshooting.md) | [Google sign-in](docs/14-google-sign-in.md) |
| [Tech stack](docs/15-tech-stack.md) | [Community & mentions](docs/16-community-and-mentions.md) |

## Quick start

```bash
flutter pub get

# one-time config (see docs 1 and 2)
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,web \
  --android-package-name=com.signals.signals --yes
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart  # then edit it

firebase deploy --only firestore:rules,firestore:indexes

flutter analyze && flutter test
flutter run -d chrome
```

## What's notable

**Progress is real.** Nothing derived is stored in Firestore. Three streams —
lessons, progress documents, quiz attempts — feed one pure computation that re-runs
whenever any of them emits, so finishing a quiz moves the dashboard immediately with
no refresh. Unit-tested in [`test/widget_test.dart`](test/widget_test.dart).

**The role split is enforced, not hidden.** [`firestore.rules`](firestore.rules)
permits lesson writes only when the caller's own `users/{uid}.role` is `admin`, and
forbids changing your own role — so admin is grantable only from the Firebase
console.

**No Firebase Storage.** Videos go to Cloudinary via an unsigned client upload, so
the whole app stays on free tiers and no API secret ships inside it.

**Assets are generated, not stubbed.** The six interaction sounds and the confetti
Lottie are synthesised by scripts in [`tool/`](tool/) — original and
royalty-free. See [docs/10](docs/10-assets-sound-animation.md). The landing page
and the lesson path are drawn with `CustomPaint` rather than shipped as
illustrations.

**Learners and admins get different screens**, not one screen with an extra card.
The switch reads the same `role` field the security rules enforce on, so the UI
cannot promise something the backend will refuse.

**The community is a chat client.** Channels, multi-channel posts, `@mentions`
resolved at write time, and per-channel unread counts. Mentions needed a
`public_profiles` collection holding a display name and nothing else, because
`users/{uid}` carries an email and Firestore cannot restrict a read to
particular fields — [docs/16](docs/16-community-and-mentions.md).

**Colour is validated, not eyeballed.** The six category tints have separate
dark-mode steps, because the light ones sit outside the lightness band where
categorical colour stays separable on a dark surface.

## Layout

```
lib/core/        constants, seed-based M3 theme, sound service, config
lib/models/      data classes; ProgressSummary holds the derived stats
lib/data/        repositories, Cloudinary upload, seed data
lib/providers/   Riverpod wiring
lib/router/      go_router + StatefulShellRoute tabs, popOr()
lib/screens/     one folder per feature area
                 welcome/ is the public landing page
                 dashboard/ holds two homes behind one route
lib/widgets/     shared UI kit, incl. the CustomPaint motifs
tool/            asset generators
```

[`docs/12-architecture.md`](docs/12-architecture.md) has the data model and the
design decisions, including the deliberate simplifications.
