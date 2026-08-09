# Architecture design — Araguaney App

**Date:** 2026-08-09
**Status:** approved
**Scope:** architecture decisions for the mobile client, prior to the first line of code.

This document records what was decided and why, including the alternatives that were
evaluated and discarded. The domain rules cited here (the offline boundary, the
additive API contract, the risk controls) originate in the backend and are documented
in the [`araguaney-lat/araguaney`](https://github.com/araguaney-lat/araguaney)
repository; they are referenced here as constraints this client inherits, not as
decisions of its own.

---

## 1. Premises

1. **The application is a thin layer.** Every business rule lives in the backend and
   is enforced there. The client captures, scans, queries, and synchronizes. If a
   feature seems to require logic in the client, the first question is whether the
   backend is missing an endpoint.
2. **The contract is `/v1`, additive-only.** A binary installed months ago must keep
   working. The backend publishes the minimum supported client version
   (`GET /v1/client/version`) so that an outdated installation prompts for an update
   instead of failing silently.
3. **The repository is public** and any organization can build its own version. This
   conditions the license, configuration management (no first-party infrastructure
   projects in the repository), and the relationship with third-party services.
4. **The mobile client's differential value** over the existing responsive web
   application is concrete: a native camera for continuous QR scanning, offline
   capture in low-connectivity environments, and push notifications for operational
   events. Parity with the rest of the web panel is a long-term goal, not a criterion
   for the first version.

## 2. Framework choice

**Decision: Flutter.**

| Alternative | Assessment |
|---|---|
| **Flutter** | A single codebase for both platforms with its own renderer (not a webview). A mature ecosystem for this client's specific needs: `mobile_scanner` (camera-based QR scanning), Drift (typed SQLite for caches and the offline queue), first-class analysis and formatting tooling. Accepted risk: Dart is a minority language and shrinks the pool of potential contributors compared to TypeScript; mitigated with a clear architecture and contribution documentation. |
| React Native + Expo | Would share a language with the web frontend (TypeScript). Discarded due to the less ergonomic SQLite/offline layer, higher ecosystem churn, and a build workflow that pushes toward paid services. |
| Kotlin Multiplatform / Compose Multiplatform | iOS support does not yet have the maturity required to bet an operational product on it. |
| PWA / Capacitor over the existing web app | The web already offers offline capture, but provides no reliable push on iOS, no quality camera scanning, and no store presence. It does not deliver the differential being sought. |

## 3. Project structure

- **Feature-first** organization, not by type:

```
lib/
  core/        # api (generated client), auth, db (Drift), push, config, i18n
  features/
    intake/    # data / domain / ui
    boxes/
    scan/
    pallets/
    shipments/
    dashboard/
test/          # mirrors lib/
api/
  openapi.json # vendored snapshot of the backend contract
```

- State management with **Riverpod** (codegen): testable and without the ceremony of
  heavier alternatives. Bloc with strict hexagonal architecture was evaluated and
  discarded: for the team size, the boilerplate costs more than it protects.
- Language conventions identical to the backend: identifiers in English, product
  prose in Spanish, contributor-facing prose in English.

## 4. API contract: a generated client

- The backend (FastAPI) publishes its OpenAPI specification. This repository
  **vendors a snapshot** (`api/openapi.json`) from which the Dart client is generated
  (`dio` dialect). Nobody writes models by hand twice.
- Updating the contract is a pull request that updates the snapshot and regenerates
  the client: the diff is reviewable, builds are deterministic, and a fork can
  compile without access to any live backend.
- The backend's contract tests guarantee that a new snapshot never breaks an old
  client (additive compatibility within `/v1`).

## 5. Authentication

- Direct login against `/v1/auth/login`; the backend issues access and refresh
  tokens and rotates the refresh token on every renewal.
- **The refresh token is stored in the platform's secure store** (Keychain on iOS,
  Keystore on Android) via `flutter_secure_storage`. **The access token lives only in
  memory.** Never in SharedPreferences or in files.
- HTTP interceptor: on 401, renew, retry once, and on failure clear the local
  session.
- The TOTP and forced-password-change flows already exist in the backend; the client
  only contributes the screens.

## 6. Offline model

### 6.1 Reading

Fully available offline: the catalog, stock, and the center's boxes are cached in the
local database (Drift) and refreshed when the application opens and on explicit user
action.

### 6.2 Writing: the boundary is a domain rule

**Only donation intake capture writes offline.** It is the only operation that
depends exclusively on what the operator has in front of them. Sealing a box,
building a pallet, or closing a shipment depends on shared state that may be changing
on another device; deciding it without connectivity would produce two truths about
the same box, and that error ends in an incorrect manifest in front of a customs
authority. These operations require connectivity, and the interface explains why.

The capture queue carries the same invariants as the web application's offline
capture:

1. The idempotency key (`capture_id`) is generated **before** the first attempt and
   never changes: retrying is the normal case, not the exception.
2. The local catalog preserves the server's per-campaign visibility: a product
   eligible without signal is one the server is going to accept.
3. The queue is **per user**: a shared device never attributes one person's capture
   to another person's session.
4. **Nothing is discarded automatically**: a business rejection stops retrying and
   waits for an explicit human decision, with the server's reason visible.

Box codes are reserved while online so they can be spent offline; a rejected capture
does not return its codes to the pool, because the physical label with that number
may already be attached to a box.

### 6.3 Synchronization

In the foreground when the application opens, with a visible counter of pending
captures. The operational instruction is the same as on the web: upon regaining
signal, open the application and wait for the counter to reach zero. The door remains
open to opportunistic background synchronization (e.g. `workmanager`) as a later
improvement that does not change the design.

## 7. Push notifications

- **Firebase Cloud Messaging is the only piece of Firebase in use.** Firebase Auth,
  Firestore, and Analytics are not adopted: authentication, data, and storage belong
  to the project's own backend.
- Access to FCM is **isolated behind an internal interface** (`PushService`). A
  deliberate consequence: a `foss` build flavor compiles without any Firebase
  dependency, with push disabled. This lets a fork operate without a Firebase project
  and keeps open distribution through channels that exclude proprietary services
  (e.g. F-Droid).
- Each fork that wants push uses its own Firebase project. Configuration files
  (`google-services.json` and equivalents) **are not versioned**; they are documented
  with templates.
- The server side (per-device token registry and event dispatch) is implemented in
  the backend repository as a phase of its own roadmap.

## 8. Observability

- Sentry (Flutter SDK) for errors and crashes, with generic messages shown to the
  operator and technical detail only in the event.
- The DSN is injected through build configuration; the `foss` flavor and forks can
  operate without Sentry.

## 9. License

**GNU GPL v3.0 or later, with an additional permission under section 7 for
distribution through application stores** (see `LICENSE` and
`LICENSE-EXCEPTIONS.md`).

Rationale:

- The backend is AGPL-3.0. Client and server are separate programs communicating
  over a network, so there is no license interaction between repositories; the
  client's license is chosen on its own merits.
- Copyleft is intended: a fork of the application must publish its code, consistent
  with the spirit of the project.
- Distributing GPL software through application stores has a known conflict between
  those platforms' terms and the license. The standard mechanism to resolve it is an
  additional permission under section 7 of GPLv3, which expressly authorizes store
  distribution as long as the complete source code remains available under the
  license.
- AGPL-3.0 with a contributor license agreement (high friction for external
  contributions) and MPL-2.0 (would allow proprietary forks) were evaluated and
  discarded.

## 10. Quality and testing

- Coverage floor: 80%. Unit and widget tests for all new behavior.
- The local database layer and the offline queue are tested against a **real
  in-memory SQLite database**, not mocks: most defects in that layer live in
  transaction handling, and mocks do not reproduce them. (The same criterion that led
  the web application to test against a real IndexedDB.)
- Golden tests for critical rendering screens (box record and label).
- Integration tests for the capture → box flow on an emulator in CI.
- Pull request gates: `flutter analyze` with no issues, `dart format` applied,
  `flutter test` passing.

## 11. Development infrastructure and distribution

- **CI: GitHub Actions.** On public repositories, runners (including the macOS
  runners required for iOS builds) have no cost, which allows building and testing
  both platforms without additional services.
- **Android:** distribution through Google Play (internal testing → closed testing →
  production). Signing with a self-managed keystore, kept outside the repository.
- **iOS:** local development and testing require no paid account; distribution
  (TestFlight and the App Store) requires Apple Developer Program membership and
  will be activated when that channel is prioritized.
- **Build flavors:** `dev` / `prod` (and `foss`) via `--dart-define` (API URL,
  capability flags).

## 12. Accepted risks and mitigations

| Risk | Mitigation |
|---|---|
| Drift between client and API | Vendored OpenAPI snapshot + contract tests in the backend + additive contract |
| Smaller Dart contributor pool than TypeScript's | Clear feature-first architecture, explicit CONTRIBUTING, CI that makes the standard evident |
| Double maintenance, web + app | The app stays thin: when new logic appears, the first question is whether an endpoint is missing |
| Reimplementing the offline queue that already exists on the web | What is reimplemented are **invariants documented as a contract**, not translated code; the four invariants have their own tests on each platform |
| Dependency on proprietary services (FCM) | Isolated behind an internal interface; the `foss` flavor compiles without it |
