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
| 2 | Ask for the version | `GET /v1/client/version` on start, cached for the session, never blocking on failure. | 🟠 Medium | ⬜ Pending |
| 3 | The wall | Below the minimum, a screen that says what to do and offers Play, with no way past it. | 🟠 Medium | ⬜ Pending |
| 4 | The mention | An available update said once, where it does not interrupt what somebody is doing. | 🟢 Low | ⬜ Pending |
| 5 | Verify on a device | With a build deliberately declared below the minimum. | 🟢 Low | ⬜ Pending |
