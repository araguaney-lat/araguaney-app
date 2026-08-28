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
| 1 | Register the Android app in Firebase | Package `lat.araguaney.araguaney_app`; SHA-1 not needed for FCM. The file goes to `android/app/google-services.json`, git-ignored. Everything around it is wired: without the file the build works and the application starts without notices. External prerequisite. | 🟠 Medium | ✅ Done |
| 2 | `PushService` interface | Four members, none mentioning FCM: start, current token, rotations, opened notices. `NoopPushService` is the implementation today and the `foss` one forever. | 🟠 Medium | ✅ Done |
| 3 | FCM implementation | `FcmPushService` is the only file in the project that imports Firebase: init, token, rotations, and taps from both sources — background and cold start. The Google Services Gradle plugin applies only when the configuration file exists. | 🔴 High | ✅ Done |
| 4 | `foss` flavor verification | CI proves the `foss` flavor picks no push service. That it carries no Firebase **is not proven**: the `foss` branch this row cited does not exist, here or on the remote. What is true is that CI runs the flavor test and that the decision is documented in `docs/release/foss.md`. Auditing the board on 2026-08-23 found the citation pointing at nothing. | 🟠 Medium | 🟨 Partial |
| 5 | Token lifecycle | Register on login and on every rotation; unregister on logout **before** the session is cleared. Nothing about notices can block entering or leaving: both hooks swallow their failures. An expired session cannot unregister and does not pretend to. | 🟠 Medium | ✅ Done |
| 6 | Tap-through routing | `risk_review` opens the center's reviews with the one from the notice marked; `shipment_delivered` opens the shipment record. Both screens arrive with this task. The router wraps only the authenticated branch. | 🟠 Medium | ✅ Done |
| 7 | Permission UX | A card on the home screen says which notices arrive, and only then opens the system prompt. It disappears on any decision: denying leaves nothing insisting. Whether it has been offered is state the application keeps, because Android does not. | 🟢 Low | ✅ Done |
| 8 | Tests | Lifecycle, logout ordering, payload parsing, tap routing to both destinations and to none, and the permission card in its four states. What stays uncovered is `FcmPushService` itself, which needs a device. | 🟠 Medium | ✅ Done |
| 9 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |
| 10 | Default notification channel and icon | An own channel at high importance, declared in the manifest and created at start-up, so an operational notice arrives as a banner and can be silenced on its own without silencing the application. Monochrome status-bar icon and brand accent colour. | 🟠 Medium | ✅ Done |
| 11 | Permission card on Android | Whether the invitation was already offered is remembered by the application, because Android reports "not granted" and never "not asked". The card no longer depends on a state that platform never produces. | 🟠 Medium | ✅ Done |
| 12 | `private_message` routes | The backend sends that kind when a private thread is opened or replied to, and had been sending it for a while: this client knew two kinds, so the notice arrived, was displayed and led nowhere when tapped. It opens the thread now. Campaign threads deliberately do not notify — that rule is the server's and this changes none of it. | 🟢 Low | ✅ Done |

---

## What running it on a device caught

Everything below was found the first time the application ran on an Android
image with Google Play services, against the production backend. All of it had
passed the test suite, because all of it lives past the seam the tests stop at.

**The tap routing was dead for the whole session.** `PushRouter` subscribes to
`onOpened` the moment the session turns active; `FcmPushService.onOpened`
touched `FirebaseMessaging` immediately; and Firebase was initialised by the
session binder, on a different path. When the screen won that race —
consistently, as it turned out — `getInitialMessage()` threw `[core/no-app]`,
the exception killed the subscription, and tapping a notice navigated nowhere
for the rest of the session. Registering the token still worked, because the
binder awaits `start()` before asking for one, which is exactly why nothing
looked wrong. The fix is for the class to guarantee its own initialisation:
`onOpened` awaits the idempotent `start()` before touching the plugin.

Worth stating plainly: **no unit test would have caught this.** The tests
exercise a fake `PushService`, and the bug lives in the one class that talks to
Firebase — the class the roadmap already recorded as "needs a device". The
verification that matters is the run: the notice arrives, the tap opens the
reviews screen, and the log shows `GET /v1/risk-reviews`.

**The same shape of defect had two more victims, both fixed here.** Every entry
point of `FcmPushService` touched Firebase without guaranteeing it was
initialised, so whoever arrived first paid: the router lost tap navigation, and
`permission()` threw inside a `FutureProvider`, where the error became an
`AsyncValue` nobody read and the permission card silently never rendered. Each
method now awaits the idempotent `start()`. Documenting a required call order
would have been cheaper to write and impossible to enforce.

**And the card had a second, independent reason not to appear.** It only
rendered on `notDetermined`, a state `firebase_messaging` never reports on
Android — there, "not granted" is always `denied`. So nobody was ever invited to
turn notices on, on the platform that ships first. The application now remembers
whether it already offered, which is the piece the system does not provide, and
the card no longer depends on a distinction that platform does not make.

**Notices also landed in Firebase's fallback channel**, at default importance:
silent, waiting in the shade, wearing Flutter's logo. There is now an own
channel at high importance, created at start-up and declared in the manifest,
with a monochrome icon and the brand accent. That also gives whoever receives
them a switch of their own in the system settings: these notices can be silenced
without silencing the application.

Verified the same way as the rest — on the emulator, against production: the
card appears on a fresh install, opens the system prompt, and the notice then
arrives as a banner on `channel=araguaney_operaciones` with `importance=4`.

---

## Where the taps land, and why there

A notice is only useful if the tap goes somewhere, and the contract does not
offer a direct route to either subject:

- **`risk_review` carries `intake_id`**, but there is no `GET /v1/intakes/{id}`.
  So the destination is `GET /v1/risk-reviews`, the center's open reviews, with
  the one whose intake matches marked. That screen also happens to be the only
  place where the **reason** can be read — which the notice withholds on
  purpose, because it is read on a lock screen. Landing on the capture itself
  would need request 2 in [`docs/backend-requests.md`](../backend-requests.md).
- **`shipment_delivered` carries `shipment_id`**, and `GET /v1/shipments/{id}`
  exists, so the destination is a read-only shipment record.

Both screens are Phase 10 material arriving early, kept to the minimum each
notice needs: no milestones, no manifest, no resolving a review. A notification
without a destination is worse than no notification.

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
