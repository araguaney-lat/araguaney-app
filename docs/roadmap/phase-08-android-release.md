# Phase 08 — Android release and distribution

> From a debug APK on one laptop to a signed App Bundle any teammate can ship
> from CI, distributed through Google Play internal testing. The laptop is an
> editor; CI is the binary factory.

---

## Objectives

1. Reproducible release builds from CI with pinned toolchain versions.
2. Signing material managed outside the repository, documented for forks.
3. Play internal testing as the standing distribution channel during development.
4. Version discipline wired to the backend's minimum-supported-version gate.

## Non-objectives

- Production rollout on Google Play: it happens when the product is ready, not in this phase.
- iOS (Phase 09).

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Google Play developer account | Registration, identity verification, payment. External prerequisite. | 🟠 Medium | ⬜ Pending |
| 2 | Upload keystore and signing config | Keystore generated and stored outside the repo; `key.properties` template documented; Play App Signing enabled. | 🟠 Medium | ⬜ Pending |
| 3 | Release build configuration | Shrinking/obfuscation settings, plugin keep rules, release `AppConfig` values via `--dart-define` (`API_BASE_URL`, `WEB_BASE_URL`, `APP_FLAVOR`). | 🟠 Medium | ⬜ Pending |
| 4 | CI release workflow | Tag → build signed AAB with pinned Flutter version → artifact; secrets via GitHub Actions. | 🔴 High | ⬜ Pending |
| 5 | Play internal testing | App created in the console, internal track configured, first AAB uploaded and installable. | 🟠 Medium | ⬜ Pending |
| 6 | Version strategy | `versionCode`/`versionName` discipline documented and aligned with `GET /v1/client/version`. | 🟠 Medium | ⬜ Pending |
| 7 | Crash reporting release wiring | Sentry release tagging and symbol upload from the CI release build. | 🟠 Medium | ⬜ Pending |
| 8 | Store listing (internal) | Spanish-first listing assets sufficient for testing tracks. | 🟢 Low | ⬜ Pending |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 (external) → 2 → 3 → 4 (the factory) → 5 → 6 → 7 → 8 → 9.
