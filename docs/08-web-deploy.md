# 8 · Building and deploying the web app

The web build is the shareable-link deliverable. Firebase Hosting is the natural
choice — you already have the project, it's free, and it gives you an HTTPS URL.

Prerequisites: [doc 1](01-firebase-setup.md).

---

## 8.1 Build the bundle

```bash
cd ~/Desktop/Signals
flutter build web --release
```

Output goes to `build/web/`. That directory is a complete static site.

With the Cloudinary values passed at build time instead of from the file:

```bash
flutter build web --release \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=signals_unsigned
```

### Test it locally before deploying

```bash
cd build/web && python3 -m http.server 8000
```

Open <http://localhost:8000>. Opening `index.html` directly with `file://` will
**not** work — Flutter web needs to be served over HTTP.

## 8.2 Deploy to Firebase Hosting

### One-time setup

```bash
npm install -g firebase-tools     # if `firebase --version` doesn't work yet
firebase login
cd ~/Desktop/Signals
firebase init hosting
```

Answer the prompts:

| Prompt | Answer |
| --- | --- |
| Use an existing project | **Yes** → pick your Signals project |
| Public directory | **`build/web`** |
| Single-page app rewrite all URLs to /index.html? | **Yes** ← required, go_router owns the routes |
| Set up automatic builds with GitHub? | **No** |
| Overwrite `build/web/index.html`? | **No** ← this one matters, say no |

That last one is the classic mistake: saying yes replaces Flutter's bootstrap
`index.html` with Firebase's placeholder page and you get a blank app.

### Deploy

```bash
flutter build web --release
firebase deploy --only hosting
```

You get back:

```
Hosting URL: https://YOUR-PROJECT-ID.web.app
```

That's the shareable link. It's public — anyone can open it, and they'll need to
sign up or sign in.

### Redeploying after changes

```bash
flutter build web --release && firebase deploy --only hosting
```

## 8.3 Authorise the domain for sign-in

Firebase Auth only accepts sign-ins from domains you've allow-listed.
`*.web.app` and `*.firebaseapp.com` for your own project are authorised
automatically, so the default URL just works.

If you use a custom domain, add it: **Firebase console → Authentication →
Settings → Authorized domains → Add domain**. Skip this and sign-in fails with
`auth/unauthorized-domain`.

## 8.4 Alternatives

Any static host works, since `build/web` is just files.

**Netlify** (drag and drop):
```bash
flutter build web --release
# then drag build/web onto https://app.netlify.com/drop
```
Add a `build/web/_redirects` file containing `/* /index.html 200` so deep links
work, and remember to authorise the Netlify domain in Firebase Auth (8.3).

**GitHub Pages**: needs `flutter build web --release --base-href /repo-name/`
because the site is served from a subdirectory.

## 8.5 What to expect from the web build

It's the same app, and it adapts: at desktop width the bottom navigation becomes
a left-hand rail and the lesson library goes to a two- or three-column grid.

Two genuine differences from Android:

* **Audio needs a first interaction.** Browsers block autoplay until the user has
  clicked something. The first sound cue of a session may be silent; everything
  after works.
* **First load is slower.** Flutter web ships a sizeable engine. Subsequent loads
  are cached.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Blank white page | You let `firebase init` overwrite `index.html`. Re-run `flutter build web --release` and deploy again |
| Blank page, console shows a 404 on `main.dart.js` | Public directory isn't `build/web` — fix it in `firebase.json` |
| Deep links 404 on refresh | The SPA rewrite wasn't enabled. `firebase.json` needs `"rewrites": [{ "source": "**", "destination": "/index.html" }]` |
| `auth/unauthorized-domain` | Add the domain under Authentication → Settings → Authorized domains |
| `Error: Failed to get Firebase project` | `firebase use --add` and pick the project |
| Videos won't play in Safari | Safari is strict about codecs and range requests. Test in Chrome; H.264 mp4 is the safe format |
| Sound never plays | Check the toggle in Profile & settings, then click anywhere and retry — browser autoplay policy |
| Works locally, fails deployed | Nearly always an unauthorised domain (8.3) |
