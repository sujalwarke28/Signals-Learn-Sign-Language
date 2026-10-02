# 13 · Troubleshooting

Grouped by where the problem shows up. Each doc also has its own table for issues
specific to that step.

---

## Build and tooling

| Symptom | Cause / fix |
| --- | --- |
| `Target of URI doesn't exist: 'firebase_options.dart'` | Run `flutterfire configure` — [doc 1](01-firebase-setup.md) |
| `Target of URI doesn't exist: 'core/config/app_config.dart'` | `cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart` — [doc 2](02-cloudinary-setup.md) |
| `flutterfire: command not found` | `export PATH="$PATH":"$HOME/.pub-cache/bin"` |
| `Unable to locate Android SDK` | `flutter config --android-sdk <path>` — [doc 3](03-android-sdk-setup.md) |
| `Execution failed for task ':app:processDebugGoogleServices'` | `google-services.json` must be at `android/app/`, not `android/` |
| `minSdkVersion 21 cannot be smaller than version 23` | `minSdk` is set to 23 in `android/app/build.gradle.kts` for firebase_auth — don't lower it |
| Gradle hangs on first build | Normal, it's downloading. Later builds are fast |
| Weird build errors after changing dependencies | `flutter clean && flutter pub get` |
| The app opens on a different `localhost` port every run | Expected — Flutter picks a free port. Pass `--web-port=8090` to pin it, and prefer hot reload (`r`) over relaunching — [doc 6, step 6.4](06-run-on-macbook.md) |
| A Jenkins sign-in page on `localhost:8080` | That's Jenkins, not this app — 8080 is its default port. Run the app on another port, e.g. `--web-port=8090` |
| `Port is already in use` | Something else holds it. Check what with `lsof -ti:8090 \| head -1 \| xargs ps -o comm= -p`; if it's an old `flutter run`, quit it with `q` |
| Edits don't show up after pressing `r` | Some changes can't hot reload — `main()`, `pubspec.yaml`, native/plugin code. Use `R`, or relaunch |
| `Could not resolve the package 'signals'` | `flutter pub get` |

## Sign-in and accounts

| Symptom | Cause / fix |
| --- | --- |
| `[firebase_auth/operation-not-allowed]` | Email/Password provider not enabled — [doc 1, step 1.2](01-firebase-setup.md) |
| `[firebase_auth/api-key-not-valid]` | Config is from a different Firebase project; re-run `flutterfire configure` |
| `[core/no-app] No Firebase App '[DEFAULT]'` | `Firebase.initializeApp` failed or wasn't awaited; check `main()` and that `firebase_options.dart` exists |
| `auth/unauthorized-domain` on the web | Add the domain under Authentication → Settings → Authorized domains |
| Signed in but stuck on the splash screen | The `users/{uid}` document is missing. The app backfills it automatically; if it can't, rules aren't deployed |
| Email or password is incorrect, but it's right | Firebase returns one error for both cases. Check for a typo in the email, or use Forgot password |

## Permissions and data

| Symptom | Cause / fix |
| --- | --- |
| `Missing or insufficient permissions` everywhere | Rules never deployed: `firebase deploy --only firestore:rules` |
| Library empty for everyone | No lessons exist — load demo content ([doc 5](05-seed-data.md)) or publish one |
| Admin UI missing | `users/{uid}.role` isn't exactly `admin`, lowercase — [doc 4](04-admin-account.md) |
| Admin can read but not write lessons | Same as above; the rules read the role from the profile document |
| `permission-denied` saving a quiz result | The rule requires `0 <= score <= total`; also check you're signed in as the same user |
| Forum reply fails | The reply and the `replyCount` bump go in one batch — both must pass. Check `authorId` is the caller |
| Progress numbers look stale | They shouldn't be — they're streamed. If they are, check the console for a rules error suppressing one of the three streams |

## Video

| Symptom | Cause / fix |
| --- | --- |
| "Could not load the video" | Bad or expired URL. Check the lesson's `videoUrl` in the Firestore console |
| Video plays on web but not Android | Codec. H.264 in an mp4 container is the safe choice |
| Video plays on Android but not web | Often Safari. Try Chrome; Safari is strict about range requests and codecs |
| Nothing plays in a release APK | The `INTERNET` permission is missing from `android/app/src/main/AndroidManifest.xml` |
| Quiz never unlocks | You have to reach 95% of the duration. Scrubbing to the end also works; check the watch bar |
| Quiz unlocked but shows "No quiz yet" | The lesson has no questions. Add them via the admin screen |

## Uploads

| Symptom | Cause / fix |
| --- | --- |
| "Cloudinary isn't configured yet" | `app_config.dart` missing or its constants empty — [doc 2](02-cloudinary-setup.md) |
| `Upload preset must be whitelisted for unsigned uploads` | The preset's Signing Mode is Signed; change it to Unsigned |
| `Upload preset not found` | Name typo, or the preset is in a different product environment than the cloud name |
| A question image is rejected as a disallowed format | The preset's **Allowed formats** is video-only. Add `png,jpg,jpeg,webp,gif` — [doc 2, step 2.3](02-cloudinary-setup.md) |
| Question image is too large | The app caps it at 10 MB (`AppConstants.maxQuestionImageBytes`), independently of the preset's limit |
| `File size too large` | Free tier caps a single upload at 100 MB; the app checks this before starting |
| Upload succeeds, no thumbnail | Cloudinary generates poster frames lazily. The app falls back to a tinted gradient tile, which is expected |
| Upload works on web, fails on the phone | Cloudinary values weren't compiled into the APK — check `app_config.dart` or your `--dart-define` flags |

## Sound

| Symptom | Cause / fix |
| --- | --- |
| No sound at all | Check the toggle in Profile & settings, then the device volume and silent switch |
| No sound on the web until you click | Browser autoplay policy. Expected; any interaction unlocks it for the session |
| Sounds cut each other off | Shouldn't happen — there's a pool of four players. If it does, the pool size is a constant in `sound_service.dart` |
| Sounds too loud or too quiet | `setVolume(0.55)` in `sound_service.dart`, or regenerate with different amplitudes ([doc 10](10-assets-sound-animation.md)) |
| Sound cues duck the lesson video | Shouldn't — the audio context uses `mixWithOthers`. Check that config wasn't changed |

## Layout and theme

| Symptom | Cause / fix |
| --- | --- |
| Fonts look like the system default | `flutter clean && flutter pub get`; check `assets/fonts/` has both TTFs and `pubspec.yaml` declares them |
| No confetti on a pass | `assets/lottie/confetti.json` missing — `python3 tool/generate_lottie.py` |
| Everything stretched wide on a monitor | `ContentWidth` caps it; if a screen misses it, that's the bug |
| Dark mode doesn't follow the system | Theme mode may be pinned. Profile & settings → Theme → the auto option |
| Text overflowing on a small phone | Worth reporting — the layouts are built for phone width first |

## Still stuck?

```bash
flutter doctor -v            # toolchain state
flutter analyze              # should be clean
flutter test                 # should all pass
flutter logs                 # runtime logs from a connected device
adb logcat | grep -i flutter # raw Android logs
```

In Chrome, the browser console shows Firebase errors verbatim — usually the fastest
way to identify a rules or config problem.
