# Phase 03 — Local cache and read operations

> Reading must work without connectivity: catalog, stock, and the center's
> boxes live in a local Drift (SQLite) database refreshed when the application
> opens and on explicit action. This phase also establishes the connectivity
> service every later phase consumes.

---

## Objectives

1. A typed local schema for the read model: product types (with campaign visibility), boxes, stock.
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
| 1 | Drift schema v1 | Tables for product types (including campaign visibility as served by the backend), boxes, and stock summaries; schema versioning from day one. | 🔴 High | ⬜ Pending |
| 2 | Cache-first repositories | Read from Drift, refresh from API on open and on explicit action; last-sync timestamp surfaced to the UI. | 🟠 Medium | ⬜ Pending |
| 3 | Catalog synchronization | Refresh visible product types on login and when connectivity returns; the local catalog must remain one the server will accept. | 🟠 Medium | ⬜ Pending |
| 4 | Connectivity service | Online/offline state exposed as a provider; changes trigger sync hooks. | 🟠 Medium | ⬜ Pending |
| 5 | Center stock screen | Read-only stock by category for the operator's center. | 🟠 Medium | ⬜ Pending |
| 6 | Box list and detail | The center's boxes with status; detail mirrors the web record. | 🟠 Medium | ⬜ Pending |
| 7 | Offline/empty states | Spanish copy that says what is stale and why an action needs connectivity. | 🟢 Low | ⬜ Pending |
| 8 | Tests on real SQLite | Repository and transaction behavior against in-memory Drift, never mocks. | 🔴 High | ⬜ Pending |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 4 (foundation) → 3 → 5 → 6 → 7 → 8 → 9.
