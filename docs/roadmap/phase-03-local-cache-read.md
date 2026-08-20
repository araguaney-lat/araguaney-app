# Phase 03 — Local cache and read operations

> Reading must work without connectivity: catalog, stock, and the center's
> boxes live in a local Drift (SQLite) database refreshed when the application
> opens and on explicit action. This phase also establishes the connectivity
> service every later phase consumes.

---

## Objectives

1. A typed local schema for the read model: product types (with campaign visibility), boxes, sync markers.
2. Cache-first repositories: instant reads, refresh when online.
3. Read-only screens operators actually use: center stock, box list, box detail.
4. An app-wide connectivity signal.

## Non-objectives

- Any write path (Phases 05 and 06).
- National aggregation views (Phase 10).

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Drift schema v1 | Tables for product types (including campaign visibility as served by the backend), boxes, and per-resource sync markers; schema versioning and an explicit migration strategy from day one. | 🔴 High | ✅ Done |
| 2 | Cache-first repositories | Read from Drift, refresh from API on open and on explicit action; last-sync timestamp surfaced to the UI. | 🟠 Medium | ✅ Done |
| 3 | Catalog synchronization | Refresh visible product types when a read screen opens and when connectivity returns; the local catalog must remain one the server will accept. | 🟠 Medium | ✅ Done |
| 4 | Connectivity service | Online/offline state exposed as a provider; changes trigger sync hooks. | 🟠 Medium | ✅ Done |
| 5 | Center stock screen | Category totals for the operator's center. Buildable today from `GET /v1/reports/campaign/{id}/by-category`, which is already scoped to the caller's center — **what that endpoint counts is capture, not stock**; see below. | 🟠 Medium | ⬜ Pending |
| 6 | Box list and detail | The center's boxes with status; detail mirrors the web record. | 🟠 Medium | ✅ Done |
| 7 | Offline/empty states | Spanish copy that says what is stale and why an action needs connectivity. | 🟢 Low | ✅ Done |
| 8 | Tests on real SQLite | Repository and transaction behavior against in-memory Drift, never mocks. | 🔴 High | ✅ Done |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## Task 5 is blocked on the backend

**Corrected on 2026-08-20, after reading the backend rather than the snapshot.**
This was recorded as blocked on a missing endpoint. It is not.

`GET /v1/reports/campaign/{campaign_id}/by-category` exists, requires only an
authenticated user with access to that campaign, and scopes itself to the
caller's center through `tenant_scope` — national administration sees every
center, everybody else sees their own, with nothing to pass and nothing the
client can widen. It returns `{category, box_count, unit_count}`, and the
generated client already carries it.

What it does **not** answer is stock. It counts boxes created inside a date
range for one campaign, whatever their status: a box sealed, palletised and
already shipped still counts. So it reads as *what this center captured*, not
*what this center holds*.

That leaves two honest options, and the difference is a product decision rather
than a technical one: build the screen now and title it for what the number
means, or ask the backend for a status-filtered reading and title it stock. The
first ships this week; the second is request 1 in
[`docs/backend-requests.md`](../backend-requests.md), now rewritten to ask for
the part that is actually missing.

---

## Suggested order

1 → 2 → 4 (foundation) → 3 → 5 → 6 → 7 → 8 → 9.
