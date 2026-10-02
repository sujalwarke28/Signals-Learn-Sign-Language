# 11 · Demo script

The click-path that shows every requirement working, in an order that builds on
itself. Roughly 8 minutes at a comfortable pace, 4 if you're being brisk.

## Before you start

* [ ] Admin account exists and is promoted ([doc 4](04-admin-account.md))
* [ ] A second **learner** account exists
* [ ] Demo content loaded ([doc 5](05-seed-data.md))
* [ ] Sound on, volume at a sane level
* [ ] Have one short video file (10–20s) on hand for the upload step
* [ ] Two sessions ready if you want to show live updates: the phone signed in as
      the learner, and a browser signed in as the admin

Have the phone as the primary device. It's the target platform and the app is
designed for it.

---

## Act 1 · Admin publishes a lesson (2 min)

> "New content has to reach learners without shipping a new build. Here's that."

1. Signed in as **admin** → **Lessons** tab → **New lesson**.
2. **Choose video** → pick your short clip → **Upload**.
   * Point out that it goes to Cloudinary, not Firebase Storage — Storage now
     needs a paid plan, and a client-side unsigned upload means no API secret
     ships inside the app.
   * When it finishes, note the duration field filled itself in from the file.
3. Fill in a title, description, category, difficulty.
4. Write one quiz question: prompt, four options, tap the circle beside the
   correct one, add an explanation.
   * Optionally **Add an image** — a handshape photo, say. It uploads to
     Cloudinary as soon as you pick it, and the learner sees it above the
     options. Worth showing: a sign-language quiz that can only ask in words is
     a poor fit for the subject.
5. **Publish lesson.**
6. **Now switch to the learner device.** The new lesson is already in their
   library. Nobody reinstalled anything.

> The lesson and its questions are written in a single Firestore batch, so a
> lesson can never appear with a half-written quiz.

## Act 2 · The learner's dashboard (1 min)

Signed in as the **learner**:

1. **Home.** Greeting by name and time of day, the completion ring, the badge
   strip, the per-category bars.
2. Read out the completion number — you'll come back to it.
3. Point at the **Keep going** card: it prefers a lesson already started over the
   next unstarted one.

## Act 3 · Lesson → video → quiz unlock (2 min)

1. **Lessons** tab. Note the status pill on each card: not started / in progress /
   completed, and the best-score bar on ones already attempted.
2. Tap a lesson. **The thumbnail flies from the card into the detail header** —
   that's a Hero transition.
3. On the detail screen, show **How to finish it**: watch the video → pass the
   quiz at 70% → complete. And note **Take the quiz** is disabled, labelled
   *"Finish the video to unlock"*.
4. **Start lesson.** As the video begins, the lesson flips to *in progress* — one
   write, driven by the first frame of playback.
   * On a wide window, point out the **Agenda** rail on the right: watch → quiz →
     pass at 70%, each ticking off live as you go. On a phone it moves below the
     player rather than disappearing.
5. Let it play out (seeded clips are 12–20 seconds). At 95% the quiz unlock card
   pops in with a sound, and the watch bar turns green.
   * If a seeded lesson: mention that the clip is a marked placeholder standing in
     for real sign-language footage — the notice is on the detail screen.
6. **Next: Quiz** in the bottom right. It stays disabled until the video is
   watched, so the unlock rule holds from the button as well as the card.

## Act 4 · The quiz (2 min)

1. **Try tapping "Check answer" with nothing selected** — it's disabled, and it
   says *"Pick an answer to continue"*. That's the answer-validation requirement.
2. Pick a **correct** answer → **Check**. The option pops with a bounce, plays a
   bright cue, and the explanation slides in.
3. Next question. Pick a **wrong** one → **Check**. It shakes, plays a softer
   lower cue, and the correct answer turns green with its explanation.
   * Worth saying: the wrong-answer sound is deliberately gentle. It's a nudge,
     not a buzzer.
4. Note the progress bar across questions and the running correct-count pill.
5. Finish the last question → **See results**.

## Act 5 · Results and live progress (1 min)

1. **Confetti bursts and the celebration sound plays** (on a pass). That's a
   Lottie animation whose particles follow real projectile arcs.
2. Score ring, correct/missed/percent tiles.
3. Point at **Updated just now** — the course percentage on this card has already
   changed, because it's derived from the attempt that was written a second ago.
4. **My progress.** The Progress screen: overall ring, quizzes taken, passed,
   perfect runs, average of best attempts, day streak, per-category cards, badges,
   recent attempts.
5. **Home.** Compare the completion number to what you read out in Act 2.

> Say this plainly: none of these numbers are stored or hardcoded. Three Firestore
> streams — lessons, progress documents and quiz attempts — feed one derived
> object that recomputes whenever any of them emits. Submitting a quiz writes the
> attempt and the progress document in one transaction, both streams fire, and
> every screen watching them updates. No refresh, no polling.

## Act 6 · Community, live (1 min)

Best with two devices side by side.

1. **Community** tab on the learner. Posts, topics, reply counts.
2. Open a thread. Show the original post and its replies.
3. **New post.** Try submitting it empty — validation on both the title and the
   body. Fill it in, **Publish post**, hear the send cue.
4. **On the admin device, the new post is already in the list.** No refresh.
5. Reply to it from the admin session → it appears on the learner's thread live,
   and the reply count on the list bumps.

## Act 7 · Polish (45s)

1. **Profile & settings** → the **Theme** segmented control. Flip to dark. The
   whole palette is regenerated from one seed colour through Material 3's tonal
   system, which is why nothing clashes in either mode.
2. Toggle **Interaction sounds** off, tap around, back on.
3. Show the **Admin** badge on the admin account and its absence on the learner's.
4. **Open the web URL on a laptop.** Same app; the bottom bar becomes a side rail
   and the lesson library goes multi-column at desktop width.

## If asked: "is the role split actually enforced?"

Two layers, and say both:

* The UI hides admin screens from learners, and `/admin/add-lesson` refuses on the
  role even if reached directly.
* More importantly, `firestore.rules` permits writes to `lessons` only when the
  caller's own `users/{uid}.role` is `admin`. A learner with the raw SDK still
  gets `permission-denied`. And the rules forbid changing your own `role`, so
  admin can only be granted from the Firebase console.

Offer to sign in as the learner and show the denial.

## If asked: "where does the quiz content come from?"

Be straight about it: the questions are real ASL content — the one-handed
alphabet, the 6–9 thumb pattern, the high/low gender pattern in family signs,
initialised colour signs, non-manual markers — written from general knowledge of
the language and **not verified against an authoritative dictionary**. The
deliverable is the app; the curriculum is illustrative. Admins can author real
vetted questions through the same screen you demoed in Act 1.

---

## One-line version, if you're short on time

Admin uploads a lesson → learner's library updates instantly → watch video →
quiz unlocks → answer with bounce/shake feedback → pass → confetti → dashboard
percentage has already moved → post in the forum → it appears live on the other
device.
