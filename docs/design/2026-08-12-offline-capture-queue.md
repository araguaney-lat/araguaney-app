# Offline capture queue (Phase 06)

> Design accepted on 2026-08-12. Covers the queue schema, the reserved-code
> lifecycle, the enqueue path, the flush engine, and the pending screen. Scope
> matches [`docs/roadmap/phase-06-offline-queue.md`](../roadmap/phase-06-offline-queue.md).

## Problem

This is the reason a native client is worth building. A capture made in a
basement has to reach the server when someone walks out, and it has to reach it
**once**.

Only donation intake writes offline. That is a domain rule, not a pending
feature: sealing, palletising and closing shipments depend on shared state that
another device may be changing right now, and deciding blind would produce two
truths about the same box.

## What the backend already provides

- **`POST /v1/intakes` is idempotent on `capture_id`**, and the check runs
  *before* box codes are claimed. A retry of a registered capture returns what
  was registered; it never reaches the code lifecycle.
- **Box code reservations**: `POST /v1/boxes/codes/reserve` hands out a block
  while online, and creating an intake claims each code exactly once, with
  `CODE_NOT_RESERVED` and `CODE_ALREADY_USED` as distinct answers.

## The four invariants, and where each one lives

### 1. The key is generated before the first attempt and never changes

`capture_id` is created when the capture form opens (Phase 05) and is the
**primary key** of the queue table. Enqueueing the same capture twice is not
prevented by a check someone could forget — it is prevented by SQLite. The
stored payload is the serialized request, frozen at enqueue: what leaves the
basement is exactly what was captured, even if the catalog changed meanwhile.

### 2. The offline catalog is the one the server will accept

Already established in Phase 03: the local catalog is a replacement copy of
`GET /v1/product-types`, campaign visibility included. Phase 06 adds nothing —
the product picker reads that cache, so anything selectable offline is
something the server served.

### 3. The queue belongs to whoever captured

Every row carries `user_id`, and no query in `CaptureQueueDao` runs without it.
The flush takes the user id as an argument; there is no "flush everything".

The other half of this invariant is an **omission**: `clearReadModel()`, which
runs when a different person logs in, does not touch the queue or the reserved
codes. What someone captured in a basement is theirs and stays pending even if
a colleague opens the app on the same phone. Deleting it there would lose
inventory through the act of changing shift; what keeps it from being sent under
the wrong session is the `user_id` on each row, not deletion.

### 4. Nothing is discarded on its own

Two paths remove a row: an accepted submission, and an explicit discard by a
person looking at the reason. A business rejection stops being retried — the
same request would get the same answer forever — and parks with the server's
wording visible.

**`CODE_ALREADY_USED` parks rather than closing.** The roadmap said "close the
entry", and this design deliberately departs from it. Because idempotency is
checked before codes are claimed, that error means the capture was **not**
registered while its label is already stuck on another box. Closing it silently
would lose inventory exactly where nobody would notice.

## Design

### Schema — Drift v2

| Table | Purpose |
|---|---|
| `queued_captures` | `capture_id` (pk), `user_id`, `payload` (JSON), `summary`, `box_count`, `status`, `attempts`, `last_failure_code`, `last_failure_message`, `created_at`, `last_attempt_at` |
| `box_code_reservations` | `code` (pk), `user_id`, `reserved_at`, `spent_at` |

`MigrationStrategy.onUpgrade` creates both when moving from v1. They are created
empty, which is correct: a device upgrading had no queued captures because there
was nowhere to queue them.

### Claiming a code is one statement

`UPDATE … WHERE code IN (SELECT … LIMIT ?) RETURNING code`. Reading the free
codes and then marking them leaves a gap in the middle, and the prize for
winning that race is two boxes wearing the same label — two parcels the manifest
declares as one. `RETURNING` closes the gap: what comes back is exactly what was
marked.

Running out returns fewer codes rather than failing. Being unable to label is
bad; losing the capture is far worse.

### Enqueue

The Phase 05 form submits to the queue when the device is offline, and also when
an online attempt fails for a retryable reason — a dropped network mid-send must
not cost the capture. Boxes without a code take one from the reserved block
first, so they can be labelled at the moment they are closed.

A business rejection received while online is **not** queued: the server already
decided, and queueing it would mean retrying a settled answer forever.

### Flush

Runs on the sync coordinator's pass (app open, connectivity regained) and on
demand from the pending screen. It walks one person's captures oldest-first and
stops at the first failure that is not about the capture:

- Accepted → the row leaves the queue.
- `BusinessRuleFailure`, `Forbidden`, `NotFound` → parked with the reason.
- Anything else (no signal, expired session, server down) → stays pending and
  the pass stops. A 401 says nothing bad about the capture; parking one for a
  credentials problem would lose inventory over a session.

### Pending screen

A permanent counter on the home screen — not a dismissible notice, because a
capture waiting for signal has to keep being visible until it leaves. Each entry
shows what it holds, how many attempts it has made, and, when parked, the
server's reason. Discard asks for confirmation and is the only human-driven
deletion.

The screen also shows how many reserved codes are left and offers to top up,
which can only be done with signal — someone walking into a basement with an
empty block will have no labels until they come back up.

## A note on the tests

The invariants are tested against real in-memory SQLite, never doubles. The
widget tests for the offline form use fakes for the queue and the code block
instead — not by preference but by constraint: in `testWidgets` the clock is
fake, and a real SQLite write triggered from inside the widget tree never
completes. What the database does is covered where a real database can run; what
the screen does is covered where the screen runs.

Parity is fixed by a test, as on the web: with connectivity, nothing is queued
and the capture travels immediately.
