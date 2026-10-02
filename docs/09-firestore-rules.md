# 9 · Firestore security rules

The rules are in [`firestore.rules`](../firestore.rules) at the project root.
They are the actual enforcement of the learner/admin split — the app hiding admin
buttons from learners is only cosmetic, and anyone with the client SDK could
bypass the UI entirely.

---

## 9.1 Deploying them

```bash
cd ~/Desktop/Signals
firebase login                 # once
firebase use YOUR_PROJECT_ID   # or `firebase use --add` the first time
firebase deploy --only firestore:rules,firestore:indexes
```

Confirm in the console: **Firestore Database → Rules**. The published text should
match the file and the timestamp should be just now.

**Nothing in the app works until this is done.** A production-mode database denies
every read until rules are published, so the symptom is
`PERMISSION_DENIED: Missing or insufficient permissions` on the very first screen.

## 9.2 What the rules enforce

### Lessons and quiz questions

```
lessons/{lessonId}                      read: any signed-in user
                                        write: admin only
lessons/{lessonId}/questions/{id}       read: any signed-in user
                                        write: admin only
```

Admin is determined by reading the caller's own profile document:

```
get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
```

That costs one extra document read per admin write, which is irrelevant at this
scale, and it keeps the role in Firestore where the console can edit it. The
alternative — a custom auth claim — would need a Cloud Function to set, and
Cloud Functions want the Blaze plan.

Correct answers are readable by learners. That's deliberate: this is a practice
app, not an invigilated exam, and the app shows the right answer and its
explanation immediately after you check. Hiding them would need a Cloud Function
to do the marking.

### User profiles

```
users/{uid}          read:   that user, or an admin
                     create: that user, and role MUST be 'learner'
                     update: that user, and role MUST NOT change
                     delete: nobody
```

Those two role clauses are the whole security model for admin:

* you cannot sign up directly into an admin account
* you cannot promote yourself afterwards

so `admin` can only be granted from the Firebase console, by someone who already
has console access. See [doc 4](04-admin-account.md).

### Progress and quiz attempts

```
users/{uid}/progress/{lessonId}   read, write: that user only
users/{uid}/attempts/{id}         read:   that user only
                                  create: that user, with 0 <= score <= total
                                  update: nobody
                                  delete: nobody
```

Attempts are an **append-only log**. Once written, a score cannot be edited or
deleted by anyone through the client. Since every number on the Progress screen
is derived from these documents, that's what makes the stats trustworthy rather
than decorative. The `score <= total` check stops a hand-crafted request claiming
12/10.

### Forum

```
forum_posts/{id}          read:   any signed-in user
                          create: author must be the caller; title and body
                                  non-empty and length-capped; replyCount must
                                  start at 0
                          update: the author, an admin, or anyone changing
                                  ONLY replyCount
                          delete: the author or an admin

forum_posts/{id}/replies/{id}
                          read:   any signed-in user
                          create: author must be the caller, body non-empty
                          update: the author
                          delete: the author or an admin
```

The `replyCount`-only exception exists because replying has to increment the
parent's counter, and the replier usually isn't the post's author. The
`affectedKeys().hasOnly(['replyCount'])` clause means that permission cannot be
used to edit anyone's words.

## 9.3 Testing the rules

### By hand, in the console

**Firestore Database → Rules → Rules Playground.** Useful checks:

| Simulated | Expect |
| --- | --- |
| `get` on `/lessons/abc`, authenticated | Allow |
| `get` on `/lessons/abc`, unauthenticated | Deny |
| `create` on `/lessons/xyz` as a learner UID | Deny |
| `create` on `/lessons/xyz` as an admin UID | Allow |
| `update` on `/users/{learnerUid}` setting `role: "admin"`, as that user | Deny |
| `get` on `/users/{otherUid}` as a learner | Deny |
| `update` on `/users/{uid}/attempts/{id}` as that user | Deny |

### In the app

The quickest end-to-end check: sign in as a learner and try to reach
`/admin/add-lesson`. The screen refuses on the role, and even if you forced past
it, the publish would come back `permission-denied`. Both layers are doing their
job.

## 9.4 Indexes

[`firestore.indexes.json`](../firestore.indexes.json) declares one composite
index, on `attempts` by `lessonId` + `createdAt`.

Most of the app's sorting is done client-side on purpose — lessons sort by
`order` then `title` in Dart, and the forum sorts by `createdAt` in Dart. That
avoids needing an index for every list, and it lets a brand-new document (whose
`serverTimestamp` hasn't resolved yet) show up immediately in its local snapshot
instead of being filtered out by a server-side `orderBy`.

If you ever add a query Firestore can't serve, the error in the console contains
a direct link that creates the index for you.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Missing or insufficient permissions` on every screen | Rules never deployed (9.1) |
| Admin can read but not write lessons | `users/{uid}.role` isn't exactly `admin` |
| `permission-denied` writing an attempt | Check `score <= total`; the rule rejects impossible scores |
| Replies fail with `permission-denied` | Both writes in the batch must pass — check the reply's `authorId` is the caller |
| `Error: Failed to load firestore.rules` | Run `firebase deploy` from the project root, where the file is |
| Rules deployed but app still denied | Sign out and back in; a stale token can lag a role change |
