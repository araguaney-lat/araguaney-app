# Phase 02 — Authentication and session

> The backend already issues and rotates JWT access/refresh tokens and owns the
> TOTP and forced-password-change flows. This phase contributes the screens and
> the token lifecycle on the device: refresh token in the platform secure store,
> access token only in memory, automatic renewal on 401.

---

## Objectives

1. Login against `/v1/auth/login` with the backend as the only authority.
2. Token storage that survives scrutiny: Keychain/Keystore for refresh, memory for access.
3. Transparent renewal with rotation; a failed renewal ends the local session.
4. The session flows the backend already requires: TOTP and forced password change.

## Non-objectives

- Registration or password recovery UI beyond linking to the existing web flows.
- Per-user offline queues (Phase 06); this phase only leaves user identity available to later phases.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Secure token storage | `flutter_secure_storage` for the refresh token; access token held in memory only. | 🟠 Medium | ⬜ Pending |
| 2 | Login screen and flow | Credentials → tokens; Spanish operator-facing errors, generic on purpose. | 🟠 Medium | ⬜ Pending |
| 3 | Refresh interceptor | On 401: renew (rotating), retry once, clear session on failure. Single-flight so concurrent 401s trigger one renewal. | 🔴 High | ⬜ Pending |
| 4 | Forced password change | `must_change_password` → blocking change screen before any operation. | 🟠 Medium | ⬜ Pending |
| 5 | TOTP challenge | Second-factor screen when the backend demands it. | 🟠 Medium | ⬜ Pending |
| 6 | Logout | Local wipe plus server-side revocation. | 🟢 Low | ⬜ Pending |
| 7 | Session state and guarding | Riverpod session provider; unauthenticated navigation lands on login. | 🟠 Medium | ⬜ Pending |
| 8 | Tests | Interceptor behavior (renewal, rotation, single-flight, failure), session transitions. | 🔴 High | ⬜ Pending |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 3 (the core loop) → 4 → 5 → 6 → 7 → 8 → 9.
