# Phase 15 — The shipment, from opening it to dispatching it

> Long-term goal: the chain that starts with a donation at the counter should
> end with a lorry leaving, without anybody having to open a laptop halfway.

---

## Where the chain was cut

A centre could capture, seal, palletise and close a pallet — and then stop. The
application could read a shipment's journey and ask for its manifest, and the
record was reachable **only by tapping a push notification**. There was no list,
no way to open one, no way to put a pallet in or take it out, and no way to
close it or say it left.

Everything below is coordination work, which is what the server already
enforces: listing, creating, adding pallets, closing and dispatching all require
the coordinator role. Marking a shipment delivered requires national
administration and is not part of this phase — it is not the origin centre's
call.

## What a shipment is, in order

A shipment is **open** while it admits pallets, **closed** when it stops
admitting them, and **dispatched** when it has left. Those are three different
things and the words matter: a closed shipment has not gone anywhere yet.
Afterwards come delivered and reconciled, which belong to whoever receives it.

Closing and dispatching **go in one direction and the server does not undo
them**, so both ask first, and the question names what is at stake — how many
pallets, going where. A dialog that only says «¿estás seguro?» tells nobody
anything.

## What is offered, and when

Only the next step, and only to coordination:

| State | What the screen offers |
|---|---|
| Open | Add and remove pallets; close |
| Closed | Dispatch. No adding, no removing — it admits no changes |
| Dispatched onward | Nothing. What follows is not the origin centre's to do |

Offering a button the server is going to refuse is worse than not having one: it
turns a rule into a surprise.

## Which pallets can go in

Only **closed** ones that are not already travelling in another shipment. An
open pallet still admits boxes, and putting it in a shipment would freeze it
behind the back of whoever is building it. The server rejects it too; filtering
it in the sheet stops the application offering something that can only end in an
error.

## The height warnings are the server's

`ShipmentDetailOut.height_warnings` arrives already worded, computed against the
shipment's height profile. The application prints them and does not interpret
them, does not colour them red and does not block on them — because the server
does not block either. The threshold belongs to the profile, and a copy of it in
the client is the mistake this project has paid for repeatedly.

That is also why [Phase 12](phase-12-pallet-height.md) measures rather than
judges: it fills `height_cm`, and this is where the judgement lands.

---

## Objectives

1. Open a shipment, fill it, close it and dispatch it from the phone.
2. Offer only what the server would accept, given the state and the role.
3. Repeat the server's warnings without reinterpreting them.

## Non-objectives

- Marking a shipment delivered or reconciling it: not the origin centre's.
- The customs declaration export. It is a job like the manifest and can follow.
- Anything offline. Coordinating a shipment needs the server by definition.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Shipment operations | List, create, add and remove pallets, close and dispatch, behind a sealed outcome. The untyped add-pallet body is written in one place. | 🟠 Medium | ✅ Done |
| 2 | The list | Shipments with a count and per-status filters carrying their own counts, ordered by the path a shipment travels. | 🟠 Medium | ✅ Done |
| 3 | Opening one | Destination required, carrier, reference and notes optional; the record opens straight after. | 🟢 Low | ✅ Done |
| 4 | The pallets it carries | Listed in the record, added from the closed ones not already travelling, removable while the shipment is open. | 🟠 Medium | ✅ Done |
| 5 | Closing and dispatching | Only the next step, only to coordination, each asking first and naming what it carries. | 🟠 Medium | ✅ Done |
| 6 | Verify against production | The chain crosses four states and the roles differ; worth walking once with real pallets. | 🟠 Medium | ⬜ Pending |

## Found while building it

The shipment fixture carried `'delivered'` in lowercase — the real statuses are
`OPEN`, `CLOSED`, `SHIPPED`, `DELIVERED`, `RECONCILED`. It is the same shape as
the invented box statuses, the invented categories and the pallet fixture using
a box status: **fixtures that agree with the code and with nothing else.** The
shipment status was also being printed raw in the record, which makes four
status tables now sharing `core/ui/status_labels.dart`.
