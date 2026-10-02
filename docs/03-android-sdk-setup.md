# 3 · Android SDK on macOS (no Android Studio needed)

You need the Android SDK to build an APK. You do **not** need Android Studio —
the command-line tools are a few hundred MB instead of several GB, and Flutter is
happy with them.

This is what was installed on this machine, so these are reproduction steps as
much as instructions.

---

## 3.1 Prerequisites

```bash
java -version    # needs 17 or newer
brew --version   # Homebrew
```

If Java is missing: `brew install --cask temurin`.

## 3.2 Install the command-line tools

```bash
brew install --cask android-commandlinetools
```

This installs to `/opt/homebrew/share/android-commandlinetools` and symlinks
`sdkmanager`, `adb`, `avdmanager` and friends onto your `PATH`.

## 3.3 Accept the licences and install the SDK packages

```bash
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools

yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses

sdkmanager --sdk_root=$ANDROID_HOME \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0"
```

* `platform-tools` gives you `adb` (needed to install onto a phone).
* `platforms;android-36` is the compile SDK.
* `build-tools;36.0.0` does the actual packaging.

## 3.4 Point Flutter at it

```bash
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
flutter doctor
```

You want:

```
[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
```

The Xcode warnings in `flutter doctor` don't matter — iOS and macOS desktop are
out of scope for this project.

## 3.5 Make it permanent

Add to `~/.zshrc` so new shells find the tools:

```bash
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Then `source ~/.zshrc`.

## 3.6 Optional: an emulator

A physical phone over USB is faster and more representative, and the emulator is
a large extra download. If you want one anyway:

```bash
sdkmanager --sdk_root=$ANDROID_HOME "system-images;android-36;google_apis;arm64-v8a" "emulator"
avdmanager create avd -n signals -k "system-images;android-36;google_apis;arm64-v8a"
$ANDROID_HOME/emulator/emulator -avd signals &
flutter devices     # the emulator should now be listed
```

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Unable to locate Android SDK` | Run step 3.4 |
| `cmdline-tools component is missing` | You installed the SDK without cmdline-tools; `brew install --cask android-commandlinetools` fixes it |
| `Android license status unknown` | Re-run the `--licenses` command in 3.3 |
| `adb: command not found` | Add `$ANDROID_HOME/platform-tools` to `PATH` (step 3.5) |
| `sdkmanager` warns about `android sdk` being the replacement | Harmless deprecation notice; `sdkmanager` still works |
