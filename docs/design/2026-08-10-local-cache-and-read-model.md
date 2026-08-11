# Local cache and read model (Phase 03)

> Design accepted on 2026-08-10. Covers the local Drift database, the
> cache-first repositories, the connectivity signal, and the read-only screens
> that consume them. Scope matches
> [`docs/roadmap/phase-03-local-cache-read.md`](../roadmap/phase-03-local-cache-read.md).

## Problem

Reading has to work in a basement with no signal. Today every screen would
have to call the backend to show anything, so an operator standing in front of
a pallet with no bars sees nothing at all. Phase 03 puts a typed local mirror
of the read model on the device, refreshes it when the network allows, and
tells the operator how old what they are looking at is.

## What this phase does not do

- No write path. Sealing, palletising and intake belong to Phases 05 and 06.
- No client-side business rules. The device stores what the server served and
  never re-derives eligibility, status meaning, or aggregates from it.
- No national aggregation views (Phase 10).

## Contract reality: the center stock screen has no endpoint

Roadmap task 5 asks for stock by category for the operator's center. The `/v1`
contract has no endpoint for it. `CategoryStockOut` and `CenterStockOut` exist
only inside `NationalDashboardOut` (national aggregate) and the public campaign
schemas. `GET /v1/dashboard/weight` is session-scoped but answers a different
question (kilograms per campaign, not units per category).

The client could sum `quantity` over cached boxes grouped by category, but that
requires deciding which box statuses count as stock — a domain rule that lives
in the backend and would silently fork the moment the backend changed it.

**Decision:** task 5 is deferred and marked as blocked on a new backend
endpoint (a session-scoped `GET` returning category totals for the caller's
center). Phase 03 ships the other eight tasks.

## Design

### 1. User identity, because the token does not carry it

`Token` exposes `center_id` and `center_role` but no user id, and `Session`
inherits that gap. Scoping the cache per user needs one.

- `TokenStorage` gains `readUserId` / `writeUserId`, stored next to the refresh
  token in the platform keystore.
- `AuthRepository.me(accessToken)` calls `GET /v1/auth/me` over the
  **session-less** Dio with an explicit `Authorization` header. It deliberately
  does not go through the authenticated client: identity has to be resolved
  *before* a session is exposed to the rest of the application, and the
  authenticated client reads its token from the session that does not exist yet.
- `Session` gains `userId`.

Identity is resolved only where it can actually change: `logIn` and
`submitTotpCode`. `restore` and `renew` reuse the stored id — a refresh token
cannot become a different person.

**Cache reset rule:** on those two paths, the read model is cleared unless the
resolved id equals the stored one. Two consequences worth stating:

- A fresh install has no stored id, so the first login clears an empty database.
  Harmless, and it also covers a device upgraded from a build that predates the
  stored id.
- If `GET /v1/auth/me` fails, the client clears anyway and leaves `userId` null.
  Failing closed is the only safe direction: the alternative is showing one
  volunteer's center data to whoever logs in next on a shared phone.

The reset itself is injected as `readModelResetProvider`
(`Future<void> Function()`), so `core/auth` never imports the database.

### 2. Drift schema v1 — `lib/core/db/`

`schemaVersion = 1` with an explicit `MigrationStrategy` from the first commit,
because the second version is the one that breaks devices, not the first.

| Table | Columns |
|---|---|
| `product_types` | `id` (text, pk), `display_name`, `category`, `brand`, `form`, `strength`, `default_unit`, `gtin`, `inn_name`, `is_controlled`, `min_shelf_life_days`, `unit_weight_kg`, `unspsc_code`, `campaign_id`, `created_at` |
| `boxes` | `id` (text, pk), `code`, `center_id`, `product_type_id`, `quantity`, `unit`, `status`, `batch`, `expiry_date`, `weight_kg`, `sealed_at`, `pallet_id`, `intake_id`, `reject_reason`, `created_at` |
| `sync_markers` | `resource` (text, pk), `last_synced_at`, `last_failure_code` |

`campaign_id` is stored exactly as served. The local catalog is a copy of the
server's answer to "what may this operator see", never a local recomputation of
it — invariant 2 of the offline frontier in `CLAUDE.md`.

`clearReadModel()` empties all three tables in one transaction.

### 3. Cache-first repositories

Both follow the same shape: a Drift stream for reading, an explicit `refresh()`
for writing, and a `SyncOutcome` (`SyncSucceeded` / `SyncFailed`) as the return
value. **A refresh never throws at the UI.** Stale data with an honest label
beats an error screen over a full cache.

- **`CatalogRepository`** — `watchProductTypes({category})`;
  `refresh()` calls `GET /v1/product-types` and **replaces the whole set inside
  one transaction**. Replacement rather than upsert is the point: a product type
  the server stopped serving has to disappear locally, or the device would offer
  something the server will reject.
- **`BoxesRepository`** — `watchBoxes()` joined with the cached product name;
  `refresh()` pages `GET /v1/boxes` at `limit=200` and stops at the first short
  page or at a cap of 500 rows, whichever comes first. `watchBox(id)` reads the
  cache; `refreshBox(id)` fetches one box when online.

**On the window.** The design conversation framed it as "open boxes plus the
most recent N". The implementation drops the status filter and keeps only the
cap: choosing which statuses are worth mirroring is a domain judgement, and
encoding a list of status strings in the client is exactly the duplication this
repository avoids. The window is therefore "the first 500 rows the server
returns for this session, in the server's order". A box outside it opens on
demand when there is signal, and the screen says so when there is not.

### 4. Connectivity — `lib/core/connectivity/`

Two facts, deliberately separate:

- **Interface state**, from the operating system via `connectivity_plus`, behind
  a `ConnectivityProbe` interface so tests never touch a platform channel.
- **Reachability**, from actual traffic. A successful refresh proves the server
  is there; a `NetworkFailure` proves it is not.

`ConnectivityStatus` is `online`, `offline`, or `unknown`. An interface coming
up moves the state to `unknown`, not to `online`: a center's Wi-Fi with no route
out would otherwise lie, and it is the case that matters most.

`SyncCoordinator` is the single place that reacts: it triggers a refresh when
the state leaves `offline`, and feeds every `SyncOutcome` back into the
connectivity state. Repositories do not subscribe individually — one hook, one
place to reason about.

### 5. Screens

- `features/boxes/ui/boxes_list_view.dart` — the center's boxes, pull to
  refresh, empty and offline states.
- `features/boxes/ui/box_detail_view.dart` — mirrors the web record from cache;
  refreshes when online; explains the need for signal when a box is not cached.
- `core/ui/stale_data_banner.dart` — "Sin conexión · datos de hace 12 minutos".
- `core/ui/relative_time.dart` — Spanish relative timestamps.
- `HomeView` gains navigation to the box list.

Operator-facing copy is Spanish and written in the widget, per the repository
convention.

### 6. Tests

Everything touching Drift runs against a real in-memory SQLite database, never
a double:

- schema opens at v1; `clearReadModel` empties every table;
- catalog replacement removes rows the server no longer serves, in one
  transaction;
- box paging stops at a short page and at the cap;
- a failed refresh leaves the cache intact and records the failure code;
- login as a different user clears the read model; login as the same user does
  not; a failed identity lookup clears;
- connectivity: interface down is offline, interface up is unknown, a success
  is online, a `NetworkFailure` is offline;
- widget: the list renders from cache with the stale banner when offline.

## New dependency

`connectivity_plus`. Nothing else.
