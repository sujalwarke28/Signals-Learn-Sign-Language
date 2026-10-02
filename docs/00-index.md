# Signals · documentation index

Every setup or process step has its own file. Work through them in order the
first time; after that, jump straight to the one you need.

| # | Doc | What it covers |
| --- | --- | --- |
| — | [`../SETUP.md`](../SETUP.md) | Start here. The short path from zero to a running app, on both Android and a MacBook. |
| 1 | [`01-firebase-setup.md`](01-firebase-setup.md) | Creating the Firebase project, enabling email auth, creating Firestore, generating `firebase_options.dart`. |
| 2 | [`02-cloudinary-setup.md`](02-cloudinary-setup.md) | Cloudinary account, cloud name, and the unsigned upload preset used for lesson videos. |
| 3 | [`03-android-sdk-setup.md`](03-android-sdk-setup.md) | Installing the Android SDK on macOS without Android Studio, and pointing Flutter at it. |
| 4 | [`04-admin-account.md`](04-admin-account.md) | Creating your account and promoting it to `admin`. |
| 5 | [`05-seed-data.md`](05-seed-data.md) | Loading the demo lessons, quizzes and forum threads. |
| 6 | [`06-run-on-macbook.md`](06-run-on-macbook.md) | Running the app from source on macOS — web, emulator, or a plugged-in phone. |
| 7 | [`07-android-apk.md`](07-android-apk.md) | Building the release APK and installing it on an Android phone. |
| 8 | [`08-web-deploy.md`](08-web-deploy.md) | Building the web bundle and deploying it to Firebase Hosting. |
| 9 | [`09-firestore-rules.md`](09-firestore-rules.md) | What the security rules enforce, how to deploy them, and how to test them. |
| 10 | [`10-assets-sound-animation.md`](10-assets-sound-animation.md) | Where the fonts, sound cues and the Lottie confetti come from, and how to regenerate or replace them. |
| 11 | [`11-demo-script.md`](11-demo-script.md) | The click-path to demo the app end to end, with what to say at each step. |
| 12 | [`12-architecture.md`](12-architecture.md) | How the code is organised, the Firestore data model, and how live progress is calculated. |
| 13 | [`13-troubleshooting.md`](13-troubleshooting.md) | Every error we've hit, and the fix. |
| 14 | [`14-google-sign-in.md`](14-google-sign-in.md) | Enabling the Google provider, and the Android SHA-1 fingerprint it needs. |
| 15 | [`15-tech-stack.md`](15-tech-stack.md) | Every technology, package and tool the project uses, with resolved versions and what each does. |
| 16 | [`16-community-and-mentions.md`](16-community-and-mentions.md) | Channels, @mentions, the `public_profiles` directory, and unread counts. |

## The two things only you can do

The app needs two external accounts. Nothing else is required.

1. **Firebase** — auth and database. Free Spark plan. See doc 1.
2. **Cloudinary** — video hosting. Free plan. See doc 2.

Neither stores a genuine secret inside the app: Firebase web/Android API keys
are project identifiers guarded by security rules, and the Cloudinary upload
preset only permits adding a file to one folder. Both are still gitignored so a
clone of this repo doesn't point at your accounts.
