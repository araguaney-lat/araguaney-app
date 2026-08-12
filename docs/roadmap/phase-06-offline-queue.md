# Phase 06 — Offline capture queue

> The reason a native client is worth building. Only donation intake writes
> offline — a deliberate domain rule, not a pending feature — and the queue
> carries the same four invariants the web's offline capture established. The
> backend already provides everything this phase needs: idempotent intakes by
> `capture_id` and box code reservations.

---

## Objectives

1. A capture made in a basement reaches the server when someone walks out.
2. Retrying never duplicates inventory (`capture_id` generated before the first attempt).
3. A box captured offline has a code and a printable QR at capture time.
4. The queue is visible, per user, and nothing is discarded without a human decision.

## Non-objectives

- Offline sealing, pallets, or shipments: they depend on shared state and stay online-only.
- Background Sync API equivalents: synchronization happens in the foreground, as on the web; opportunistic background sync may come later without changing the design.
- Conflict resolution: captures create new rows and cannot collide.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Queue schema | Drift v2 table with `capture_id` as the primary key —SQLite prevents a double enqueue, not a check— and `user_id` on every row. The payload is frozen as JSON at enqueue time. | 🔴 High | ✅ Done |
| 2 | Code reservation lifecycle | Reserve blocks while online, spend offline. Claiming is a single `UPDATE … RETURNING`, so the same code cannot be handed out twice. Codes are never returned to the block on rejection: the physical label may already exist. | 🔴 High | ✅ Done |
| 3 | Offline enqueue path | The Phase 05 form queues when offline and also when an online attempt fails for a retryable reason. A business rejection is never queued: the server already decided. | 🔴 High | ✅ Done |
| 4 | Sync engine | Flush on the sync pass and on demand. Same `capture_id` on every retry. Stops at the first failure that is not about the capture, so no signal does not burn the whole queue. | 🔴 High | ✅ Done |
| 5 | Pending screen | Permanent counter, per-capture state, the server's reason on rejection; discard is explicit and human-only. | 🟠 Medium | ✅ Done |
| 6 | Business rejections | Stop retrying and park with the server's reason visible. `CODE_ALREADY_USED` parks too — see below. | 🟠 Medium | ✅ Done |
| 7 | Offline label | QR rendered from the reserved code at capture time, reusing the Phase 05 label screen. | 🟠 Medium | ✅ Done |
| 8 | Invariant tests | On real in-memory SQLite: idempotency across retries, per-user isolation on a shared device, a change of shift not wiping the queue, and nothing auto-discarded. | 🔴 High | ✅ Done |
| 9 | Parity test | With connectivity nothing is queued and the capture travels immediately — fixed by a test, as on the web. | 🔴 High | ✅ Done |
| 10 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## Where this design departs from the plan

Task 4 said `CODE_ALREADY_USED` should close the queue entry. It parks instead.

The backend checks idempotency by `capture_id` **before** claiming box codes, so
a retry of a registered capture never reaches the code lifecycle. That error can
therefore only mean the capture was *not* registered while its label is already
stuck on another box — a real conflict about physical inventory. Closing the
entry on its own would make it disappear exactly where nobody would notice,
which is what invariant 4 exists to prevent.

---

## Suggested order

1 → 2 (foundations; enqueueing without them is worse than not enqueueing) →
3 → 4 → 5 → 6 → 7 → 8 → 9 → 10.
