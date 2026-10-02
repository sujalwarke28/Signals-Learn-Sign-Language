# 4 · Creating the admin account

Signals has one login flow and two roles. The role lives in a single Firestore
field, `users/{uid}.role`, which is either `"learner"` or `"admin"`.

There is deliberately **no way to become an admin from inside the app**. The
security rules reject any update that changes your own `role`, so promotion
happens in the Firebase console only. That's what makes the role split real
rather than cosmetic.

Prerequisites: [doc 1](01-firebase-setup.md) finished, and the rules deployed.

---

## 4.1 Create the account through the app

1. Run the app — `flutter run -d chrome` is the quickest way.
2. Signed out, you land on the welcome page — tap **Learn your first sign**,
   or **Sign in** and then **Create an account**.
3. Fill in:
   * **Your name** — this is what shows on your forum posts
   * **Email** — e.g. `admin@signals.app` (it doesn't need to be a real inbox
     unless you want password resets to work)
   * **Password** — at least 6 characters
4. Tap **Create account**. You land on the dashboard as a learner.

Behind the scenes this did two things: created the Firebase Auth user, and wrote
`users/{uid}` with `role: "learner"`. Both are needed — an Auth user without the
Firestore document has no role.

## 4.2 Promote it to admin

1. Open the [Firebase console](https://console.firebase.google.com) → your
   project → **Firestore Database** → **Data**.
2. Open the **`users`** collection. You'll see one document, named with a long
   random ID (that's the Auth UID).
3. Click it. You should see fields including:

   ```
   createdAt    : (timestamp)
   displayName  : "Your Name"
   email        : "admin@signals.app"
   role         : "learner"
   soundEnabled : true
   ```

4. Click the pencil icon next to **`role`**.
5. Change the value from `learner` to `admin`. Keep it lowercase — the rules
   compare the string exactly.
6. Click **Update**.

## 4.3 Confirm it worked

You don't need to restart the app. The profile document is streamed, so the
change lands within a second or two:

* the avatar menu (top-right of the dashboard) → **Profile & settings** now shows
  an **Admin** badge instead of **Learner**
* an **Admin tools** card appears at the bottom of the dashboard
* the Lessons tab grows a **New lesson** floating button
* **Profile & settings** gains an **Admin** section with *Add a lesson* and
  *Demo content*

If none of that appears, see the table below.

## 4.4 Creating a second, learner account

For a convincing demo it's worth having both. Sign out (Profile & settings →
Sign out) and create a second account — leave its role as `learner`. Then you
can show:

* the learner seeing a lesson the admin published moments earlier
* the learner having no admin UI at all
* the learner's forum reply appearing live in the admin's session

Two browser windows (one normal, one incognito) lets you show both at once.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| No admin UI after editing the role | Check for a typo — it must be exactly `admin`, lowercase, no spaces |
| Two documents in `users` | You created two accounts; check you edited the right UID (match it against the email field) |
| `users` collection missing entirely | Sign-up failed partway. Delete the user under **Authentication → Users** and sign up again |
| Admin UI shows but publishing fails with `permission-denied` | Rules aren't deployed — see [doc 9](09-firestore-rules.md) |
| Want to demote back to learner | Same steps, set `role` back to `learner` |
