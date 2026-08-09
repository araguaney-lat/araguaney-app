# Phase 07 — Push notifications

> Firebase Cloud Messaging, and nothing else from Firebase, isolated behind an
> internal interface so the `foss` flavor compiles without any proprietary
> dependency. The server side (device token registry and event dispatch) is a
> phase of the backend repository's roadmap and gates this one.

---

## Objectives

1. Operational events reach the right operators: risk review opened, shipment delivered, message received.
2. `PushService` as the only seam: FCM behind it, a no-op implementation for `foss`.
3. Forks can run push with their own Firebase project via documented templates.

## Non-objectives

- In-app notification center (Phase 10 candidate).
- Any other Firebase product.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Backend counterpart gate | Device token endpoints and dispatch job exist in the backend (tracked in the backend repository's roadmap). | 🟠 Medium | ⬜ Pending |
| 2 | `PushService` interface | Register/unregister, token refresh, message tap routing; no-op implementation for `foss`. | 🟠 Medium | ⬜ Pending |
| 3 | FCM implementation | `firebase_messaging` wired only in non-`foss` flavors; configuration file templates documented, never versioned. | 🔴 High | ⬜ Pending |
| 4 | `foss` flavor verification | CI job proves the `foss` build compiles with zero Firebase dependencies. | 🟠 Medium | ⬜ Pending |
| 5 | Token lifecycle | Register on login, unregister on logout, re-register on token rotation. | 🟠 Medium | ⬜ Pending |
| 6 | Tap-through routing | A notification opens the relevant screen (risk review, shipment, message). | 🟠 Medium | ⬜ Pending |
| 7 | Permission UX | Spanish rationale before the system prompt; graceful degradation when denied. | 🟢 Low | ⬜ Pending |
| 8 | Tests | Interface contract tests; token lifecycle with a fake implementation. | 🟠 Medium | ⬜ Pending |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 (external gate) → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9.
