# 16 · Community: channels, mentions and unread

The community screen is laid out like a chat client rather than a forum index:
channels down the side, messages beside them, a composer at the foot. This file
covers the three features that make that work, and the constraints that shaped
each of them.

---

## 16.1 Channels

Channels come from `AppConstants.forumTopics` — there is no channel collection,
because the set is fixed and small. `Channel.slugFor()` turns a topic into the
displayed name: `Practice Tips` → `#practice-tips`.

A post belongs to **one or more** channels. `ForumPost.topics` is a list, and the
composer's chips are multi-select. Deselecting the last one is blocked: a post
with no channel would have nowhere to appear.

### Backward compatibility

Posts written before channels existed have a single `topic` string and no
`topics` array. Both sides of the change are handled:

* **Reading** — `ForumPost._topicsFrom()` prefers `topics`, falls back to
  `topic`, and defaults to `General` if neither is present. An untagged post
  lands in a channel rather than disappearing.
* **Writing** — `createPost()` writes `topics` *and* sets `topic` to the first
  entry, so an older build of the app can still read new posts.

You can delete the `topic` write once you are sure no old client is in use.
Nothing in the current code reads it.

### The rail

`ChannelRail` is persistent at 840px and wider, and becomes a `Drawer` below
that — a fixed rail on a phone would eat a third of the screen. The breakpoint
is `ForumListScreen.railBreakpoint`.

Two entries above the channel list are not channels:

| Entry | What it shows |
| --- | --- |
| **All messages** | Every post, newest first |
| **Mentions** | Only posts naming you |

Neither is writable, so a message typed while either is selected goes to
`#general` (`targetChannel()`).

## 16.2 Mentions

### Why there is a `public_profiles` collection

The obvious implementation — read the user list and offer it after an `@` — is
not available. `users/{uid}` carries an email address and a role, so the rules
restrict reads to the owner and admins, and **Firestore rules cannot restrict a
read to particular fields**. Exposing the collection to make the picker work
would expose every learner's email to every other learner.

So there is a second collection holding one field:

```
public_profiles/{uid}
  displayName, updatedAt
```

Readable by any signed-in learner, writable only by its owner, and the uid is
the document id — so a display name cannot be published under somebody else's
account. `users/{uid}` stays private.

### Backfill

`AuthRepository.ensureProfile()` runs on every sign-in, and upserts the public
profile **outside** its `if (snap.exists) return` guard. Accounts created before
the directory existed therefore publish themselves the next time their owner
opens the app — there is no migration script to run.

The write is best-effort and swallows its errors. A learner who cannot be
mentioned yet is a much smaller problem than one who cannot sign in, which is
what an uncaught permission error on this path would cause on a project whose
rules had not been redeployed.

### Who the picker offers

`mergePeople()` unions two sources:

| Source | Why |
| --- | --- |
| The directory | The real answer: everyone with an account, posted or not |
| Post and reply authors | Fallback for anyone not backfilled yet, and a graceful degrade if the directory cannot be read at all |

The directory wins on name, because a post carries whatever name its author had
when they wrote it. The reader is always excluded, and the list is sorted by
name so it does not reshuffle between opens.

### Handles

A handle is the first name, lowercased, with punctuation stripped —
`Ada Lovelace` is `@ada`. The whole name compacted (`@adalovelace`) also
resolves, which is the escape hatch when two people share a first name. If a
handle genuinely matches two people, the mention resolves to **both**: notifying
one of them at random would be worse.

### Resolution and storage

Mentions are resolved **when the message is written**, not when it is read, and
the resulting uids are stored on the document:

```
forum_posts/{postId}
  mentionedUids: [uid, …]
```

This is denormalised on purpose. The client already streams every post, so the
Mentions view is a filter over data that is in memory — no second query, and no
composite index to deploy. `postsMentioning()` is the whole implementation.

Rendering is separate: `mentionSpans()` marks up `@handles` that belong to a
real participant and leaves unknown ones as plain text, because highlighting
`@nobody` would promise a notification that was never sent. An `@` that does not
start a word is ignored, so `ada@example.com` is not a mention.

### Known limit

A mention inside a **reply** highlights correctly within its thread, but does
not appear in the global Mentions view. Surfacing those would need a
`collectionGroup` query over `replies`, which requires both a rules addition and
a composite index.

## 16.3 Unread badges

Per-channel counts in the rail, held in `shared_preferences` as a timestamp per
channel (`forum.channelReads`). `unreadIn()` counts posts in a channel newer
than that timestamp.

Two rules worth knowing:

* **Your own posts never count.** Opening a channel to be told you have one
  unread message that you wrote yourself is noise.
* **A channel never opened counts everything**, so a new learner sees what is
  waiting rather than a silent rail.

### Why it is local

Syncing read state would mean a `users/{uid}/channel_reads` subcollection, and
the rules grant only `progress` and `attempts` under a user document — so a
server-side version would be unreadable and unwritable until new rules were
deployed. Local works immediately with nothing to deploy.

The tradeoff: read state is **per device**. The phone and the browser keep
separate counts, and reinstalling clears them. If you want it synced, add the
subcollection to `firestore.rules` with `allow read, write: if isSelf(uid)` and
move `ChannelReads` onto a repository.

## 16.4 The composer

`ChannelComposer` sits at the foot of the channel and posts straight into
whichever one is open. `@` autocomplete works inside it.

### Where the title comes from

A post document needs a title, and the rules enforce one between 1 and 120
characters — but a chat bar is a single box and nobody in a chat wants to fill
in a title field. `titleFromMessage()` derives one: the first line, or the first
sentence if it is long enough to be useful, truncated on a word boundary.

`"Hi. I am new here"` stays whole rather than becoming the useless title
`"Hi."`, and whitespace-only input still returns something non-empty, so the
write can never be rejected for an empty title.

The full message is always kept as the body. The derived title is only what the
thread view and the admin console display.

The `+` button to the left of the bar opens the longer composer, which is where
you go for a post that wants its own title or several channels at once.

## 16.5 Testing

All of the logic above is pure and lives outside the widgets:

| File | Covers |
| --- | --- |
| `lib/screens/forum/mentions.dart` | Handles, parsing, resolution, spans, merging |
| `lib/screens/forum/channels.dart` | Slugs, membership, unread, title derivation |

`test/forum_mentions_test.dart` pins the edge cases that matter — the email
address that is not a mention, the shared first name, the early full stop,
the 120-character cap, your own posts not counting as unread.
