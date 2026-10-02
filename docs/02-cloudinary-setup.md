# 2 · Cloudinary setup (video hosting)

Lesson videos are uploaded straight from the admin screen to **Cloudinary** and
only the resulting URL is stored in Firestore. Firebase Storage is avoided
entirely, so the whole app stays on free tiers.

Signals uploads **unsigned**: the app sends the file plus an upload *preset*
name, and no API secret ever ships inside the app. That is the only safe way to
upload from a client, because anything bundled into an APK or a web build can be
read back out of it.

Time needed: about 5 minutes. Free tier is 25 GB storage / 25 GB monthly
bandwidth — far more than a demo needs.

---

## 2.1 Create the account

1. Go to <https://cloudinary.com/users/register_free> and sign up (Google sign-in
   is fine).
2. When asked what you're building, anything is fine — it only affects tips.
3. You land on the **Dashboard**.

## 2.2 Find your cloud name

On the Dashboard, the **Product Environment Credentials** card shows:

```
Cloud name:  dxxxxxxxx      <- you need this
API key:     1234...        <- NOT needed, do not put this in the app
API secret:  ****           <- NOT needed, never put this in the app
```

Copy the **Cloud name** only.

## 2.3 Create the unsigned upload preset

1. Click the **gear icon** (Settings) in the left sidebar.
2. Open **Upload** (in newer dashboards: **Product Environment Settings →
   Upload**).
3. Scroll to **Upload presets** → click **Add upload preset**.
4. Set these:

   | Field | Value |
   | --- | --- |
   | **Upload preset name** | `signals_unsigned` |
   | **Signing Mode** | **Unsigned**  ← the important one |
   | **Folder** | `signals/lessons` |
   | Use filename as public ID | off (leave default) |
   | Unique filename | on (leave default) |

5. Leave every other field alone. Click **Save**.

The preset must be **Unsigned** or the app's uploads come back
`401 Upload preset must be whitelisted for unsigned uploads`.

### Optional but recommended: limit what the preset accepts

Still inside the preset, under **Upload Control** (or **Upload Manipulations**),
you can set:

* **Allowed formats**: `mp4,mov,webm,m4v,png,jpg,jpeg,webp,gif`
* **Max file size**: `100000000` (100 MB)

The image formats are not optional if you set this field at all. The same preset
uploads both lesson videos and the optional image on a quiz question, so a
video-only list makes Cloudinary reject every picture with a *format not allowed*
error — and it fails at upload time, not when you pick the file, because the
restriction lives on the preset rather than in the app.

An unsigned preset is, by design, usable by anyone who extracts the cloud name
and preset from your app. These two limits are what keep that from being
interesting to abuse. For a college demo it's fine either way — for anything
public, set them.

## 2.4 What Signals does with it

The admin **Add Lesson** screen POSTs the picked file to:

```
POST https://api.cloudinary.com/v1_1/<CLOUD_NAME>/video/upload
  multipart/form-data
  file=<the video bytes>
  upload_preset=signals_unsigned
```

and reads `secure_url` out of the JSON response. That URL goes into the
Firestore `lessons` document as `videoUrl`, and `video_player` streams it
directly. A poster frame is derived from the same public ID by swapping the
delivery type to `/image/upload/` with a `.jpg` extension, so lesson cards get a
thumbnail for free.

A quiz question may also carry an optional picture. That uses the same preset
against the `image` endpoint instead:

```
POST https://api.cloudinary.com/v1_1/<CLOUD_NAME>/image/upload
```

Its `secure_url` is stored on the question as `imageUrl`. Cloudinary routes by
resource type in the path, so one unsigned preset covers both — there is nothing
extra to configure. Question images are capped at 10 MB by the app
(`AppConstants.maxQuestionImageBytes`), well under the tier limit.

## 2.5 Where the values live in the code

Both values are compiled in from **`lib/core/config/app_config.dart`**. They are
not secrets (see above), but that file is gitignored so your account isn't
carried along with the source. To recreate it:

```bash
cd ~/Desktop/Signals
cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart
# then edit the two constants
```

You can also override them at build time without touching the file:

```bash
flutter build apk --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=dxxxxxxxx \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=signals_unsigned
```

`--dart-define` wins over the file when both are present.

---

## What to hand back to Claude / put in your notes

* **Cloud name** (e.g. `dxxxxxxxx`)
* **Upload preset name** (`signals_unsigned` if you followed this doc)
* Confirmation the preset's signing mode is **Unsigned**

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `401 Upload preset must be whitelisted for unsigned uploads` | Preset's Signing Mode is Signed — change to Unsigned |
| `400 Upload preset not found` | Preset name typo, or created under a different product environment than the cloud name you used |
| `400 File size too large` | Free tier caps a single video at 100 MB; compress or trim the clip |
| Upload works, video won't play | Check the stored `videoUrl` starts `https://res.cloudinary.com/...` and ends in a video extension |
| Web upload fails with a CORS error | Cloudinary's upload endpoint allows browser uploads by default; a CORS error here almost always means the URL is malformed (wrong cloud name) |
