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
| 4 | The mention | Said at the foot of the sign-in screen, beside the installed version, where it interrupts nothing. | 🟢 Low | ✅ Done |
| 5 | The installed version, at the foot | `Versión 1.0.0 (3)` on the sign-in screen and on the wall, with the build number, so asking «what version do you have» stops costing a conversation. | 🟢 Low | ✅ Done |
| 6 | Real values in the backend | Both are `0.0.0` today, so the gate is inert. Recorded as a request. | 🟢 Low | ⬜ Pending |
| 7 | Verify on a device | With a build deliberately declared below the minimum, once the backend publishes real values. | 🟢 Low | ⬜ Pending |
