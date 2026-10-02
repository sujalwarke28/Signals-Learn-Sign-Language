# 7 · Building the APK and installing it on a phone

The Android APK is the primary deliverable. This covers building it and getting
it onto a phone — both over USB and by sending the file.

Prerequisites: [doc 3](03-android-sdk-setup.md) (Android SDK) and
[doc 6, step 6.3](06-run-on-macbook.md) (Firebase and Cloudinary config present).

---

## 7.1 Build the release APK

```bash
cd ~/Desktop/Signals
flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

The first release build takes several minutes (Gradle, R8, native stripping).
Later builds are much quicker.

### Baking the Cloudinary values in at build time

If you'd rather not keep `app_config.dart` on disk, pass them instead:

```bash
flutter build apk --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=signals_unsigned
```

`--dart-define` takes precedence over the file.

### Smaller APKs (optional)

```bash
flutter build apk --release --split-per-abi
```

This produces one APK per CPU architecture instead of one universal APK. For
handing a file to a marker, the single universal APK is simpler — it installs on
any phone. Modern phones are `arm64-v8a`.

## 7.2 Check the build

```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

Expect roughly 25–50 MB. If it's far smaller, the build probably failed — scroll
up for the real error.

## 7.3 Install it — over USB (easiest)

With the phone connected and USB debugging on (see
[doc 6, step 6.6](06-run-on-macbook.md)):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`-r` replaces an existing install without wiping its data. You should see
`Success`, and **Signals** appears in the app drawer.

Or let Flutter do both steps:

```bash
flutter install --release
```

## 7.4 Install it — from the APK file directly

For sending the APK to someone (or to your own phone without a cable).

1. **Get the file onto the phone.** Any of: Google Drive, email it to yourself,
   AirDrop to an Android via Nearby Share, or a USB cable in file-transfer mode.
2. **Allow installs from that source.** Android blocks sideloading per-app:
   * Open the file (from Files, Drive, Gmail — whatever you used).
   * Android says *"For your security, your phone is not allowed to install
     unknown apps from this source."* → tap **Settings**.
   * Toggle **Allow from this source** on.
   * Go back and tap the APK again.

   To set it in advance: **Settings → Apps → Special app access → Install unknown
   apps** → pick the app you'll open the APK from → **Allow from this source**.
   (Older Android: **Settings → Security → Unknown sources**.)
3. **Install.** Tap **Install**, then **Open**.
4. Play Protect may warn *"Unsafe app blocked"* or offer to scan it. This is
   expected for any app not distributed through the Play Store — tap **Install
   anyway** / **More details → Install anyway**.

## 7.5 Signing — what this APK is and isn't

The release build is signed with Flutter's **debug keystore**
(`~/.android/debug.keystore`). That's why `flutter build apk --release` just works
with no setup.

* ✅ Installs by hand on any phone. Fine for a college submission or a demo.
* ❌ Not acceptable to the Play Store, which requires your own upload key.
* ⚠️ Rebuilding on a different machine produces a different signature, so the new
  APK won't install over the old one — uninstall first.

If you ever do need a real signing key:

```bash
keytool -genkey -v -keystore ~/signals-upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

then create `android/key.properties` (gitignored) and reference it from a
`signingConfigs` block in `android/app/build.gradle.kts`. Out of scope for this
project.

## 7.6 First run on the phone — what to check

* **Sign-up works.** This proves the phone reached Firebase Auth over the network.
* **Lessons load.** Proves Firestore reads and the deployed rules.
* **A video plays.** Proves network video playback and the `INTERNET` permission.
* **A sound plays on a button tap.** Proves the bundled WAV assets shipped.
* **Dark mode.** Flip the system theme in the notification shade; the app follows
  it (or set it explicitly in Profile & settings).
* **A quiz updates the dashboard.** Finish one, then go Home — the percentage
  should already be different.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | An existing Signals has a different signature. `adb uninstall com.signals.signals` first |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | Free some space on the phone |
| `adb: no devices/emulators found` | See the USB table in [doc 6](06-run-on-macbook.md) |
| App installs, then closes immediately | Almost always missing/mismatched `google-services.json`. Check `flutter logs` or `adb logcat | grep -i flutter` |
| `Missing or insufficient permissions` in the app | Rules not deployed — [doc 9](09-firestore-rules.md) |
| Videos won't play but everything else works | Check the `INTERNET` permission survived in `android/app/src/main/AndroidManifest.xml` |
| Uploads fail only on the phone | Cloudinary values weren't compiled in — check `app_config.dart` or your `--dart-define` flags |
| `minSdkVersion` error | `minSdk` must be 23+ for firebase_auth; it's set in `android/app/build.gradle.kts` |
