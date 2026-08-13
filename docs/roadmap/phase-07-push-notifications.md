# Phase 07 — Push notifications

> Firebase Cloud Messaging, and nothing else from Firebase, isolated behind an
> internal interface so the `foss` flavor compiles without any proprietary
> dependency. **The backend side is done and live**: the device endpoints exist,
> the dispatch job is tested, and `PUSH_ENABLED` is on in production. What is
> missing is a real token, which only this application can produce.

---

## Objectives

1. Operational events reach the right operators: risk review opened, shipment delivered.
2. `PushService` as the only seam: FCM behind it, a no-op implementation for `foss`.
3. Forks can run push with their own Firebase project via documented templates.

## Non-objectives

- In-app notification center (Phase 10 candidate).
- Message notifications: the backend has not wired them, pending a rule that
  does not teach people to silence everything.
- Any other Firebase product.

---

## What the backend publishes

Both endpoints require a session and are **idempotent by design**, so the client
does not track whether it already registered.

| Endpoint | Body | Response |
|---|---|---|
| `POST /v1/devices` | `{token, platform: "android"\|"ios", app_version?}` | `{ok: true}` |
| `POST /v1/devices/unregister` | `{token}` | `{ok: true}` |

Three behaviours the client must not fight:

- **Registering an existing token reassigns it** to whoever holds the session.
  The server resolves the shared-device case; the application does nothing
  special.
- **Unregistering someone else's token answers 200 and does nothing.** That is
  not an error and must not be surfaced as one — answering differently would
  reveal whether a token exists.
- **Unregistering on logout is a requirement, not tidiness.** A center's phone
  is shared: without that call, the next person to log in would receive the
  previous person's notices.

Notification content is composed in Spanish by the server; the application only
displays it. What is for navigating travels in `data`:

| `kind` | Other fields | Recipient |
|---|---|---|
| `risk_review` | `intake_id` | Coordination of the center |
| `shipment_delivered` | `shipment_id` | Coordination of the origin center |

A design note worth carrying into the UI: **the risk review notice does not say
why it was raised.** It is read on a lock screen, sometimes with someone
standing next to you; the reason lives inside the review.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Register the Android app in Firebase | Package `lat.araguaney.araguaney_app`; SHA-1 not needed for FCM. The file goes to `android/app/google-services.json`, git-ignored. Everything around it is wired: without the file the build works and the application starts without notices. External prerequisite. | 🟠 Medium | ⛔ External |
| 2 | `PushService` interface | Four members, none mentioning FCM: start, current token, rotations, opened notices. `NoopPushService` is the implementation today and the `foss` one forever. | 🟠 Medium | ✅ Done |
| 3 | FCM implementation | `FcmPushService` is the only file in the project that imports Firebase: init, token, rotations, and taps from both sources — background and cold start. The Google Services Gradle plugin applies only when the configuration file exists. | 🔴 High | ✅ Done |
| 4 | `foss` flavor verification | CI proves the `foss` flavor picks no push service. That it carries no Firebase is proven on the `foss` branch, which removes the dependency — the decision is taken and documented in `docs/release/foss.md`. | 🟠 Medium | 🟨 Partial |
| 5 | Token lifecycle | Register on login and on every rotation; unregister on logout **before** the session is cleared. Nothing about notices can block entering or leaving: both hooks swallow their failures. An expired session cannot unregister and does not pretend to. | 🟠 Medium | ✅ Done |
| 6 | Tap-through routing | `risk_review` → the center's risk reviews; `shipment_delivered` → the shipment. See the gap below: neither destination exists in the application yet. | 🟠 Medium | ⬜ Pending |
| 7 | Permission UX | Spanish rationale before the system prompt; graceful degradation when denied — a denied permission never blocks capture. | 🟢 Low | ⬜ Pending |
| 8 | Tests | Lifecycle against a fake service, logout unregistering while the session is still alive, and payload routing including the incomplete and unknown cases. The FCM implementation and the tap destinations remain uncovered because they do not exist yet. | 🟠 Medium | 🟨 Partial |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## The gap task 6 has to close

A notification is only useful if the tap lands somewhere. Neither destination
exists today, and the contract does not offer a direct route to either:

- **`risk_review` carries `intake_id`**, but there is no `GET /v1/intakes/{id}`.
  What exists is `GET /v1/risk-reviews` (the center's open reviews) and
  `POST /v1/risk-reviews/{review_id}/resolve`. The honest destination is a risk
  review screen that lists them and highlights the one whose intake matches;
  routing to the intake itself would need a new backend endpoint.
- **`shipment_delivered` carries `shipment_id`**, and `GET /v1/shipments/{id}`
  exists, but the application has no shipment screen at all — shipments are
  Phase 10.

Neither is a reason to delay push. It is a reason to decide, before writing the
routing, that this phase brings the minimum destination each notice needs: a
read-only risk review list and a read-only shipment record. Both are Phase 10
material arriving early because a notification without a destination is worse
than no notification.

---

## How the `foss` promise is kept

A Dart dependency is not excluded by a `--dart-define`: now that
`firebase_messaging` is in `pubspec.yaml`, its native libraries are part of
every artifact built from it. The seam keeps Firebase out of the code paths of
a `foss` build, which is necessary and not sufficient — a build that never calls
Firebase still contains it.

The decision taken: **the `foss` artifact is built from a branch without the
dependency**, and the patch is kept to three changes so it can be rebased for
every release. `FcmPushService` concentrates every Firebase import into one
file precisely to keep that patch small. The cost — two artifacts from two
branches — is accepted knowingly and written down in
[`docs/release/foss.md`](../release/foss.md).

---

## Suggested order

1 (external) → 2 → 3 → 4 → 5 → 7 → 6 (with its two destinations) → 8 → 9.
