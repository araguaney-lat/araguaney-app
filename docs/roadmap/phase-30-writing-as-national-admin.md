# Phase 30 — Writing as a national administrator

> A superadmin can read every centre from this application and register nothing
> in any of them.

---

## The exact mechanism

`resolve_write_center_id` in the backend says it plainly: every create endpoint
needs a concrete `center_id`, and a `national_admin` has no home centre, so they
must name one in the request body. Everybody else always writes to their own,
whatever they send.

`IntakeCreate` carries `center_id`. **This application never sets it.** So a
capture submitted by a national administrator is refused with `CENTER_REQUIRED`,
and what reaches the person is a generic failure.

Reading is unaffected: `tenant_scope` returns `None` for a national
administrator, which is why the same session lists pallets and boxes from every
centre without trouble. The asymmetry is the whole bug — everything looks like
it works until something is written.

## Why it was never noticed

Because the accounts that hit it are the two superadmin ones, and the sessions
that were tested belonged to a centre. A coordinator never sends `center_id` and
never needs to; the code path is correct for the role that uses it most and
missing for the role that has the most access.

## What it needs, and the decision inside it

A centre has to be chosen. That is not a settings toggle hidden somewhere: it
changes where physical boxes are recorded as being, and getting it wrong writes
a donation into the wrong warehouse.

Two shapes are possible and they are not equivalent:

- **Per capture.** The centre is part of the form, defaulted to nothing, and
  chosen every time. Safe, and tedious for somebody registering ten donations in
  one place.
- **A working centre for the session.** Chosen once, shown permanently
  wherever it matters, and changed deliberately. Faster, and it fails badly if
  the reminder is not loud — somebody who forgets which centre they are «in»
  writes into the wrong one.

The second is better if and only if the current centre is impossible to miss.
That is a design decision and belongs in the phase, not in a pull request.

## The other writes

Capture is the one that matters, because it is the operation this application
exists for. But the same rule applies to anything else that creates: pallets,
shipments, transfers. Whatever shape is chosen has to reach all of them, or a
national administrator gets the same silent wall one screen later.

---

## Objectives

1. Let a national administrator register a capture from this application.
2. Make the centre being written to impossible to mistake.
3. Cover every create, not only capture.

## Non-objectives

- Changing the backend rule. Requiring an explicit centre from somebody who
  belongs to none is correct.
- Letting a coordinator choose a centre. The server ignores it and the
  interface should not suggest otherwise.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the defect | Record the mechanism and that reads hide it. This file. | 🟢 Low | ✅ Done |
| 2 | Decide the shape | Per capture or a working centre for the session, with the reminder that makes the second safe. | 🟠 Medium | ⬜ Pending |
| 3 | Choosing a centre | Needs [Phase 21](phase-21-centers.md) for the list. | 🟠 Medium | ⬜ Pending |
| 4 | Capture carries it | `IntakeCreate.center_id` set for the role that needs it and left null for everybody else, pinned by a test. | 🟠 Medium | ⬜ Pending |
| 5 | Every other create | Pallets, shipments and transfers, so the wall does not simply move. | 🟠 Medium | ⬜ Pending |
| 6 | `CENTER_REQUIRED` says something | Until the above ships — and after, for anything missed — the refusal explains itself instead of arriving generic. | 🟢 Low | ⬜ Pending |
| 7 | Verify on a device | With a superadmin account, which is what surfaced this. | 🟢 Low | ⬜ Pending |
