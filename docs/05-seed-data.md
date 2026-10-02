# 5 · Loading the demo content

A fresh Firebase project has no lessons, so the app's library is empty. The
seeder fills it with ten ASL lessons (four quiz questions each) and four forum
threads with replies.

It runs **from inside the app**, as the signed-in admin. That means no service
account key, no Node script, and no extra credentials — and because it goes
through the same security rules as any other write, a successful seed also proves
your rules and your admin role are set up correctly.

Prerequisites: [doc 4](04-admin-account.md) — you need an admin account.

---

## 5.1 Run the seeder

1. Sign in as your **admin** account.
2. Tap your avatar (top-right of the dashboard) → **Profile & settings**.
3. Scroll to the **Admin** section → **Demo content**.
4. A sheet opens with two checkboxes, both ticked:
   * **Lessons and quiz questions** — 10 lessons across 6 categories
   * **Forum threads** — 4 posts with replies
5. Tap **Load demo content**.

It takes a few seconds. On success you'll see
`Loaded 10 lessons, 40 questions, 4 posts, 7 replies.`

Go to the **Lessons** tab and the library is populated.

## 5.2 What gets created

```
lessons/{id}                         x10
lessons/{id}/questions/{id}          x4 each
forum_posts/{id}                     x4
forum_posts/{id}/replies/{id}        1–2 each
```

The ten lessons:

| Category | Lessons |
| --- | --- |
| Alphabet | The ASL Alphabet: A to F · G to N · Letters That Move: J and Z |
| Numbers | Numbers 1 to 10 · Counting Past Ten |
| Greetings | Hello and Goodbye · What's Your Name? |
| Common Phrases | Please, Thank You, Sorry |
| Family | Family Signs |
| Colors | Colors |

## 5.3 About the quiz content — read this before you demo

The questions are **American Sign Language** (ASL), written from general
knowledge of the language: handshapes, the one-handed alphabet, the 6–9 thumb
pattern, the high/low gender pattern in family signs, initialised colour signs,
and the role of non-manual markers.

They have **not been verified against an authoritative ASL dictionary**. If you
are asked in your demo, say that plainly — the questions are real sign-language
content rather than filler, but the app is the deliverable and the curriculum is
illustrative. If you want them checked, ASLU (lifeprint.com) and Handspeak are
the usual references.

The app uses ASL, not BSL. Several questions deliberately contrast the two
(ASL fingerspells one-handed, BSL two-handed).

## 5.4 About the videos — read this too

**The seeded lesson videos are placeholder clips, not sign-language footage.**
They are short public sample videos from Cloudinary's `demo` cloud (a dog, a sea
turtle, some horses), 12–20 seconds each.

They are there so the video player, the watch-progress bar, the "video watched"
flag and the quiz unlock can all be demonstrated end to end without needing real
footage. Every seeded lesson is flagged `isPlaceholderVideo: true`, and the
lesson detail screen shows a notice saying so — so the app never pretends a dog
video is a sign-language lesson.

Short clips were chosen on purpose: you have to watch 95% of a video to unlock
its quiz, and 15 seconds makes for a much better live demo than 15 minutes.

### Replacing them with real footage

Two options:

* **Publish over them.** Use **Admin → Add a lesson** to upload a real clip with
  real questions. New lessons appear alongside the seeded ones, and yours won't
  carry the placeholder notice. This is also the better thing to demo.
* **Start clean.** In the Demo content sheet, tap **Clear all lessons and posts**,
  then add your own lessons only.

If you have real sign-language clips you want seeded in bulk, the URLs live at
the top of [`lib/data/seed_data.dart`](../lib/data/seed_data.dart) — swap the five
constants and set `isPlaceholderVideo: false`.

## 5.5 Resetting between demos

The same sheet has **Clear all lessons and posts**, which deletes every lesson,
question, post and reply.

It does **not** delete learner progress, because an admin has no rule permission
to write another user's `users/{uid}/progress` or `attempts` documents. So after
clearing, old quiz attempts may reference lessons that no longer exist. To reset
a learner completely, delete that user's document subtree in the Firestore
console, or just create a fresh learner account — which is faster.

**Running the seeder twice creates a second copy of everything.** It does not
check for duplicates.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| No **Demo content** option | You're signed in as a learner — see [doc 4](04-admin-account.md) |
| `Firestore refused the write` | Rules not deployed, or role isn't exactly `admin` |
| Seeding stalls partway | Network drop. Clear content and run it again |
| Lessons appear but have no quiz | A partial write, which shouldn't happen (lesson + questions go in one batch). Clear and re-seed |
| Videos won't play | See [doc 13](13-troubleshooting.md) — usually a network or codec issue, not a config one |
| I see 20 lessons | You ran the seeder twice. Clear content, seed once |
