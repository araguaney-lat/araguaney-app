# Phase 27 — Creating a transfer

> The application can read a transfer, approve it, reject it, dispatch it and
> receive it. It cannot start one.

---

## The one missing verb

Eight of the nine transfer routes are called. `POST /v1/transfers` is not.

So a centre can answer a transfer and cannot propose one — which is the half
that begins at a shelf, looking at boxes somebody else needs more than you do.

## Why it was left out, and why that reason is thin

Creating a transfer needs three things a phone makes awkward: the destination
centre, chosen from a list this application cannot read; a set of sealed boxes,
chosen from an inventory; and a note explaining why.

The first is real and is [Phase 21](phase-21-centers.md). The second is not
awkward at all — **choosing sealed boxes by scanning them is the thing this
application is best at**, and the pallet screen already does exactly that
pattern. The third is a text field.

So the blocker was the centre list, and once that exists this is a short phase.

## Boxes, not quantities

`TransferCreate` carries `box_ids`. A transfer moves specific sealed boxes, not
an amount of a product, and the interface has to say that: scanning is the
natural way to choose them and the only one that cannot pick a box that is not
in your hand.

---

## Objectives

1. Propose a transfer to another centre, choosing the boxes by scanning them.
2. Say why, in words the other centre will read.

## Non-objectives

- Anything offline. A transfer proposes moving shared state.
- Choosing boxes from a list without scanning them, as the only path.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | The destination | Needs [Phase 21](phase-21-centers.md): a centre cannot be chosen from a list this application cannot read. | 🟠 Medium | ⬜ Pending |
| 2 | Choosing the boxes | Scanning them, with the pattern the pallet screen already uses, and a running count. | 🟠 Medium | ⬜ Pending |
| 3 | Creating it | `POST /v1/transfers` with the note, and the refusal shown as the server phrased it. | 🟠 Medium | ⬜ Pending |
| 4 | The manifest | `POST /v1/transfers/{id}/manifest.pdf`, through the path the shipment manifest already uses. | 🟢 Low | ⬜ Pending |
| 5 | Verify on a device | A transfer proposed from a phone and answered from the panel. | 🟢 Low | ⬜ Pending |

This completes block 3 of [Phase 10](phase-10-operational-parity.md).
