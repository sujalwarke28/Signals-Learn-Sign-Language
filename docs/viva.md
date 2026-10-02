# Viva preparation — Signals

Questions an examiner is likely to ask, with answers written the way you would
say them out loud. Each answer names the file, so you can open it if asked to
show the code.

**Contents**

1. [The opening question](#1-the-opening-question)
2. [Frontend](#2-frontend)
3. [Backend](#3-backend)
4. [Architecture and layering](#4-architecture-and-layering)
5. [State management](#5-state-management)
6. [Routing and navigation](#6-routing-and-navigation)
7. [Database and data model](#7-database-and-data-model)
8. [Security](#8-security)
9. [How specific features work](#9-how-specific-features-work)
10. [Every file in the repository](#10-every-file-in-the-repository)
11. [Why this and not that](#11-why-this-and-not-that)
12. [Testing](#12-testing)
13. [Building and deploying](#13-building-and-deploying)
14. [Limitations and honest answers](#14-limitations-and-honest-answers)
15. [Dart language questions](#15-dart-language-questions)
16. [Flutter framework questions](#16-flutter-framework-questions)
17. [Things you did *not* use — and why](#17-things-you-did-not-use--and-why)
18. [Hard questions](#18-hard-questions)

---

## 1. The opening question

### Q. Tell me about your project.

Signals is a cross-platform app that teaches sign language. It has:

- **Video lessons** grouped into six categories
- **A quiz after every lesson**, marked immediately with explanations
- **Live progress** — every number is computed from your real results, nothing is stored pre-calculated
- **A community** laid out like a chat app, with channels and `@mentions`
- **An admin role** that can publish new lessons from inside the app, so content can be added without releasing a new version

It runs on **Android and the web** from one codebase, and operates entirely on
free tiers.

### Q. In one sentence, what problem does it solve?

Hearing people are usually willing to learn a few signs, but there is nowhere
structured, private and free to practise until they are no longer embarrassed to
try — so the burden of communication keeps falling on the deaf person.

### Q. What is the single most technically interesting part?

**Progress is never stored — it is computed.** There is no "completion
percentage" field anywhere in the database. Three live data streams feed one
pure function that re-runs whenever any of them changes. So the moment you
finish a quiz, every screen updates with no refresh, and there is exactly one
definition of each number rather than one in the app and one in the database.

---

## 2. Frontend

### Q. What did you use for the frontend?

**Flutter 3.47.2**, written in **Dart 3.13.2**.

- Flutter is Google's UI toolkit. You write the interface once and it compiles
  to a native Android app *and* to a web app.
- It does not use the platform's own widgets — it draws every pixel itself with
  its own rendering engine. That is why the app looks identical on Android and
  in a browser.

### Q. Why Flutter and not React Native, or native Android?

| Option | Why not |
| --- | --- |
| **Native Android (Kotlin)** | Would have given me one platform. I needed a web version too, which would have meant a second codebase in a second language. |
| **React Native** | Reaches Android and iOS well, but its web story is weaker, and it bridges to native widgets, so the UI drifts between platforms. |
| **Flutter** | One codebase, genuinely identical rendering on Android and web, and a strong animation and custom-painting system — which I needed for the hand-drawn visuals. |

### Q. What design system did you use?

**Material 3**, Google's current design language, with one twist: the entire
colour scheme is generated from a **single seed colour** (`#6C5CE7`, a violet)
using `ColorScheme.fromSeed()`.

- I pick one colour; Material generates every surface, container and text colour
  for both light and dark mode.
- This is why nothing in the app clashes — the contrast relationships are
  computed, not hand-picked.
- **Where:** `lib/core/theme/app_theme.dart`

### Q. Did you use any UI component libraries?

No third-party component library. Everything is Flutter's built-in widgets plus
a shared kit I wrote in `lib/widgets/` — cards, the progress ring, the pressable
wrapper, badges.

The distinctive visuals are **drawn, not imported**:

- `lib/widgets/signing_space.dart` — the moving trail on the landing page
- `lib/screens/dashboard/lesson_path.dart` — the winding lesson path
- `lib/widgets/practice_strip.dart` — the 14-day activity chart

All three use `CustomPaint`, Flutter's low-level drawing API. No illustration
files, nothing to license, and they recolour themselves from the theme in light
or dark mode.

### Q. What fonts do you use and why are they bundled?

- **Nunito** for body text — rounded, highly legible at small sizes
- **Outfit** for headings — geometric and modern, set with slightly negative
  letter spacing at large sizes

Both are bundled as files in `assets/fonts/` rather than fetched from Google
Fonts at runtime. Two reasons:

1. **No network request on first paint** — no flash of the wrong font
2. **The app renders correctly offline**

Declared in `pubspec.yaml` under `flutter: fonts:`.

---

## 3. Backend

### Q. What did you use for the backend?

I did not write a backend. The app uses **backend-as-a-service**:

| Service | What it does here |
| --- | --- |
| **Firebase Authentication** | Sign-up, sign-in, sessions, password reset. Email/password and Google |
| **Cloud Firestore** | The database. A NoSQL document database with real-time listeners |
| **Firebase Hosting** | Serves the web build at `signals-app-a7b29.web.app` |
| **Cloudinary** | Stores, transcodes and serves the lesson videos |

The app talks directly to these from the client. There is **no server-side code
I wrote** — no Node service, no Python API, no Cloud Functions.

### Q. Then what enforces your business rules?

**`firestore.rules`**, in the project root.

This is the important point. It is a rules file that runs **on Google's servers**
on every single read and write. It is not client code, so it cannot be bypassed
by modifying the app.

It enforces:

- Only an admin can create or edit a lesson
- A learner can read and write only their *own* progress
- Nobody can promote themselves to admin
- Quiz attempts are append-only — a score cannot be edited later
- Nothing at all is readable while signed out

So the security layer that a traditional backend would provide exists; it is just
expressed as rules rather than as server code.

### Q. Why backend-as-a-service instead of writing your own backend?

**Five reasons, in order of how much they mattered:**

1. **Real-time is the core feature.** Firestore pushes changes to connected
   clients automatically. A REST API I wrote would need polling or WebSockets
   built by hand to achieve the same thing. "Progress updates live" would have
   been the hard part instead of a free property.

2. **Authentication is genuinely hard to get right.** Password hashing, reset
   tokens, session expiry, Google OAuth. Getting any of it subtly wrong is a
   real security problem. Firebase Auth is maintained by people whose job it is.

3. **No server to operate.** No uptime, no scaling, no patching, no cost.

4. **Security rules sit next to the data.** The rule protecting a document lives
   with that document rather than being scattered across endpoint handlers where
   one forgotten check is a breach.

5. **It fits the scale honestly.** This is an app with lessons and learners, not
   a system with complex transactional workflows. A custom backend would have
   been more code to achieve less.

### Q. What are the downsides of that choice? *(Expect this follow-up.)*

I should name these without being prompted — it shows I chose rather than
defaulted:

- **Vendor lock-in.** Firestore's query model and rules language are
  Google-specific. Moving to another provider means rewriting the data layer.
- **No place for server-only logic.** Anything that must be trusted — verifying
  a payment, sending email, calling a paid API with a secret key — has nowhere
  to run. Cloud Functions would solve it but require the paid Blaze plan.
- **Limited querying.** No joins, no aggregations. Some things are done in Dart
  that SQL would do in the query.
- **Costs scale with reads**, not with compute. A badly written listener is
  expensive in a way it would not be on a server you own.

### Q. Why Cloudinary for video and not Firebase Storage?

Two reasons:

1. **Firebase Storage requires the paid Blaze plan.** Cloudinary's free tier
   does not. Using it is what keeps the whole project free.
2. **Cloudinary does media work Firebase Storage does not** — it transcodes the
   video, reports its true duration, and generates a poster thumbnail by
   changing the URL.

**The security detail worth volunteering:** uploads are **unsigned**. The app
sends the file plus a preset name, never an API secret. That is deliberate —
anything compiled into an APK or a web bundle can be extracted from it, so a
secret key must never be in the client.

- **Where:** `lib/data/cloudinary_service.dart`

---

## 4. Architecture and layering

### Q. How is the code organised?

Four layers, with a strict rule about who may talk to whom:

```
Screens / Widgets     (what you see)
        ↓  watches
Providers             (state, Riverpod)
        ↓  calls
Repositories          (the only code that touches Firestore or HTTP)
        ↓
Firebase / Cloudinary
```

**The rule:** a widget never imports `cloud_firestore`. A screen watches a
provider; a provider calls a repository; a repository is the only thing holding
a database handle.

### Q. Why does that rule matter?

Three practical benefits:

1. **Testability.** Logic lives in pure functions with no Firebase import, so
   tests run in milliseconds with no emulator and no network.
2. **One place to change.** If a collection path changes, I edit one repository,
   not forty widgets.
3. **It is navigable.** If something is wrong with the data, the answer is in
   `lib/data/`. If something is wrong with the look, it is in `lib/widgets/`.

### Q. Where would I find the code for X?

| Looking for | Directory |
| --- | --- |
| Anything that talks to the database | `lib/data/` |
| Anything that computes a number | `lib/models/progress_summary.dart` |
| State wiring | `lib/providers/` |
| Screens | `lib/screens/`, one folder per feature |
| Reusable UI | `lib/widgets/` |
| Routes and the auth redirect | `lib/router/app_router.dart` |
| Theme and colours | `lib/core/theme/app_theme.dart` |
| Tunable numbers (pass mark, etc.) | `lib/core/constants.dart` |
| Security rules | `firestore.rules` (project root) |

---

## 5. State management

### Q. What state management did you use?

**Riverpod 3** (`flutter_riverpod`).

In plain terms: state management is how different screens share data without
passing it down manually through every widget. Riverpod lets me declare a piece
of state once and let any screen "watch" it.

### Q. Why Riverpod and not Provider, BLoC or setState?

| Option | Why not |
| --- | --- |
| **setState** | Fine for one widget. Useless for data several screens need. |
| **Provider** | Riverpod is by the same author and fixes its main flaws: it is compile-time safe and does not depend on the widget tree, so providers can be tested without mounting a UI. |
| **BLoC** | Powerful but heavy — a lot of boilerplate per feature. Appropriate for complex event-driven state; too much ceremony for mine. |
| **Riverpod** | Compile-safe, testable, and `StreamProvider` maps perfectly onto Firestore's real-time listeners. |

### Q. What types of provider did you use?

| Type | Used for | Example |
| --- | --- | --- |
| `StreamProvider` | Live Firestore data | `lessonsProvider`, `forumPostsProvider` |
| `Provider` | Derived values computed from others | `progressSummaryProvider` |
| `NotifierProvider` | Small mutable UI state | filters, search text, theme mode |

**Note on Riverpod 3:** `StateProvider` is no longer in the main API, which is
why mutable state uses `Notifier` classes.

### Q. How do SharedPreferences get into the app?

They are loaded **once** in `main()` before the app starts, then injected with
`overrideWithValue`. That means every screen downstream can read settings
*synchronously* — no loading spinner for a theme preference.

- **Where:** `lib/main.dart`, and the placeholder provider in
  `lib/providers/app_providers.dart`

---

## 6. Routing and navigation

### Q. How does navigation work?

**`go_router`** — declarative routing. I declare a table of URLs and which
screen each one builds, rather than imperatively pushing screens.

- **Where:** `lib/router/app_router.dart`

### Q. Why go_router rather than Navigator directly?

- **The web needs real URLs.** With plain `Navigator`, a web build has no
  meaningful address bar and no deep links. `go_router` makes every screen
  addressable.
- **Redirects are centralised.** All auth logic is in one `redirect` function
  rather than scattered checks in every screen's `initState`.
- **It supports nested navigators** for tabs, which I needed.

### Q. How do the bottom tabs work?

`StatefulShellRoute` with four branches — Home, Lessons, Progress, Community.

- Each tab keeps **its own navigation stack and scroll position**, so switching
  away and back does not reset you.
- Full-screen flows — video player, quiz, results, settings — are pushed on the
  **root** navigator, *above* the tab bar. That is deliberate: someone mid-quiz
  should not be able to tab away by accident.

### Q. How does the app decide where to send someone?

A pure function, `authRedirect()`, in `lib/router/app_router.dart`:

1. If auth has not resolved yet → hold on the splash screen. This stops a
   returning user seeing a flash of the login page.
2. If signed out and not on a public route → go to `/welcome`.
   Public routes are `/welcome`, `/login`, `/signup`.
3. If signed in and sitting on a public route → go to `/home`.
4. Otherwise → let them through.

**Why it is a free function:** it takes three booleans and a string and returns
a string. No Flutter, no Firebase. So every rule above is unit-tested without
mounting a navigator — see `test/auth_redirect_test.dart`.

### Q. What is `popOr()` and why does it exist?

A back link can only "pop" a screen it was pushed on top of. On the web, every
screen is also a URL — so a page can be opened **cold** from a pasted link, a
bookmark or a reload, with nothing underneath it. A plain `pop()` then throws
*"There is nothing to pop"*.

`context.popOr(fallback)` pops when it can and navigates to a sensible route
when it cannot.

**Be honest if asked:** only the sign-up screen uses it so far. Nine other call
sites still use bare `pop()` and would throw if opened cold on the web. It is a
known, documented gap.

---

## 7. Database and data model

### Q. What database and what kind is it?

**Cloud Firestore** — a NoSQL **document** database.

- Data is stored as **documents** (like JSON objects) inside **collections**
  (like folders).
- There are no tables, no rows, and no joins.
- Documents can contain **subcollections**, which is how I model ownership.

### Q. Walk me through your data model.

Eight collections:

```
users/{uid}                              profile, role, settings
  progress/{lessonId}                    per-lesson state
  attempts/{attemptId}                   quiz history, append-only

public_profiles/{uid}                    display name ONLY

lessons/{lessonId}                       lesson metadata + video URL
  questions/{questionId}                 the quiz

forum_posts/{postId}                     community messages
  replies/{replyId}                      thread replies
```

### Q. Why are questions a subcollection of a lesson, rather than a top-level collection with a lessonId field?

Two reasons:

1. **The security rule becomes a one-liner** — `match /lessons/{id}/questions/{qid}`
   inherits the lesson's context. The alternative needs a rule that reads another
   document to check ownership.
2. **Deleting a lesson's quiz is obvious** — the questions live inside it.

### Q. Why do progress and attempts live under the user?

Because the security rule then reduces to **"this user only"** with no
query-level filtering to get wrong. If progress were top-level with a `userId`
field, every query would need a filter, and forgetting one in a single place
would leak another learner's data.

### Q. Why is there a separate `public_profiles` collection?

This is a good question to be asked, because the reasoning is not obvious.

- The `@mention` feature needs to show a list of people you can mention.
- That means reading other users' display names.
- But `users/{uid}` also holds an **email address** and a **role**.
- **Firestore security rules cannot restrict a read to particular fields** — a
  read is all-or-nothing on the document.

So "let everyone read everyone's name" was only expressible as a **second
collection** holding exactly one field. `users/{uid}` stays private; display
names live in `public_profiles/{uid}`, readable by any signed-in learner and
writable only by its owner — and because the uid is the document id, nobody can
publish a name under somebody else's account.

### Q. How do existing users get a public profile?

`AuthRepository.ensureProfile()` runs on **every sign-in** and writes the public
profile **outside** its "does this already exist" check. So accounts created
before the feature existed backfill themselves the next time their owner opens
the app. No migration script.

### Q. You said no joins. How do you show an author's name on a post?

**Denormalisation** — I store `authorName` on the post itself, copied at write
time.

- **Trade-off:** if someone changed their name, old posts would show the old one.
- **Why that is acceptable:** a post is a historical record; showing the name
  they had when they wrote it is arguably more correct, and it saves a read per
  post.

The same reasoning applies to `replyCount`, which is a stored counter
incremented in the same batch as the reply, so it cannot drift.

---

## 8. Security

### Q. How do you stop a learner from making themselves an admin?

The security rule on `users/{uid}` permits a self-update **only if the role
field is unchanged**:

```
allow update: if isSelf(uid)
  && request.resource.data.role == resource.data.role;
```

So admin can only be granted from the Firebase console or by a server with
admin credentials. A learner who modified the app still cannot do it, because
the check runs on Google's servers.

### Q. How do you stop a learner from writing a lesson?

The rule calls a helper that reads the caller's *own* user document and checks
their role:

```
function isAdmin() {
  return signedIn()
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

**Cost:** one extra document read per admin write. Acceptable at this scale, and
it avoids needing a Cloud Function to set custom auth claims.

### Q. Could someone cheat a quiz?

Partly, and I should say so plainly:

- Correct answers **are** readable by learners, because the app shows the
  explanation immediately after answering, which needs the answer client-side.
- So a determined learner could read the correct answers from the data.
- **Why that is the right trade-off:** this is a practice app, not an invigilated
  exam. Someone cheating only cheats themselves.
- **What a graded exam would need:** marking on the server via a Cloud Function,
  with answers never sent to the client. That requires the paid plan.

What *is* protected: attempts are **append-only**. You cannot edit or delete a
past score to inflate your average.

### Q. Are your API keys exposed?

Yes, and that is fine — but I should explain why rather than brush it off.

- **Firebase keys are identifiers, not secrets.** They say which project to talk
  to. Security comes from the rules, not from hiding the key. Google documents
  this explicitly.
- **The Cloudinary upload preset is not a secret either** — an unsigned preset
  only permits adding a file to one configured folder.
- **The Cloudinary API secret is never used by the app at all**, so it cannot
  leak from it.

They are still gitignored, so that a clone of the repo does not point at my
accounts.

---

## 9. How specific features work

### Q. How does live progress work? *(The most likely "how does it work" question.)*

**Nothing derived is stored.** There is no completion-percentage field anywhere.

1. Three `StreamProvider`s listen to Firestore: lessons, progress documents,
   quiz attempts.
2. `progressSummaryProvider` watches all three and calls
   `ProgressSummary.from(...)` — a **pure function**.
3. When any stream emits, the function re-runs and every screen watching it
   rebuilds.

**The moment that makes it visible:** submitting a quiz writes the attempt
document and the progress document **in one transaction**. Both streams fire,
the summary recomputes, and the dashboard percentage has already moved by the
time you navigate back.

- **Where:** `lib/models/progress_summary.dart` (the computation),
  `lib/providers/progress_providers.dart` (the wiring)

### Q. What does it compute?

| Statistic | How |
| --- | --- |
| Completion % | Progress docs with `status == completed` ÷ total lessons |
| Average score | Mean of the **best** attempt per lesson — so retrying helps rather than dilutes |
| Per-category | Lessons grouped by category |
| Day streak | Consecutive days back from today with at least one attempt |
| Perfect runs | Attempts where score equals total |
| Badges | Pure functions of the statistics above, so they light up live |

### Q. How does the lesson state machine work?

Three states — `notStarted`, `inProgress`, `completed` — and only **two stored
booleans** decide which one you are in:

- `videoCompleted` — true once you pass 95% of the video
- `quizPassed` — true once you score 70% or more

`status` is **re-derived** from those two on every write, never set directly.
That means it cannot get out of sync with the facts.

**Three transactional writes move it:**

| Write | Trigger | Effect |
| --- | --- | --- |
| `markVideoStarted` | First playing frame | → `inProgress`. Will not demote a completed lesson on rewatch |
| `markVideoCompleted` | Position ≥ 95% | Unlocks the quiz |
| `submitAttempt` | Quiz finished | Writes the attempt **and** folds the result into progress |

- **Where:** `lib/data/progress_repository.dart`

### Q. Why 95% and not 100% for "video watched"?

Trailing frames are often unreachable on some codecs — the player reports 99.4%
and stops. Demanding 100% would leave quizzes **permanently locked**. 95% is
far enough through that you have genuinely watched it.

- **Where:** `AppConstants.videoCompleteFraction` in `lib/core/constants.dart`

### Q. How does video upload work?

1. The admin picks a file (`file_picker`).
2. The app sends it as a **multipart POST** straight to Cloudinary with an
   unsigned upload preset — no secret involved.
3. Cloudinary returns a secure URL and the **real duration**, so the admin never
   types it in.
4. The poster thumbnail comes free by swapping `/video/upload/` for
   `/image/upload/` in the URL and asking for a `.jpg`.
5. The lesson and all its questions are written to Firestore in **one batch**,
   so a lesson can never appear with a half-written quiz.

- **Where:** `lib/data/cloudinary_service.dart`, `lib/screens/admin/add_lesson_screen.dart`

### Q. How do @mentions work?

1. **Who can be mentioned** — everyone in `public_profiles`, plus anyone who has
   posted (a fallback, in case the directory has not caught up).
2. **Typing `@`** shows a suggestion strip. A handle is the person's first name,
   lowercased — "Ada Lovelace" is `@ada`.
3. **On send**, the app parses the text, resolves handles to user IDs, and stores
   them on the post as `mentionedUids`.
4. **The Mentions view** filters the posts the app already has in memory.

**Why resolve on write rather than on read:** the app already streams every
post, so the Mentions view costs **no extra database query and no index**. If I
resolved on read I would need a separate indexed query.

**Edge cases handled:** `ada@example.com` is not a mention (the `@` does not
start a word); an unknown handle stays plain text rather than being highlighted,
because highlighting it would promise a notification that was never sent; and if
two people share a first name, both are notified rather than picking one at
random.

- **Where:** `lib/screens/forum/mentions.dart`

### Q. How do unread counts work?

- A timestamp per channel is stored in `SharedPreferences`.
- The count is the number of posts in that channel newer than that timestamp.
- **Your own posts never count** — being told you have one unread message you
  wrote yourself is noise.
- A channel you have never opened counts everything.

**Why local and not in the database:** syncing it would need a new subcollection
under the user, and the rules only grant `progress` and `attempts` there — so it
would need a rules change and a deploy. The honest trade-off is that read state
is **per device**: your phone and your browser keep separate counts.

- **Where:** `lib/screens/forum/channels.dart` (the counting),
  `lib/providers/forum_providers.dart` (the storage)

### Q. The chat composer is one box, but a post needs a title. How?

`titleFromMessage()` derives one — the first line, or the first sentence if it is
long enough to be useful, truncated on a word boundary at 120 characters.

- `"Hi. I am new here"` stays whole rather than becoming the useless title `"Hi."`
- Whitespace-only input still returns something non-empty, so the write can never
  be rejected for an empty title (the rules require 1–120 characters)
- The **full message is always kept as the body** — the derived title is only
  what the thread view and admin console display

### Q. How does the lesson path drawing work?

- Node positions are calculated on a **sine wave** down the column, so the path
  winds left and right.
- The curve between them is drawn with **cubic Bézier** segments whose control
  points are pulled vertically, giving an S-shape rather than a kink.
- The **lit portion of the curve is exactly the completion fraction** — the
  picture cannot disagree with the number.
- `PathMetric` is used to extract a fraction of the path, which is how the
  draw-on animation works.

- **Where:** `lib/screens/dashboard/lesson_path.dart`

### Q. How are the sound effects and confetti made?

They are **generated by committed Python scripts**, not downloaded:

- `tool/generate_sounds.py` synthesises six WAV cues
- `tool/generate_lottie.py` generates the confetti animation

So there is no licensing question about any bundled media, and either can be
regenerated.

---

## 10. Every file in the repository

### Q. What is `pubspec.yaml`?

The project manifest — Flutter's equivalent of `package.json`.

It declares four things:

1. **Metadata** — name, description, version (`1.0.0+1`: version name + build number)
2. **The Dart SDK constraint** — `sdk: ^3.13.2`
3. **Dependencies** — every package the app uses, with version constraints
4. **Assets and fonts** — which folders get bundled into the build

**On the `^` in `^4.15.0`:** it means "this version or any later one that does
not change the major number" — so 4.x is allowed, 5.0 is not, because a major
bump may break the API.

### Q. What is `pubspec.lock` and should it be committed?

It records the **exact** version of every package actually resolved, including
transitive ones.

- `pubspec.yaml` says "4.15.0 or compatible"; `pubspec.lock` says "exactly
  4.15.2".
- **Yes, it is committed.** For an application you want reproducible builds —
  everyone and every CI run gets byte-identical dependencies. (For a *library*
  you would not commit it.)

### Q. What is `.gitignore` and what is in yours?

It lists files Git should not track. Mine excludes four groups:

| Group | Why |
| --- | --- |
| `build/`, `.dart_tool/` | Generated output. Large, and rebuildable |
| `*.iml`, `.idea/` | Editor settings, personal to my machine |
| `lib/firebase_options.dart`, `lib/core/config/app_config.dart`, `android/app/google-services.json`, `.firebaserc` | **Project-specific config.** Not secrets — they are identifiers — but keeping them out means a clone does not point at my Firebase and Cloudinary accounts |
| `release/` | Built APKs, kept locally for handing around |

**Be ready for:** "so you have no secrets in the repo?" — correct, and I can
explain why those files are identifiers rather than secrets (see §8).

### Q. What is `analysis_options.yaml`?

Configuration for the Dart static analyser — the tool that catches mistakes
before you run the code.

- It includes `package:flutter_lints`, the standard Flutter rule set
- It excludes generated folders from analysis
- It **disables two specific rules**, each with a comment explaining why — for
  example `prefer_initializing_formals`, because every repository takes public
  named parameters and stores them privately, and following that rule would
  expose a private field name to callers

`flutter analyze` currently reports **zero issues**.

### Q. What is `firebase.json`?

Firebase CLI configuration. It declares:

- Which folder to deploy as the website (`build/web`)
- A **rewrite** sending every URL to `index.html` — required, because this is a
  single-page app and the routing happens in Dart, not on the server
- **Cache headers** (see below)
- Where the rules and index files live

### Q. Tell me about the cache headers — there is a story here.

Yes, and it is worth telling because it was a real bug.

The original config marked all JavaScript as `immutable` with a one-year cache.
**Flutter's web output does not put a content hash in its filenames** —
`main.dart.js` is called that in every build. So returning visitors were pinned
to whatever build they first loaded, for a year. I deployed new code and the
site still showed the old version.

A second, subtler issue: a header rule for `/index.html` **does not match a
request for `/`**, so the root page was separately cached for an hour.

**The fix:** entry points now use `no-cache, must-revalidate` — ETags make
revalidation a cheap 304 — and bundled assets get a day rather than a year.

- **Where:** `firebase.json`, and documented in `docs/08-web-deploy.md`

### Q. What is `firestore.rules`?

The security rules — effectively the backend logic layer. Covered in §8.

### Q. What is `firestore.indexes.json`?

Declares **composite indexes**. Firestore automatically indexes single fields,
but a query that filters on one field *and* sorts by another needs an index
declared in advance.

Mine has one: `attempts` on `lessonId` ascending plus `createdAt` descending,
backing the "most recent attempt for this lesson" query.

### Q. What is `.firebaserc`?

Maps the local project to a Firebase project ID so the CLI knows where to
deploy. Gitignored, because it names *my* project.

### Q. What is `.metadata`?

Generated by Flutter. It records which Flutter version created the project so
the tool can apply migrations on upgrade. Committed, not hand-edited.

### Q. What is in the `android/` folder?

The native Android wrapper — Gradle build files, the manifest, the app icon, and
`google-services.json` (gitignored) which tells the Firebase SDK which project
to use.

**On `minSdk`:** the effective floor is **24** (Android 7.0), but note it is not
hardcoded — `build.gradle.kts` uses `flutter.minSdkVersion`, and Flutter 3.47
defaults that to 24. `firebase_auth` independently requires 23 or above, so the
default already satisfies it. If asked "where is it set", the honest answer is
"inherited from Flutter, not pinned by me".

### Q. What is in the `web/` folder?

The web shell — `index.html`, the manifest and icons. Flutter injects the
compiled app into this page.

### Q. What is in `tool/`?

Two Python scripts that generate the sound cues and the confetti animation. They
are committed so the assets can be regenerated or replaced, and so there is no
licensing ambiguity about any bundled media.

### Q. What is in `docs/`?

Seventeen numbered documents plus this one — setup guides, architecture, the
security model, the demo script, troubleshooting, and the case study report.
`docs/00-index.md` lists them all.

---

## 11. Why this and not that

A rapid-fire section. These are the comparisons most likely to be probed.

| Decision | Alternative | Why mine |
| --- | --- | --- |
| **Flutter** | React Native, native | One codebase for Android *and* web with identical rendering |
| **Riverpod** | Provider, BLoC | Compile-safe, testable without a widget tree, maps onto Firestore streams |
| **Firestore** | SQL (Postgres/MySQL) | Real-time listeners are the core feature; no server to run |
| **BaaS** | Custom backend | No server to operate, auth solved, security next to the data |
| **Cloudinary** | Firebase Storage | Storage needs the paid plan; Cloudinary transcodes and thumbnails for free |
| **Unsigned upload** | Signed upload | A signed upload needs an API secret, which can be extracted from any client build |
| **Computed progress** | Stored counters | One definition of each number; cannot drift out of sync |
| **Role in Firestore** | Custom auth claim | A claim needs a Cloud Function to set it; a field can be edited from the console |
| **Client-side sorting** | Firestore `orderBy` | Avoids a composite index per list, and lets a brand-new document appear instantly before its server timestamp resolves |
| **go_router** | Navigator 2.0 directly | Real URLs on the web, centralised redirects, far less boilerplate |
| **Bundled fonts** | `google_fonts` package | No network request on first paint; renders offline |
| **CustomPaint visuals** | Stock illustrations | Nothing to license, recolours with the theme, and distinctive |

---

## 12. Testing

### Q. How did you test it?

**154 automated tests across 16 files**, run with `flutter test`. Plus
`flutter analyze` for static analysis, which reports zero issues.

### Q. What kind of tests?

Two kinds:

1. **Unit tests on pure functions** — the majority. Because the logic is
   extracted out of widgets, I can test the day-streak rule or the redirect
   logic with no Firebase and no UI.
2. **Widget tests** — render a screen at a given size and assert it lays out
   without throwing.

### Q. Give an example of a test catching a real bug.

Four, actually, and they are worth naming:

- **A hero section overflowed by 61 pixels on a 360×640 phone.** It was a
  fixed-height box centring a column that could exceed it. Only visible on small
  screens or at large font scales.
- **A badge tile overflowed its row by 9 pixels** whenever its label wrapped to a
  third line. Pre-existing, and only visible on screens tall enough to lay that
  row out at all.
- **Category colours failed a dark-mode check** — five of six sat outside the
  lightness band where colours stay distinguishable on a dark background.
- **A back link threw on web deep links** after I added the landing page.

### Q. Why so many layout tests at different screen sizes?

Because this project has repeatedly shipped **unbounded-constraint bugs that
only appear at viewport sizes nobody develops at**. Two of the four bugs above
are exactly that. So the main screens are now tested at five sizes from a small
phone to a desktop.

### Q. What is *not* tested?

Honest answer:

- No integration tests against a live Firebase (would need the emulator suite)
- No tests of the security rules themselves (the Firebase rules test SDK could do
  this)
- Video playback is not tested — the test environment has no video stack

---

## 13. Building and deploying

### Q. How do you build the Android app?

```
flutter build apk --release
```

Produces a universal APK (~63 MB) containing all CPU architectures. With
`--split-per-abi` it produces smaller per-architecture builds (~24 MB), which is
what I actually distribute.

**Signing:** release builds use the local debug keystore. That is fine for
sideloading, and it matters for one reason — **Google Sign-In only works if that
key's SHA-1 fingerprint is registered in Firebase.** Building on a different
machine would break sign-in until that machine's fingerprint was added.

### Q. How do you deploy the web version?

```
flutter build web --release
firebase deploy --only hosting
```

Firebase Hosting serves it on a global CDN with automatic HTTPS, and deploys are
atomic with one-click rollback.

### Q. How do you deploy the security rules?

```
firebase deploy --only firestore:rules,firestore:indexes
```

**Important point:** rules deploy **separately** from hosting. Deploying the web
app does not update the rules — a mistake that is easy to make and hard to
notice, because the app keeps working on the old rules.

### Q. How do you verify a deploy actually worked?

Compare the served file against the local build:

```
curl -s https://signals-app-a7b29.web.app/main.dart.js | shasum
shasum build/web/main.dart.js
```

If the hashes match, the server is correct and anything stale is browser cache.
This is how I diagnosed the `immutable` header bug.

---

## 14. Limitations and honest answers

Naming these yourself is worth more than being caught out by them.

### Q. What would you do differently at scale?

| Current | At scale |
| --- | --- |
| Sorting in Dart | Server-side paginated queries with composite indexes |
| Quiz marked on the client | Cloud Function marking, answers never sent to the client |
| Progress recomputed on every emission | Fine at this volume; at thousands of lessons, incremental aggregation |
| Role as a Firestore field | Custom auth claim, set by a Cloud Function — no extra read per write |
| Unread state in local prefs | Synced subcollection |

### Q. What is incomplete?

- **Nine `pop()` call sites** still throw if their screen is opened cold on the
  web. `popOr()` exists; the conversion is unfinished.
- **Mentions inside replies** highlight in-thread but do not appear in the global
  Mentions view — that needs a collection-group query, a rules addition and an
  index.
- **No offline write queue** beyond Firestore's built-in caching.
- **No iOS build**, deliberately — it needs Xcode, a separate Firebase app,
  CocoaPods and an Apple Developer account. The web build covers iPhone users.

### Q. Why no payment or monetisation?

I considered it (Razorpay in test mode) and chose not to, for a specific
technical reason: **payment verification must happen somewhere the user cannot
tamper with.** With no server, the app would have to grant its own premium
status, which anyone could do without paying. Doing it correctly needs Cloud
Functions and therefore the paid plan, which would end the free-tier property.

---

## 15. Dart language questions

### Q. What is Dart and why does Flutter use it?

Dart is a language by Google, designed for building user interfaces. Flutter
uses it for three reasons that matter:

1. **It compiles two ways.** During development it uses **JIT** (just-in-time),
   which is what makes hot reload possible. For release it uses **AOT**
   (ahead-of-time) to native machine code, so the shipped app is fast.
2. **It compiles to JavaScript**, which is how the same code runs on the web.
3. **Garbage collection is tuned for UI work** — short-lived objects (widgets
   get rebuilt constantly) are cheap to allocate and collect.

### Q. What is hot reload and how is it different from hot restart?

| | What it does | When it fails |
| --- | --- | --- |
| **Hot reload** (`r`) | Injects changed code into the running app and rebuilds the widget tree. **State is kept** | Changes to `main()`, global variables, `pubspec.yaml`, or native code |
| **Hot restart** (`R`) | Restarts the Dart VM. **State is lost**, but the app does not recompile from scratch | Native/plugin changes still need a full rebuild |

Possible because of the JIT compiler in debug mode. A release build has no hot
reload at all.

### Q. What is null safety?

Dart distinguishes between a type that can be null and one that cannot:

- `String name` — can **never** be null. The compiler guarantees it
- `String? name` — may be null, and the compiler forces you to handle that

This is **sound** null safety: if the compiler says it cannot be null, the
runtime does not need to check.

**In this project:** `AppUser? user` on the dashboard is nullable because auth
may not have resolved yet, which is why you see `user?.firstName ?? 'there'`.

### Q. Explain `var`, `final`, `const` and `late`.

| Keyword | Meaning |
| --- | --- |
| `var` | Type inferred, value can change |
| `final` | Set **once at runtime**, cannot be reassigned |
| `const` | **Compile-time** constant. Baked into the binary before the app runs |
| `late` | Non-nullable, but initialised later than its declaration |

**The `final` vs `const` distinction matters:**

```dart
final now = DateTime.now();   // fine — computed at runtime
const now = DateTime.now();   // ERROR — not knowable at compile time
```

**`late` in this project:** `lib/widgets/signing_space.dart` declares
`late final AnimationController _c` because the controller needs `vsync: this`,
which does not exist until the State object is constructed.

### Q. Why does `const` matter so much in Flutter specifically?

Because a `const` widget is **created once and reused forever**. When Flutter
rebuilds a tree, it can see that a `const` widget is identical to the previous
one and skip rebuilding that entire subtree.

That is why you see `const SizedBox(height: 16)` everywhere in this codebase
rather than `SizedBox(height: 16)`. It is not style — it is a measurable
performance difference in a tree that rebuilds on every stream emission.

### Q. What is a `Future`? What does `async`/`await` do?

A **`Future`** is a promise of a value that is not ready yet — a network call, a
database write, reading a file.

`async` marks a function as returning a Future. `await` pauses inside that
function until the Future completes, so asynchronous code **reads top to
bottom** instead of nesting callbacks.

**In this project:** every repository write returns a Future —
`Future<void> submitAttempt(...)`.

### Q. What is a `Stream`, and how is it different from a `Future`?

| | Delivers |
| --- | --- |
| `Future` | **One** value, once |
| `Stream` | **Many** values, over time |

A Future is ordering a parcel. A Stream is a magazine subscription.

**This is the single most important concept in the project.** Firestore's
`.snapshots()` returns a Stream, so when a lesson is published, a new value
arrives down that stream and the UI rebuilds. If it returned a Future, the app
would need a refresh button.

### Q. What is a mixin? Do you use one?

A mixin lets a class reuse code from multiple sources without multiple
inheritance — `class A extends B with C, D`.

**Used in this project:** `SingleTickerProviderStateMixin` in
`lib/widgets/signing_space.dart`, and `TickerProviderStateMixin` in
`lib/screens/dashboard/lesson_path.dart` (which has two controllers, hence the
plural version). They give the State object the ability to drive animations in
step with the screen's refresh rate.

### Q. What is an extension method?

It adds a method to a type **you do not own**, without subclassing it.

**Used in this project:** `extension PopOr on BuildContext` in
`lib/router/app_router.dart` adds `context.popOr(fallback)` to Flutter's own
`BuildContext`. Also `extension SfxRef on Ref` in
`lib/providers/settings_providers.dart`, which adds `ref.playSfx(...)`.

### Q. What are records? (Dart 3)

A lightweight way to return several values without declaring a class.

**Used in this project:**

```dart
// lib/data/auth_repository.dart — a named record
Stream<List<({String uid, String displayName})>> watchDirectory()

// lib/widgets/common.dart — destructured from a switch
final (bg, fg, icon) = switch (status) { ... };
```

Before records you would have declared a class or returned a `Map`, losing type
safety.

### Q. What is pattern matching / a switch expression? (Dart 3)

A `switch` that **returns a value** rather than executing statements, and which
the compiler checks for exhaustiveness.

**Used in this project** — `lib/screens/dashboard/recall_nudge.dart`:

```dart
String agoLabel(int days) => switch (days) {
      <= 0 => 'today',
      1 => 'yesterday',
      < 14 => '$days days ago',
      _ => 'a while back',
    };
```

Note it matches on **ranges**, not just equality.

### Q. What is a factory constructor?

A constructor that does not have to create a new instance — it can return a
cached one, a subclass, or build the object from something else.

**Used throughout this project:** every model has
`factory Lesson.fromDoc(DocumentSnapshot doc)`, which converts a Firestore
document into a Dart object. It is a factory because it needs logic — handling
missing fields, type conversions — before it can construct anything.

### Q. What are named, optional and required parameters?

```dart
const LessonCard({
  super.key,                  // optional named
  required this.lesson,       // required named
  this.index = 0,             // optional named with a default
});
```

Flutter uses named parameters heavily because a widget with eight positional
arguments would be unreadable at the call site.

### Q. What is cascade notation (`..`)?

Calls several methods on the same object without repeating its name:

```dart
final path = Path()
  ..moveTo(x, y)
  ..cubicTo(...)
  ..close();
```

**Used in** `lib/screens/dashboard/lesson_path.dart` for building paths.

### Q. What are collection-if and collection-for?

Conditionals and loops **inside** a list literal — very common in Flutter because
widget children are lists:

```dart
children: [
  const Header(),
  if (isAdmin) const AdminCard(),      // collection-if
  for (final c in categories)          // collection-for
    CategoryRow(stats: c),
  ...moreWidgets,                      // spread
]
```

All three appear throughout `lib/screens/`.

### Q. What is an Isolate? Do you use one?

Dart is **single-threaded** — it has one event loop. An Isolate is a separate
thread with its own memory, which can only communicate by passing messages (no
shared memory, so no locks and no race conditions).

**Not used in this project**, deliberately. Isolates are for CPU-heavy work that
would block the UI — image processing, parsing a huge file. Everything heavy
here is **I/O**, not CPU: waiting on Firestore or on a network upload. `await`
already keeps those off the UI thread.

**If asked when I would use one:** if I were decoding video frames or running
on-device sign recognition, that would go in an Isolate via `compute()`.

---

## 16. Flutter framework questions

### Q. What does "everything is a widget" mean?

In Flutter, the UI is a tree of widgets. Not just visible things like buttons —
padding is a widget, alignment is a widget, even the theme is a widget.

A widget is **not** the thing on screen. It is a lightweight, immutable
*description* of what should be on screen. Flutter throws them away and rebuilds
them constantly; they are cheap by design.

### Q. StatelessWidget vs StatefulWidget?

| | Use when |
| --- | --- |
| `StatelessWidget` | The widget's appearance depends only on its inputs. Given the same inputs, it always looks the same |
| `StatefulWidget` | The widget has internal data that changes over time — a text field's contents, an animation's position, whether something is expanded |

**In this project:** most screens are `StatelessWidget` or `ConsumerWidget`,
because their data comes from Riverpod rather than from internal state.
`StatefulWidget` appears where there is genuinely local state — the search field
in the lesson library, the animation controllers in `lesson_path.dart`.

### Q. Why is the State separate from the StatefulWidget?

Because **widgets are destroyed and rebuilt constantly**, but state must
survive that. The widget is immutable and disposable; the `State` object
persists across rebuilds and is attached to the element tree instead.

### Q. What are the three trees?

This is a favourite advanced question.

| Tree | What it is |
| --- | --- |
| **Widget tree** | Your code. Immutable descriptions. Rebuilt constantly, cheap |
| **Element tree** | The bridge. Holds State objects, tracks *which* widget is at each position, decides what actually changed |
| **Render tree** | `RenderObject`s. Does layout, painting and hit testing. Expensive, so Flutter avoids recreating these |

**Why it matters:** when you call `setState`, Flutter rebuilds widgets, but the
element tree compares old and new, and only the parts that genuinely changed
touch the render tree. That is what makes rebuilding "the whole screen" cheap.

### Q. What is a BuildContext?

A handle to a widget's **location in the element tree**. It is how a widget
finds things above it — `Theme.of(context)`, `MediaQuery.of(context)`,
`Navigator.of(context)` all walk *up* the tree from that position.

**Common exam trap:** using a `context` after the widget is gone. That is why
async code in this project checks `if (!mounted) return;` before touching
context — for example in `lib/screens/forum/channel_composer.dart`.

### Q. What is a Key, and when do you need one?

Keys preserve identity when widgets of the same type are reordered or
swapped. Without one, Flutter matches widgets by type and position, so
reordering a list can attach the wrong state to the wrong item.

**Used in this project:**

- `ValueKey(_i)` on the cycling hero word in `welcome_screen.dart`, so
  `AnimatedSwitcher` knows the text genuinely changed and should animate
- `GlobalKey<FormState>` in the login and add-lesson forms, to call `validate()`
  from outside the form
- `GlobalKey<NavigatorState>` in `app_router.dart` for the root and shell
  navigators

**`GlobalKey` caution:** expensive, and gives access across the whole tree. Only
use it when you genuinely need to reach a widget from outside.

### Q. What are the StatefulWidget lifecycle methods?

| Method | When it runs |
| --- | --- |
| `initState()` | Once, when the State is created. Set up controllers and listeners |
| `didChangeDependencies()` | After `initState`, and **again** whenever an inherited widget it depends on changes |
| `build()` | Every rebuild |
| `didUpdateWidget()` | When the parent rebuilds with new configuration |
| `dispose()` | When the widget is removed. **Must** release controllers, or you leak |

**Used subtly in this project:** `lib/widgets/reveal.dart` relies on
`didChangeDependencies` firing every time an `InheritedNotifier` ticks, which is
how scroll-triggered reveals re-check their position.

### Q. Explain Flutter's layout model.

The one-line version, which is worth memorising:

> **Constraints go down. Sizes go up. Parent sets position.**

1. A parent passes **constraints** (min/max width and height) to its child
2. The child picks its own **size** within those constraints and reports back
3. The **parent** decides where to place it

**Why it matters practically:** a widget cannot ask "how big is the screen?" —
it only knows its constraints. If a parent gives **unbounded** constraints (as a
scrolling column does vertically) and the child tries to fill them, you get the
classic *"BoxConstraints forces an infinite width"* error. **This project hit
that exact bug twice** — both caught by the layout tests.

### Q. Why did your hero section overflow, and how did you fix it?

Honest answer, and a good one to have ready:

- It was a **fixed-height** box with a vertically centred column inside it
- On a short screen, or at a large OS font scale, the column needed more room
  than the box allowed, so it overflowed by 61 pixels
- **Fix:** use a `ConstrainedBox` with a **minimum** height instead. The content
  now determines the real height and can grow; the minimum only stops it
  collapsing

### Q. Row, Column, Stack, Expanded, Flexible — what is the difference?

| Widget | Does |
| --- | --- |
| `Row` / `Column` | Lay children out horizontally / vertically |
| `Stack` | Overlap children, positioned by `Positioned` or alignment |
| `Expanded` | **Forces** a child to fill the remaining space in a Row/Column |
| `Flexible` | **Allows** a child to shrink, but does not force it to grow |
| `Wrap` | Like a Row that moves to the next line when it runs out of room |

**In this project:** `Expanded` appears constantly to stop text overflowing in
rows; `Wrap` is used for the channel chips and the status pill row, because they
must reflow on narrow screens; `Stack` is how the lesson path puts nodes on top
of a painted curve.

### Q. ListView vs Column — when do you use which?

- **`Column`** builds all children immediately and does not scroll
- **`ListView`** scrolls, and `ListView.builder` is **lazy** — it only builds the
  items currently visible

**In this project:** the community transcript uses `ListView.builder` with
`reverse: true`, so the newest message sits at the bottom and the view opens
already scrolled there, like a chat app.

**Trap worth knowing:** a `ListView` inside a `Column` throws, because the Column
gives unbounded height and the ListView tries to be infinite. You need
`Expanded` or a fixed height.

### Q. What are Slivers?

Scrollable areas that can do more than a plain list — headers that shrink, grids
and lists mixed in one scroll view, lazy building throughout.

**Used in this project:** `CustomScrollView` with `SliverToBoxAdapter` in
`welcome_screen.dart` and `lesson_library_screen.dart`, which lets the canopy
header and the content scroll as one surface.

### Q. What is an InheritedWidget?

How data is shared **down** the tree efficiently. `Theme`, `MediaQuery` and
`Navigator` are all InheritedWidgets — that is why `Theme.of(context)` works
anywhere.

Crucially, only widgets that actually depend on it rebuild when it changes.

**Used in this project:** `lib/widgets/reveal.dart` uses an
`InheritedNotifier` so scroll notifications tick every `Reveal` below it, without
passing a callback down manually.

**Note:** Riverpod means you rarely write one yourself — but you should know
that Riverpod's own `ProviderScope` is built on this mechanism.

### Q. What is a Hero animation?

A shared-element transition: the same widget appears on two screens, and Flutter
animates it flying between them. Both sides use a `Hero` with the **same tag**.

**Used in this project:** the lesson thumbnail flies from the library card into
the lesson detail header. Tag is `LessonCard.heroTag(lesson.id)`.

**A real bug this caused:** with an `IndexedStack` shell, two tabs were mounted
at once, both containing a Hero with the same tag — which Flutter rejects. Fixed
by wrapping inactive branches in `HeroMode(enabled: false)`. There is a
regression test for it: `test/hero_tag_test.dart`.

### Q. Implicit vs explicit animations?

| | Example | Use when |
| --- | --- | --- |
| **Implicit** | `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher` | A value changes and you want it to animate. No controller needed |
| **Explicit** | `AnimationController` + `AnimatedBuilder` | You need to drive it — loop it, reverse it, sequence it, or paint from it |

**Both used here.** Implicit: `AnimatedContainer` in the tinted chips and status
pills. Explicit: `AnimationController` in `signing_space.dart` (a forever loop)
and `lesson_path.dart` (a one-shot draw-on plus a repeating pulse).

### Q. What is an AnimationController and what is `vsync`?

A controller produces values from 0 to 1 over a duration and notifies listeners
on every frame.

`vsync` takes a **TickerProvider**, which synchronises those updates to the
screen's refresh rate — and, importantly, **stops the ticker when the widget is
off-screen**, so an animation does not burn battery in a background tab. That is
what `SingleTickerProviderStateMixin` supplies.

**Always dispose a controller**, or it keeps ticking after the widget is gone.
Every controller in this project is disposed.

### Q. What is CustomPaint and why did you use it?

It gives you a canvas and lets you draw directly — lines, paths, gradients,
shadows.

**Used three times, for things widgets cannot express:**

- `signing_space.dart` — the trail on the landing page, including a tapering
  stroke built from 44 segments and a blurred head
- `lesson_path.dart` — the winding curve, with the lit portion extracted using
  `PathMetric` so it exactly matches the completion fraction
- `practice_strip.dart` — the activity chart

**Why not an image?** Nothing to license, it recolours itself from the theme in
light or dark mode, it scales to any screen size without pixelation, and it adds
no bytes to the bundle.

### Q. MediaQuery vs LayoutBuilder?

- **`MediaQuery`** — information about the **screen**: size, text scale,
  brightness, whether animations are disabled
- **`LayoutBuilder`** — the constraints **this particular widget** has been given

**Rule of thumb:** use `LayoutBuilder` when a widget should adapt to its own
space, `MediaQuery` when it should adapt to the device. This project uses
`MediaQuery.sizeOf(context)` for breakpoints and
`MediaQuery.disableAnimationsOf(context)` for reduced motion.

### Q. How does Flutter actually render on screen?

Flutter does **not** use the platform's native widgets. It paints every pixel
itself with its own engine — historically **Skia**, now **Impeller** on newer
versions.

**That is why** the app looks identical on Android and in a browser, and why a
Flutter app does not automatically look like a platform-native app.

**On the web** it compiles to JavaScript or WebAssembly and renders through
CanvasKit, which is why the bundle includes a sizeable `canvaskit/` folder.

---

## 17. Things you did *not* use — and why

Examiners often probe the edges of what you know. Having a reason ready is worth
more than having used the thing.

### Q. Why not BLoC?

BLoC is an event-driven pattern — you dispatch events, a bloc emits states.
Powerful for complex flows with many transitions, but it is a lot of boilerplate
per feature: events, states, the bloc itself.

My state is mostly **streams from Firestore plus small UI flags**. Riverpod maps
onto that directly with far less ceremony. BLoC would have been scaffolding
around a problem I did not have.

### Q. Why not GetX or MobX?

- **GetX** bundles state, routing and dependency injection together and relies on
  a global service locator. That makes testing harder and hides where things come
  from.
- **MobX** is reactive and capable, but needs **code generation** to be ergonomic.

Riverpod gave me compile-time safety without a build step.

### Q. Why no code generation (`build_runner`, `freezed`, `json_serializable`)?

Those generate `fromJson`/`toJson` and immutable classes with `copyWith`.

I wrote `fromDoc()` and `toMap()` by hand instead, because:

1. **There are only seven models**, so the saving would be small
2. **Firestore types need custom handling anyway** — `Timestamp` to `DateTime`,
   defaults for missing fields, and the legacy `topic`-to-`topics` fallback.
   Generated code would need annotations and converters for all of it
3. It avoids a build step that has to be re-run after every model change

**At twenty models I would use it.** At seven, hand-written is clearer.

### Q. Why no Isolates?

Covered in §15 — nothing here is CPU-bound. All the heavy work is I/O, which
`await` already handles without blocking the UI thread.

### Q. What are platform channels? Did you use them?

The bridge between Dart and native Android/iOS code, for things Flutter has no
API for.

**Not written directly** — but used indirectly by every plugin. `video_player`,
`audioplayers`, `google_sign_in` and `file_picker` are all Dart wrappers around
platform channels into native SDKs.

**If asked when I would write one:** if I needed the camera for real-time sign
recognition, and no package existed.

### Q. Did you write a custom RenderObject?

No. `CustomPaint` was enough — it gives a canvas without reimplementing layout.

A custom `RenderObject` is for when you need custom **layout** behaviour, not
just custom painting. The lesson path positions its nodes with `Positioned`
inside a `Stack`, so layout was already solved.

### Q. What about Flutter flavors?

Build variants — separate dev/staging/production apps with different Firebase
projects and bundle IDs.

Not used, because there is one environment. **With real users I would need
them**, so a test account could not write to production data.

### Q. Why no integration tests?

I have unit tests and widget tests. Integration tests drive the real app on a
device or emulator.

Not written because they need the **Firebase emulator suite** to avoid writing to
real data, which is meaningful setup. It is the clearest gap in the test
strategy, and I would add it next alongside security-rules tests.

### Q. What is deferred loading, and would it help your web build?

`deferred as` splits code so part of it downloads only when first needed.

**It would genuinely help here** — the admin screens are useless to a learner but
ship in every bundle. On Flutter web it would reduce the first download. I did
not do it because the bundle size was acceptable and it adds complexity to the
import graph.

### Q. Navigator 1.0 vs 2.0?

- **1.0** is imperative — `Navigator.push(...)`, a stack you manipulate
- **2.0** is declarative — you describe the whole stack and Flutter works out the
  transition. Much more capable, much harder to use directly

`go_router` is built on 2.0 and hides that complexity. I still use imperative
`context.push()` calls, but go_router translates them.

---

## 18. Hard questions

### Q. Isn't this just a CRUD app with videos?

No — and the distinction worth drawing is **where the logic lives**:

- The progress engine is a genuine derived-state problem: three live streams
  feeding one pure computation, with no stored aggregates to drift.
- The role split is enforced server-side in a rules language, not hidden in the UI.
- The mention system resolves at write time specifically to avoid a second
  indexed query.
- Several visuals are custom-painted geometry, not laid-out widgets.

### Q. What was the hardest part?

The honest answer is **the cache-header bug**, because it looked like a deploy
failure and was not. The site was serving correct code; browsers had been told a
year earlier never to ask again. Diagnosing it meant checking the *served* bytes
rather than trusting either the deploy output or what I saw on screen.

### Q. What did you learn?

- **Security rules are a design constraint, not an afterthought.** The
  `public_profiles` collection exists purely because rules cannot filter fields.
  That shaped the data model.
- **Pure functions are what make a Flutter app testable.** Every piece of logic I
  pulled out of a widget became trivially testable.
- **Caching is a correctness problem**, not a performance one.

### Q. If you had two more weeks?

1. Finish the `popOr()` conversion — a known correctness gap
2. Add security-rules tests with the Firebase emulator
3. Replace the placeholder lesson videos with real signed content
4. Sync unread state so it works across devices
5. Add an offline write queue

### Q. Why should someone use this over YouTube?

YouTube has the videos but none of the structure: no sequence, no check that you
actually retained anything, no sense of progress, and nobody to ask. Signals
adds the parts that turn watching into learning — and it is private, so the
embarrassment that stops most people never comes up.
