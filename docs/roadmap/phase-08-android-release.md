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
| 1 | Google Play developer account | Registration, identity verification, payment. External prerequisite. **Done on 2026-08-20: the account is registered and identity verification passed.** | 🟠 Medium | ✅ Done |
| 2 | Upload keystore and signing config | Gradle reads `key.properties`; template and generation documented; release builds unsigned when it is absent, so a fork can build without a key. **The keystore itself and Play App Signing are external.**  **Done on 2026-08-16**: the keystore exists outside the repository, the four signing secrets are loaded, and Play App Signing activated with the first upload. | 🟠 Medium | ✅ Done |
| 3 | Release build configuration | Shrinking and resource shrinking with R8, keep rules per plugin explaining what breaks without each, obfuscation with split debug info, and release `AppConfig` values via `--dart-define` (`API_BASE_URL`, `WEB_BASE_URL`, `APP_FLAVOR`, `SENTRY_DSN`). | 🟠 Medium | ✅ Done |
| 4 | CI release workflow | Tag → signed AAB with a pinned Flutter version → bundle and debug symbols as artifacts; signing material from repository secrets, written and deleted around the build. Integration CI pins the same version. | 🔴 High | ✅ Done |
| 5 | Play internal testing | App created in the console, internal track configured, first AAB uploaded and installable. **Unblocked on 2026-08-20** — task 1 is done; what remains is the upload keystore (task 2) and the console steps.  **Done on 2026-08-20**: the app exists in the console, the internal track is configured, and `1.0.0+1` was uploaded and installed on a real phone. | 🟠 Medium | ✅ Done |
| 6 | Version strategy | `versionCode`/`versionName` discipline documented in `docs/release/versioning.md` and aligned with `GET /v1/client/version`. | 🟠 Medium | ✅ Done |
| 7 | Crash reporting release wiring | Sentry initialised only when a DSN is configured, tagged `package@version+build`, no request bodies. Symbols are published as a build artifact. **Uploading them to Sentry needs the DSN and an auth token.** | 🟠 Medium | 🟨 Partial |
| 8 | Store listing (internal) | Spanish-first listing assets sufficient for testing tracks. **Unblocked on 2026-08-20** with task 1. | 🟢 Low | ⬜ Pending |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## What the repository can and cannot do

Four of these tasks need accounts and key material that do not belong in a
repository, and no amount of code substitutes for them: the Play account, the
keystore, the console app with its internal track, and the store listing. They
are marked external rather than pending, because nothing here unblocks them.

What is done is the half that is code: the build knows how to sign when the
material exists, the factory knows how to assemble it from secrets, and the
version discipline is written down and wired to the backend's gate. The day the
account and the keystore exist, a tag produces an uploadable bundle without
touching this repository again.

Documentation lives in [`docs/release/android.md`](../release/android.md) and
[`docs/release/versioning.md`](../release/versioning.md).

---

## Suggested order

1 (external) → 2 → 3 → 4 (the factory) → 5 → 6 → 7 → 8 → 9.
