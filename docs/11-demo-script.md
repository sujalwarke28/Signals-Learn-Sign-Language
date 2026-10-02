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

## Act 0 · The landing page (45s)

Open the web URL **signed out**, in a private window.

1. A visitor meets the pitch, not a password field. The motto — *Say hello with
   your hands* — with the object of the sentence cycling: hello, thank you,
   good morning, I love you.
2. The motion behind it is the **signing space**: in sign language, meaning
   lives in movement through the box in front of your torso. It is drawn with
   `CustomPaint`, not an illustration, which is why it costs nothing to ship.
3. Scroll. The argument is deliberately ordered: *you have someone in mind* →
   *the hard part is the embarrassment, not the hands* → how it works → what is
   inside → you are not alone → **a language, not a workaround**.
4. Land on that last panel if anyone asks about the Deaf community. It says
   plainly that this is somewhere to begin, not somewhere to stop, and points
   people at Deaf teachers.

> Signed-out visitors land here, not on `/login`. Three routes are public:
> `/welcome`, `/login`, `/signup`.

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

Sign in as the **admin** first, and point out that `/home` is a *console*: a
publish action, library metrics, coverage sorted thinnest-first, and a queue of
"things a learner would notice before you do" — lessons still on stand-in
footage, questions with no reply. No streak, no badges. An admin never takes the
lessons.

Now the **learner** on the same route:

1. **Home.** The canopy: greeting by name, a count that climbs to its value, and
   the streak phrased so it never scolds — at zero it says *a good day to start
   again*.
2. Read out the completion number — you'll come back to it.
3. The **Up next** card is the one obvious action. It prefers a lesson already
   started over the next unstarted one.
4. Scroll to **Your path**: the library as a route you walk. The lit section of
   the curve *is* the completion fraction, so the picture cannot disagree with
   the number.

> Same route, same role field the security rules enforce on. The UI cannot
> disagree with what the backend will allow.

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

1. **Community** tab. It is laid out like a chat client — channels down the
   side on a laptop, behind the `#` button on a phone. `#general`,
   `#question`, `#practice-tips`, and so on.
2. Messages are a transcript, not a stack of cards: consecutive messages from
   the same person inside a few minutes tuck under the first.
3. Type in the bar at the foot and send. It lands in whichever channel is open —
   the hint names it. **On the other device it appears instantly.** No refresh.
4. Type `@` and pick the other account. Send it.
5. **On that device, the message is highlighted and the Mentions entry in the
   rail carries a count.** Mentions resolve when the message is written and are
   stored on the document, so the view is a filter over data already in memory —
   no extra query.
6. Point at the unread badges. Your own messages never count toward them.

## Act 7 · Polish (45s)

1. **Profile & settings** → the **Theme** segmented control. Flip to dark. The
   whole palette is regenerated from one seed colour through Material 3's tonal
   system, which is why nothing clashes in either mode.
2. Toggle **Interaction sounds** off, tap around, back on.
3. Show the **Admin** badge on the admin account and its absence on the learner's.
4. **Open the web URL on a laptop.** Same app; the bottom bar becomes a side
   rail, the lesson library goes multi-column, and the community's channel rail
   becomes persistent instead of a drawer.
5. If anyone asks about accessibility: turn on *Reduce Motion* in the OS. Every
   animation in the app checks for it and renders a sensible still frame — the
   trail at rest, the number stated plainly, no confetti.

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
