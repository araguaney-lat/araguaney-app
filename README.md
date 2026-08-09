# Araguaney App

Mobile client (Android and iOS, built with Flutter) for [Araguaney](https://github.com/araguaney-lat/araguaney), the open-source platform that coordinates in-kind donation collection centers and prepares humanitarian shipments with standardized boxes, pallets, and exportable manifests.

> **Status: pre-development.** This repository currently contains the architecture and design documentation. Application code will follow the roadmap described in `docs/`.

## What this application is

The Araguaney backend is API-first: every operation is available through a versioned REST API (`/v1`) with an additive-only compatibility contract. This application is a **thin client** of that API:

- It contains **no business logic of its own**. Validation rules, state machines, and tenant scoping live in the backend and are enforced there.
- It targets the workflows where a mobile device adds real value over the responsive web application: camera-based QR scanning, offline donation capture in low-connectivity environments, and push notifications for operational events.
- It follows the backend's compatibility contract: the app may run a binary that is months old, and the backend exposes a minimum supported client version so outdated installations prompt for an update instead of failing silently.

## Architecture at a glance

| Concern | Decision |
|---|---|
| Framework | Flutter (single codebase for Android and iOS) |
| Project layout | Feature-first (`lib/features/<feature>/{data,domain,ui}` with shared infrastructure under `lib/core/`) |
| State management | Riverpod |
| HTTP client | `dio`, with a Dart API client generated from a vendored OpenAPI snapshot of the backend contract |
| Local database | Drift (typed SQLite) for read caches and the offline capture queue |
| Authentication | Backend-issued JWT access/refresh tokens; refresh token stored in the platform keystore (Keychain / Android Keystore) |
| Push notifications | Firebase Cloud Messaging, isolated behind an internal interface; a `foss` build flavor compiles without Firebase |
| Error monitoring | Sentry |

The full rationale for each decision, including the offline write boundary and the constraints inherited from the backend's domain rules, is documented in `docs/design/`.

## Offline behavior

Reading is fully available offline: catalog, stock, and the center's boxes are cached locally and refreshed when connectivity returns. **Writing offline is limited to donation intake capture** — the one operation that depends only on what is physically in front of the operator. Sealing boxes, building pallets, and closing shipments require connectivity, because they depend on shared state that may be changing on other devices. This boundary is a deliberate domain rule inherited from the backend, not a pending feature.

## Building your own version

This repository is public and the license permits redistribution under its terms. Forks that want push notifications need their own Firebase project; the `foss` flavor builds without any Firebase dependency. Configuration templates and build documentation will be published alongside the application code.

## Related repositories

- [`araguaney-lat/araguaney`](https://github.com/araguaney-lat/araguaney) — backend (FastAPI) and web application (Next.js).

## License

GNU General Public License v3.0 or later, with an additional permission under GPLv3 section 7 that allows distribution through application store services. See [LICENSE](LICENSE) and [LICENSE-EXCEPTIONS.md](LICENSE-EXCEPTIONS.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please read the design documents in `docs/` before proposing changes: several boundaries that may look like limitations (for example, the offline write scope) are deliberate domain rules.
