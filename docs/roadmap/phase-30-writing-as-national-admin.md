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

Two shapes were possible and they are not equivalent:

- **Per capture.** The centre is part of the form, defaulted to nothing, and
  chosen every time. Safe, and tedious for somebody registering ten donations in
  one place — and answering the same question ten times in a row is how a
  question stops being read.
- **A working centre for the session.** Chosen once, shown permanently
  wherever it matters, and changed deliberately. Faster, and it fails badly if
  the reminder is not loud — somebody who forgets which centre they are «in»
  writes into the wrong one.

**The second was chosen**, on the condition that made it defensible: the current
centre is on every screen that writes, not in a settings page.

### «All centres» is not one of the shapes

The obvious third option — a session that reads the whole country and picks a
centre only when writing — was rejected where it matters most. Reception and
donation paperwork always name a centre; there is no such thing as receiving a
donation into every warehouse at once.

Country-wide numbers did not need that mode either. A report that covers every
centre is **a property of the report**, and it already works that way:
`StockByCategoryView` says «todos los centros» because the role is national, not
because a selector was left on «all». Whatever reports come later inherit that
shape, and nothing about the session becomes ambiguous.

### What the web panel does

`CenterSelector.tsx` renders a centre dropdown for a national administrator and
keeps the choice in a `useState` that reaches no request. It scopes nothing, on
either side. This phase is not a port of it.

## The other writes

Capture is the one that matters, because it is the operation this application
exists for. But the same rule applies to anything else that creates: pallets,
shipments, and the block of box codes. All of them name the working centre now,
or a national administrator would get the same silent wall one screen later.

Creating a transfer is not in this list because this application cannot create
one yet — that is [Phase 27](phase-27-create-a-transfer.md), and it inherits the
rule.

## Two things the work turned up

**Reading and writing had to move together.** Registering into one centre while
the boxes list shows the whole country is two different places on one screen.
The list endpoints take no centre filter, so the narrowing is client-side —
every read model carries its centre, which is what makes it possible. A
`center_id` query parameter would let the server do it, and is recorded as
request 9.

**A reserved block belongs to a centre, not only to a person.** The server hands
out codes for a centre; the device stored them under the person alone. Somebody
who reserved fifty codes in one warehouse and switched to another would have
spent the rest there, and the label is stuck on the box before anybody notices.
The queue's rule — that a device is shared, so rows are divided by who — needed
a second axis.

## What the offline queue gained

A fifth invariant, alongside the four already there:

> **The centre is fixed when the capture starts, not when it is sent.** The
> queue stores the request already built, so a capture registered in Caracas is
> still a Caracas capture after somebody walks to Valencia and changes centre.
> Resolving it at send time would move donations that were already put down,
> days after the fact.

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
| 2 | Decide the shape | A working centre for the session, chosen from real centres, with no «all centres» mode. | 🟠 Medium | ✅ Done |
| 3 | Choosing a centre | Asked once after signing in, changed from the menu. Uses [Phase 21](phase-21-centers.md) for the list. | 🟠 Medium | ✅ Done |
| 4 | Capture carries it | `IntakeCreate.center_id` set for the role that needs it and left null for everybody else, fixed when the capture starts. | 🟠 Medium | ✅ Done |
| 5 | Every other create | Pallets, shipments and the reserved code block, so the wall does not simply move. | 🟠 Medium | ✅ Done |
| 6 | Reads follow the centre | Boxes, pallets, shipments, captures and transfers narrowed to the working centre, client-side. | 🟠 Medium | ✅ Done |
| 7 | Codes belong to a centre | A block reserved for one centre is not spent in another. | 🟠 Medium | ✅ Done |
| 8 | `CENTER_REQUIRED` says something | For anything missed, the refusal explains what to do instead of arriving generic. | 🟢 Low | ✅ Done |
| 9 | Verify on a device | With a superadmin account, which is what surfaced this. | 🟢 Low | ⬜ Pending |
