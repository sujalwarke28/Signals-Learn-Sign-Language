# 1 · Firebase setup (Auth + Firestore)

Signals uses Firebase for **Authentication** (email/password) and **Cloud
Firestore** (lessons, questions, progress, quiz attempts, forum). It does **not**
use Firebase Storage — video hosting is Cloudinary, so you never need the Blaze
plan. Everything here works on the free **Spark** plan.

Time needed: about 10 minutes.

---

## 1.1 Create the Firebase project

1. Go to <https://console.firebase.google.com> and sign in with your Google
   account.
2. Click **Create a project** (or **Add project**).
3. Project name: `signals-app` (any name works — the generated project *ID* will
   look like `signals-app-1a2b3`; note it down, you'll need it later).
4. Google Analytics: **disable** it. It isn't used and skipping it is faster.
5. Click **Create project**, wait for it to finish, then **Continue**.

## 1.2 Enable Email/Password authentication

1. In the left sidebar, open **Build → Authentication**.
2. Click **Get started**.
3. Under **Sign-in method**, click **Email/Password**.
4. Toggle **Enable** ON. Leave "Email link (passwordless sign-in)" OFF.
5. Click **Save**.

> Do **not** create any users by hand here. The app's own sign-up screen creates
> them, because it also writes the matching `users/{uid}` Firestore document that
> carries the `role` field.

For the **Google** provider on the same screen, see
[`14-google-sign-in.md`](14-google-sign-in.md) — the web build needs nothing
beyond enabling it, but Android also needs a signing fingerprint registered.

## 1.3 Create the Firestore database

1. Left sidebar → **Build → Firestore Database**.
2. Click **Create database**.
3. Location: pick the region closest to you (e.g. `asia-south1` for India, or
   `nam5 (us-central)`). **This cannot be changed later.**
4. Start in **production mode** (not test mode). The app ships its own security
   rules and we deploy them in step 1.6 — production mode just means nothing is
   readable until those rules land.
5. Click **Create**.

## 1.4 Register the app platforms

You do **not** need to click through the "Add app" wizard by hand — the
`flutterfire` CLI registers both the Android and Web app for you and writes the
config into the code. That's the next step.

## 1.5 Generate `lib/firebase_options.dart`

Run these from the project root (`~/Desktop/Signals`).

```bash
# One-time: install the CLIs
npm install -g firebase-tools          # if `firebase --version` already works, skip
dart pub global activate flutterfire_cli

# Make sure the activated CLI is on your PATH (add to ~/.zshrc to keep it)
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Log in to the same Google account you used in the console
firebase login

# Generate the config. Replace the project id with yours from step 1.1.
cd ~/Desktop/Signals
flutterfire configure \
  --project=YOUR_PROJECT_ID \
  --platforms=android,web \
  --android-package-name=com.signals.signals \
  --yes
```

What this creates / changes:

| File | What it is |
| --- | --- |
| `lib/firebase_options.dart` | Per-platform Firebase config the app reads at startup |
| `android/app/google-services.json` | Android Firebase config |
| `firebase.json` | Records which platforms were configured |

`--android-package-name` **must** be `com.signals.signals`; that's the
`applicationId` in `android/app/build.gradle.kts`. If they disagree, Android
sign-in will fail at runtime.

> These files contain API keys, but Firebase web/Android API keys are **not
> secrets** — they identify the project, they don't grant access. Access is
> controlled entirely by the Firestore security rules. They're still
> gitignored in this repo so your project isn't trivially reusable by others.

## 1.6 Deploy the Firestore security rules

The rules live at [`firestore.rules`](../firestore.rules) and are what actually
stops a learner from writing lessons — the admin UI being hidden is only
cosmetic.

```bash
cd ~/Desktop/Signals
firebase use YOUR_PROJECT_ID          # first time: firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```

Verify in the console under **Firestore Database → Rules** — the published rules
should match the file, and the timestamp should be just now.

## 1.7 Create the admin account

1. Run the app (`flutter run -d chrome` is quickest) and use the **Sign up**
   screen to create your account, e.g. `admin@signals.app`.
2. That gives you a `users/{uid}` document with `role: "learner"`.
3. In the Firebase console → **Firestore Database → Data → `users`**, open your
   document and change `role` from `learner` to `admin`. Save.
4. Back in the app, pull-to-refresh or restart. An **Admin** entry now appears
   in the profile menu, and the Firestore rules will accept lesson writes from
   you.

Role promotion is deliberately console-only: no screen in the app can grant
admin, and the rules forbid a user from editing their own `role` field.

See [`04-admin-account.md`](04-admin-account.md) for the full walkthrough with
what to expect on screen.

## 1.8 Seed the demo content

Once you have an admin account, load the sample lessons, questions and forum
posts — see [`05-seed-data.md`](05-seed-data.md).

---

## What to hand back to Claude / put in your notes

* Firebase **project ID** (e.g. `signals-app-1a2b3`)
* Confirmation that Email/Password auth is enabled
* Confirmation that Firestore exists, and which region

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `flutterfire: command not found` | `export PATH="$PATH":"$HOME/.pub-cache/bin"` |
| `[core/no-app] No Firebase App '[DEFAULT]'` | `lib/firebase_options.dart` missing or `Firebase.initializeApp` not awaited — re-run `flutterfire configure` |
| `PERMISSION_DENIED: Missing or insufficient permissions` | Rules not deployed (step 1.6), or you're signed out |
| `[firebase_auth/operation-not-allowed]` | Email/Password provider not enabled (step 1.2) |
| `[firebase_auth/api-key-not-valid]` | `google-services.json` / `firebase_options.dart` is from a different project — re-run `flutterfire configure` |
| Android build fails on `google-services.json` | File must sit at `android/app/google-services.json`, not `android/` |
