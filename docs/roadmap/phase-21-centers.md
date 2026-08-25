# Phase 21 — Centres

> Four routes, none called, and one consequence already written down: a
> transfer cannot name the other centre because listing centres requires a role
> this application never asks for.

---

## The gap this closes on the way

[Backend request 3](../backend-requests.md) exists because `TransferOut` carries
`from_center_id` and `to_center_id` and nothing else, and `GET /v1/centers`
requires `national_admin`. A coordinator therefore cannot resolve an identifier
into a name, and the transfers screen says so instead of guessing.

That request stays the right fix for a coordinator. But **a national
administrator can list centres**, and this application never lets them — so for
the one role that could name the other centre, the screen is silent for no
reason.

## What a centre record is for on a phone

Not administration. The useful cases are narrow and real: confirming which
centre a transfer is going to, finding a centre's contact when a shipment is
lost, and — for whoever coordinates nationally — seeing that a newly approved
centre exists.

Creating and editing a centre is `require_national_admin` and belongs to the
panel more than here. It is included because approving a centre application
(Phase 22) produces one, and a flow that creates something you cannot then look
at is half a flow.

## What shipped first, and what did not

Tasks 1 to 3. Reading centres, the record, and naming the other centre in a
transfer **for a session that can resolve it** — which for a coordinator is
still nobody, so that screen behaves exactly as it did: the direction, the date,
and no identifier. Backend request 3 remains the real fix for them.

**Creating and editing did not ship, on purpose.** The phase includes it because
approving a centre application produces a centre, and a flow that creates
something you cannot then look at is half a flow — but looking at it is task 2,
which is done. The form itself is `national_admin` only, belongs to the panel
more than here, and has no case that starts away from a desk. It waits for
[Phase 22](phase-22-center-applications.md), which is what would give it one.

### Two things the contract said and the generated model did not

`CenterOut` lists `address`, `contact_name`, `contact_email`, `contact_phone`,
`country_code` and `state_name` as **required**, and the generated Dart model
declares every one of them nullable. Whichever is right, the screen cannot
assume: it omits what does not arrive rather than drawing a label over nothing,
and a centre with no place shown has no second line. That is the same rule the
pallet rows learned and the same failure the box statuses were.

The list is also asked for **once** and reused. It is short, changes rarely, and
whoever looks at it is usually resolving several identifiers in a row — the rows
of a transfers list, for instance.

### The form, and what it deliberately does not do

**Only the name is required**, because that is all `CenterCreate` requires.
Adding obligations the contract does not have would be a business rule of this
client's own, which is exactly what it does not carry: if a centre needs more
than a name to be useful, the server is where that is decided and said. What is
left blank travels absent rather than as an empty string.

The fields are in the same order the panel asks for them. That matters little on
its own; what matters is that somebody who has registered a centre on the web
recognises the form without rereading it.

**Deactivating is not offered here, and the panel does offer it.** On the web it
is a toggle on a list row; on a phone a tappable chip that takes a centre out of
the public list is an accidental tap waiting to happen. What deactivating
actually does — removes it from the centres a donor can choose and from the
active listings — was read in the backend rather than assumed, and it is not
obviously a thing to do between two pallets. If it turns out to be needed, it
belongs behind a confirmation on the record and not on a row.

### Approving an application now leads to what it created

`approve` answers with `created_center_id`, and the queue offers it: after
approving, the confirmation carries «Ver centro». That is what closes the half
flow this phase named — creating something you cannot then look at — and it is
the moment the correction is most likely, with the application still in mind.

---

## Objectives

1. Read a centre: name, place, contact.
2. List them, for whoever is allowed.
3. Let a transfer name the other centre when the session can resolve it.

## Non-objectives

- Making centre management a mobile module. The panel is where a centre is
  configured.
- Replacing backend request 3. A coordinator still needs names on the transfer
  payload; this phase only stops leaving them out for the role that could look
  them up.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Centres repository | `GET /v1/centers` and `GET /v1/centers/{id}` behind a sealed outcome that treats a 403 as an answer and not a failure, since that is what a coordinator gets every time. | 🟠 Medium | ✅ Done |
| 2 | The record and the list | Name, place, address and contact, omitting what the response does not carry. Deactivated centres last, and said so. Reached from the menu, for whoever can list them. | 🟠 Medium | ✅ Done |
| 3 | Name the other centre when possible | The transfer row names it for a session that can resolve it. The silence stays for everybody else, without a dangling separator. | 🟠 Medium | ✅ Done |
| 4 | Create and edit | One form for both, with only the name required because that is all the contract asks. Reached from the list and from the record, and from the confirmation of an approved application. | 🟠 Medium | ✅ Done |
| 5 | Verify on a device | Against a transfer between two real centres. | 🟢 Low | ⬜ Pending |
