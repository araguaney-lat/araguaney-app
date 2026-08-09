# Phase 01 — API contract and generated client

> The backend publishes an OpenAPI specification with an additive-only `/v1`
> contract. This phase vendors a snapshot of that contract and generates the
> Dart client from it, so nobody writes models by hand twice, diffs are
> reviewable, and a fork can compile without access to any live backend.

---

## Objectives

1. A vendored `api/openapi.json` snapshot with a documented refresh procedure.
2. A generated Dart client (`dio` dialect) that no one edits by hand.
3. Typed error handling for the backend's error envelope.
4. The minimum-supported-version gate working from the first networked build.

## Non-objectives

- Authentication flows (Phase 02). This phase only leaves the HTTP plumbing ready.
- Any UI beyond the forced-update screen.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Vendor the OpenAPI snapshot | Commit `api/openapi.json` from the backend; document the refresh procedure (own commit, reviewable diff). | 🟠 Medium | ⬜ Pending |
| 2 | Client generation | Wire the OpenAPI-to-Dart generator (`dio` dialect) into `lib/core/api/generated/`; generated code excluded from analysis, never hand-edited. | 🔴 High | ⬜ Pending |
| 3 | Regeneration check in CI | CI fails if the committed generated client does not match the committed snapshot. | 🟠 Medium | ⬜ Pending |
| 4 | Dio base configuration | Base URL from `AppConfig`, timeouts, JSON handling, user-agent with app version. | 🟠 Medium | ⬜ Pending |
| 5 | Typed failures | Map the backend error envelope (`code`, `message`, `field`) to sealed failure types; generic Spanish messages for operators, detail preserved for diagnostics. | 🔴 High | ⬜ Pending |
| 6 | Client version gate | Call `GET /v1/client/version` on startup; below minimum → blocking update screen. | 🟠 Medium | ⬜ Pending |
| 7 | Tests | Error mapping and version gate against a mocked HTTP layer. | 🟠 Medium | ⬜ Pending |
| 8 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 3 (contract pipeline first) → 4 → 5 → 6 → 7 → 8.
