# 6 · Running Signals from source on a MacBook

Covers a clean machine through to the app running in Chrome, on an emulator, and
on a physical Android phone over USB.

---

## 6.1 Install Flutter

If `flutter --version` already works, skip to 6.2.

```bash
# Xcode command line tools (git, clang) — needed even though iOS is out of scope
xcode-select --install

# Homebrew, if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter
brew install --cask flutter
```

Or download the SDK zip from <https://docs.flutter.dev/get-started/install/macos>
and extract it (this machine has it at `~/Downloads/flutter`), then:

```bash
export PATH="$PATH:$HOME/Downloads/flutter/bin"   # add to ~/.zshrc to keep it
```

Check it:

```bash
flutter --version     # this project was built on 3.47.2 / Dart 3.13.2
flutter doctor
```

You need ✓ on **Flutter** and **Chrome**. For the APK you also need ✓ on
**Android toolchain** — see [doc 3](03-android-sdk-setup.md). The Xcode and
CocoaPods warnings are irrelevant here; iOS is out of scope.

## 6.2 Get the code and its dependencies

```bash
cd ~/Desktop/Signals
flutter pub get
```

## 6.3 Add the two config files

The repo deliberately doesn't contain them. Both are one-time.

**Firebase** — follow [doc 1](01-firebase-setup.md), which ends with:

```bash
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,web \
  --android-package-name=com.signals.signals --yes
```

That writes `lib/firebase_options.dart` and
`android/app/google-services.json`.

**Cloudinary** — follow [doc 2](02-cloudinary-setup.md), then:

```bash
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
```

and edit the two constants in the copy.

Verify you have everything:

```bash
ls lib/firebase_options.dart lib/core/config/app_config.dart android/app/google-services.json
flutter analyze        # should report "No issues found"
flutter test           # should report "All tests passed"
```

## 6.4 Run it — web (fastest loop)

```bash
flutter run -d chrome --web-port=8090
```

Hot reload with `r`, hot restart with `R`, quit with `q`.

`--web-port` is worth the extra typing. Without it Flutter picks a random free
port every launch, so the app lands on a different `localhost:xxxxx` each time
and you lose the tab you had open. Pinned, it's always
<http://localhost:8090>.

> Not `8080`: that's Jenkins' default port, and if you have Jenkins installed
> you'll get its sign-in page instead of the app. Any free port works — 8090,
> 4200 and 9090 are all fine. Avoid `5000` on macOS, which AirPlay Receiver
> takes.

Better still, don't relaunch. Leave `flutter run` attached and press **`r`**
after an edit: hot reload patches the running app in place, keeping you signed
in and on the same screen — which saves re-navigating to a lesson every time you
tweak something. **`R`** (hot restart) rebuilds from scratch but reuses the same
process, port and tab.

Only a few changes need a real relaunch: edits to `main()`, anything in
`pubspec.yaml`, and native or plugin changes. Flutter says so when it happens.

> If a relaunch reports the port is in use, an earlier `flutter run` is still
> alive — quit it with `q`, or `lsof -ti:8090 | xargs kill`. To see what is
> holding a port before killing anything:
> `lsof -ti:8090 | head -1 | xargs ps -o comm= -p`.

This is the quickest way to develop, and it's how you'll create and promote your
admin account.

> One caveat: browsers block audio until the page has been interacted with, so
> the very first sound cue may be silent. Any tap fixes it for the session.

## 6.5 Run it — Android emulator

```bash
flutter emulators                     # list
flutter emulators --launch <id>       # or launch from Android Studio
flutter run
```

Creating an emulator from scratch is in [doc 3, step 3.6](03-android-sdk-setup.md).

## 6.6 Run it — a real Android phone over USB

This is the primary target, and worth doing at least once before you demo.

1. On the phone: **Settings → About phone** → tap **Build number** seven times to
   enable Developer options.
2. **Settings → System → Developer options** → turn on **USB debugging**.
3. Plug the phone into the Mac with a data-capable USB cable.
4. The phone shows *Allow USB debugging?* → tick **Always allow** → **Allow**.
5. Check the Mac can see it:

   ```bash
   adb devices          # should list your device, not "unauthorized"
   flutter devices      # should list the phone by model name
   ```

6. Run:

   ```bash
   flutter run                     # debug build
   flutter run --release           # closer to real-world performance
   ```

## 6.7 Build the artefacts

```bash
# Release APK — see doc 7 for installing it
flutter build apk --release

# Web bundle — see doc 8 for deploying it
flutter build web --release
```

## 6.8 Useful commands

| Command | What it does |
| --- | --- |
| `flutter analyze` | Static analysis; should be clean |
| `flutter test` | The unit tests, including the progress-calculation tests |
| `flutter clean && flutter pub get` | Nuclear option when the build acts strangely |
| `flutter pub outdated` | What could be upgraded |
| `flutter devices` | Everything you could run on right now |
| `flutter logs` | Device logs from a running app |
| `python3 tool/generate_sounds.py` | Regenerate the sound cues |
| `python3 tool/generate_lottie.py` | Regenerate the confetti animation |

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Target of URI doesn't exist: 'firebase_options.dart'` | Step 6.3 not done |
| `Error: Couldn't resolve the package 'signals'` | Run `flutter pub get` |
| `adb devices` shows `unauthorized` | Unlock the phone and accept the USB debugging prompt |
| `adb devices` shows nothing | Charge-only cable, or a USB hub — try a different cable, directly into the Mac |
| Gradle downloads forever on first build | Normal, once. Subsequent builds are much faster |
| `Execution failed for task ':app:processDebugGoogleServices'` | `google-services.json` is missing or in the wrong folder (must be `android/app/`) |
| Chrome opens blank with console errors about Firebase | `firebase_options.dart` is from a different project — re-run `flutterfire configure` |
| Fonts look wrong | `flutter clean`, then `flutter pub get` — the bundled TTFs may not have been packaged |
