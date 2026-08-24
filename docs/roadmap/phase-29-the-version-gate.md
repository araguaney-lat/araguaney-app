# Phase 29 — The minimum version gate

> The architecture says an old binary is safe because `GET /v1/client/version`
> publishes the minimum supported version. That endpoint is never called.

---

## What exists and what is missing

`lib/core/api/client_version_gate.dart` is written. It has an enum, a comparison
and tests. **No file in the application invokes it**, and
`GET /v1/client/version` does not appear in any call site.

So the sentence in `CLAUDE.md` — «puede correr un binario de hace meses: el
contrato `/v1` es solo-aditivo y `GET /v1/client/version` publica la versión
mínima soportada» — describes a mechanism that is half-built. The additive
contract is real. The gate is not connected.

This is the same shape as the status tables and the screen list, at the level of
a whole feature: something written, tested, and never wired, invisible because
no list said it should be.

## Why it matters more than its size

The gate is what makes shipping to Play safe. The store hands an old version to
whoever has not updated, sometimes for months, and the contract being additive
protects the *data* — not the person using a build whose assumptions have moved
on. Without the gate, the only signal is a screen behaving oddly.

It also decides how loud to be. There are two answers and they are different:
**below the minimum** is a wall, and **an update is available** is a mention.
Conflating them either blocks somebody who is fine or lets somebody keep working
past the point where the application can be trusted.

## What it must not do

**It cannot block on a failed check.** The endpoint is one more request that can
time out in a basement, and an application that refuses to open because it could
not reach a version endpoint is worse than one running slightly behind. An
unreachable gate means «carry on», and it is checked again later.

## «Más tarde» tiene que significar más tarde

The wall is the contract's edge and takes no argument. The other state — a newer
version exists and the installed one still works — is a different question, and
getting it wrong in either direction is easy.

**A screen that forces every time** teaches people that this application
interrupts for things that do not matter. **A reminder every few hours** is worse:
it gets tapped away by reflex, and the day the wall finally arrives it arrives as
a surprise after weeks of dismissing the same thing.

The decisive observation is that **effectiveness does not come from frequency,
it comes from timing.** A notice beside a truck, mid-scan, is dismissed unread.
The same notice at launch — before anything has been started — costs almost
nothing and gets acted on. So:

- **It appears only at launch.** Never on a timer, never mid-shift. Once
  dismissed it stays gone for the life of the process, so a session change —
  signing in, a forced password change — cannot bring it back while somebody is
  working.
- **It says that queued captures survive the update.** That is the real fear of
  anybody holding unsent work, and without saying it «Más tarde» is the only
  reasonable answer.
- **Silence starts long and tightens**: five days on the first dismissal, two on
  the second, one from the third on. There are no publication dates in the
  contract, so a version's age is approximated by how many times *that* version
  has been put off — somebody ignoring it accumulates dismissals.
- **A new publication starts over.** The count is stored against the version, so
  a different one is a different thing being asked.

Play already updates most people in the background, so whoever sees this screen
has automatic updates off or is on a metered connection. That is a minority, and
treating it as if it never updated would be disproportionate.

## What the backend publishes today

```
GET https://api.araguaney.lat/v1/client/version
{"min_supported":"0.0.0","latest":"0.0.0"}
```

Both are placeholders, and that decides what «done» means here. With those
values the gate evaluates to `current` for every build ever shipped: nothing is
below `0.0.0`, and no version is newer than it either, so the wall can never
appear and the mention can never fire.

**That is the correct state for the client side to be in.** The mechanism is
wired, tested and inert, and it starts working the day somebody publishes real
numbers — which is a decision for the other repository and not something this
one can make on its own. The alternative, leaving the client unwired until the
backend has values, is how it stayed unwired for six phases.

Recorded as a request rather than assumed: until `min_supported` names a real
version, no build can ever be blocked, and until `latest` does, nobody is ever
told there is a newer one.

## What was found while wiring it

`AsyncValue.value` **rethrows** on an `AsyncError`. The first version of the
gate read `ref.watch(clientVersionStatusProvider).value`, which meant a failed
check would have thrown while building `SessionGate` and shown an error screen
— the exact opposite of the promise this phase is built on. It reads
`valueOrNull` now.

The test that caught it is the one that matters most here: «a failed check never
locks anybody out». It was written before the code was correct, and it failed.

---

## Objectives

1. Ask the server what the minimum is, on start and not on every screen.
2. Stop a build that is below it, saying what to do.
3. Mention an available update without interrupting.

## Non-objectives

- Updating in place. Play does that.
- Blocking when the check itself fails.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the gap | Record that the gate exists and nothing calls it. This file. | 🟢 Low | ✅ Done |
| 2 | Ask for the version | `GET /v1/client/version` on start through the unauthenticated client, cached for the session, failing open. | 🟠 Medium | ✅ Done |
| 3 | The wall | Below the minimum, a screen with no way past it, saying that queued captures survive, and opening the store through `market://` with the web listing as a fallback. | 🟠 Medium | ✅ Done |
| 4 | The mention | A line at the foot of the sign-in screen, beside the installed version. | 🟢 Low | ✅ Done |
| 5 | «Actualizar» or «Más tarde», at launch | The screen, shown only when the application opens, remembered per version, with silence starting at five days and tightening to one. | 🟠 Medium | ✅ Done |
| 6 | The installed version, at the foot | `Versión 1.0.0 (3)` on the sign-in screen and on the wall, with the build number, so asking «what version do you have» stops costing a conversation. | 🟢 Low | ✅ Done |
| 7 | Real values in the backend | Both are `0.0.0` today, so the gate is inert. Recorded as a request. | 🟢 Low | ⬜ Pending |
| 8 | Verify on a device | With a build deliberately declared below the minimum, once the backend publishes real values. | 🟢 Low | ⬜ Pending |
