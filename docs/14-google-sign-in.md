# 14 · Google sign-in

The login and sign-up screens each carry a **Continue with Google** button below
the email form. Web works as soon as the provider is enabled in the console.
Android needs one extra step — a signing fingerprint — and this doc is mostly
about that step, because Android fails in a confusing way without it.

---

## 14.1 Enable the provider (both platforms)

1. Firebase console → **Build → Authentication → Sign-in method**.
2. Click **Google** → toggle **Enable** ON.
3. Pick a **project support email** (required; your own address is fine).
4. **Save**.

Leave Email/Password enabled alongside it. The two providers coexist: a learner
who signed up with `you@gmail.com` by password and later taps the Google button
with the same address is linked to the *same* account by Firebase, not given a
second one.

That is all the web build needs. `localhost` and your
`*.firebaseapp.com` / `*.web.app` hosting domains are on the authorized-domains
list by default; if you serve the web build from a custom domain, add it under
**Authentication → Settings → Authorized domains**, or the popup closes with
`auth/unauthorized-domain`.

---

## 14.2 Register the Android signing fingerprint

Google refuses to issue an ID token to an Android app whose signing certificate
it doesn't recognise. Your `android/app/google-services.json` currently has no
fingerprint registered, so **Android Google sign-in will fail until you do this**.

### The debug fingerprint (for `flutter run` and the debug APK)

This machine's debug SHA-1 is:

```
3D:1A:6D:D8:27:60:F2:2B:5A:6A:37:F8:7E:7E:3D:A1:B0:D5:04:32
```

Regenerate it any time with:

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

### Add it to Firebase

1. Firebase console → **⚙ Project settings → General**.
2. Scroll to **Your apps** and select the Android app
   (`com.signals.signals`).
3. Click **Add fingerprint**, paste the SHA-1, **Save**.
4. Click **Download google-services.json** and replace the file at
   `android/app/google-services.json`.
5. `flutter clean && flutter run -d <device>`.

You can confirm the new file took by checking that it now contains an
`oauth_client` entry with `"client_type": 1` — the Android client. Before you
add a fingerprint there is only `"client_type": 3`, the web client.

### The release fingerprint

**As this project stands, there is nothing extra to do.**
`android/app/build.gradle.kts` deliberately signs `release` with the *debug*
keystore (`signingConfig = signingConfigs.getByName("debug")`), so the release
APK carries the same SHA-1 as a debug build. One fingerprint covers both.

That changes the day you add a real upload key — a Play Store build needs one,
and [`07-android-apk.md`](07-android-apk.md) covers it. At that point read the
new keystore's SHA-1:

```bash
keytool -list -v -keystore <your-release-keystore.jks> -alias <your-alias>
```

and add it as a *second* fingerprint on the same Firebase Android app. A single
app can hold as many fingerprints as you have signing keys. Skipping that step
is the classic "Google sign-in worked in testing and fails in the Play build"
bug, because the signature no longer matches anything Google trusts.

---

## 14.3 How it works in the code

| Where | What |
| --- | --- |
| [`lib/data/auth_repository.dart`](../lib/data/auth_repository.dart) | `signInWithGoogle()` — the whole flow, both platforms. Returns `false` if the learner backed out. |
| [`lib/screens/auth/google_sign_in_button.dart`](../lib/screens/auth/google_sign_in_button.dart) | The button, its busy state, and the `or` divider. |
| [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart), [`signup_screen.dart`](../lib/screens/auth/signup_screen.dart) | Where the button is mounted. |

The two platforms reach Firebase differently, on purpose:

* **Web** uses `signInWithPopup` from `firebase_auth`. The `google_sign_in`
  package deliberately has no `authenticate()` on web — the browser SDK requires
  its own rendered button — so the popup is the supported route. If the browser
  blocks the popup, the code falls back to `signInWithRedirect`.
* **Android** uses `google_sign_in` 7.x (`GoogleSignIn.instance.authenticate()`),
  which shows the native Credential Manager account picker, and trades the
  resulting ID token for a Firebase credential.

No client IDs are hard-coded. On Android the plugin reads the web OAuth client
straight out of `google-services.json`, so re-downloading that file is the only
thing you ever need to keep in sync.

A first Google sign-in has no `users/{uid}` document yet, so `signInWithGoogle()`
calls `ensureProfile()`, which writes one with `role: "learner"` — the same
starting point as an email sign-up. Promotion to admin is still console-only;
see [`04-admin-account.md`](04-admin-account.md).

---

## 14.4 Signing out

Two places, both behind the same confirmation dialog
([`lib/screens/auth/sign_out_action.dart`](../lib/screens/auth/sign_out_action.dart)):

* the **logout icon** in the Home screen header, next to your avatar;
* **Sign out** at the bottom of **Profile & settings**.

Signing out clears the native Google credential as well as the Firebase session,
so the next sign-in shows the account picker rather than silently reusing the
last account.

Getting back to the signed-out state takes two mechanisms, deliberately
(signing out lands on `/welcome`, not `/login`):

* `confirmSignOut` navigates there directly, so leaving is a consequence of the
  tap rather than something inferred from an auth stream;
* the router's `authRedirect` agrees independently, which is what catches a
  session that ends some other way — a revoked token, a password change on
  another device, an expired credential.

`authRedirect` in [`lib/router/app_router.dart`](../lib/router/app_router.dart)
is a pure function for exactly this reason, and
[`test/auth_redirect_test.dart`](../test/auth_redirect_test.dart) pins the rules
down without needing Firebase or a navigator.

One trap worth knowing, because it bit this app once: a provider that reads an
auth-gated collection **must** depend on the uid. `/lessons` is readable only
when signed in, so `lessonsProvider` rebuilds on `currentUidProvider`. When it
did not, its `keepAlive`d Firestore subscription outlived the session, stuck
forever on `permission-denied`, and the dashboard rendered "Not allowed to read
that" instead of the signed-out landing page.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Android: picker opens, you choose an account, and it reports "didn't finish" | Almost always a missing or wrong SHA-1 (14.2). Android's Credential Manager reports several config errors as a plain cancel, so this wording covers both. |
| Android: "Google sign-in isn't set up for this build yet" | `clientConfigurationError` — the Google provider is off in the console (14.1), or `google-services.json` is from another project. |
| Android: works in debug, fails in the release APK | Only possible once you've added a real upload key — today `release` is signed with the debug keystore, so both share one SHA-1. If you have added one, register its fingerprint too (14.2). |
| Android: no device found when you try to run it | `flutter devices` lists nothing Android until a phone is plugged in with USB debugging on, or an emulator is installed — this SDK has no emulator or system image. See [`06-run-on-macbook.md`](06-run-on-macbook.md). |
| Web: `auth/unauthorized-domain` | The domain serving the app isn't in **Authentication → Settings → Authorized domains**. |
| Web: nothing happens on click | Popup blocked *and* the redirect fallback blocked. Allow popups for the site. |
| `[firebase_auth/operation-not-allowed]` | The Google provider isn't enabled (14.1). |
| Google account creates a second, separate account | It won't, as long as the email matches. Firebase links providers by verified email address. |
