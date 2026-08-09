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
| 1 | Queue schema | Drift table keyed by user; `capture_id` generated at enqueue time and immutable across retries. | 🔴 High | ⬜ Pending |
| 2 | Code reservation lifecycle | Reserve blocks while online (`POST /v1/boxes/codes/reserve`), spend offline, never return codes on rejection (the physical label may exist). | 🔴 High | ⬜ Pending |
| 3 | Offline enqueue path | The Phase 05 intake form submits to the queue when offline; identical payload semantics. | 🔴 High | ⬜ Pending |
| 4 | Sync engine | Flush on app open, on connectivity regained, on foreground; same `capture_id` on every retry; `CODE_ALREADY_USED` and idempotent 200 close the entry. | 🔴 High | ⬜ Pending |
| 5 | Pending screen | Permanent counter, per-capture state, the server's reason on rejection; discard is explicit and human-only. | 🟠 Medium | ⬜ Pending |
| 6 | Business rejections | Stop retrying (same answer awaits), park for review with the reason visible. | 🟠 Medium | ⬜ Pending |
| 7 | Offline label | QR rendered from the reserved code at capture time. | 🟠 Medium | ⬜ Pending |
| 8 | Invariant tests | On real in-memory SQLite: idempotency across retries, per-user isolation on a shared device, campaign visibility of the offline catalog, nothing auto-discarded. | 🔴 High | ⬜ Pending |
| 9 | Parity test | With permanent connectivity the application behaves exactly as in Phase 05 — fixed by a test, as on the web. | 🔴 High | ⬜ Pending |
| 10 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 (foundations; enqueueing without them is worse than not enqueueing) →
3 → 4 → 5 → 6 → 7 → 8 → 9 → 10.
