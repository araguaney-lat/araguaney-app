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
| 1 | The destination | The active centres, minus this one — the server refuses origin equal to destination, and offering it would be offering a refusal. | 🟠 Medium | ✅ Done |
| 2 | Choosing the boxes | Scanning them, with the pattern the pallet screen already uses, and a running count. | 🟠 Medium | ✅ Done |
| 3 | Creating it | `POST /v1/transfers` with the note, and the refusal shown as the server phrased it. | 🟠 Medium | ✅ Done |
| 4 | The manifest | `POST /v1/transfers/{id}/manifest.pdf`, through the path the shipment manifest already uses — now shared rather than copied. | 🟢 Low | ✅ Done |
| 5 | Verify on a device | A transfer proposed from a phone and answered from the panel. | 🟢 Low | ⬜ Pending |

## Reading a box's state is not duplicating a rule

Creating a transfer is **one call with the whole list inside it**, so a single
box the server refuses takes the other nineteen with it — and finding that out
at the end means scanning them all again. So a scan that hits a box the cached
copy says is unsealed, on a pallet, or already in the list stops there and says
which of those it is.

That is reading what the server served, not deciding it: the rule still lives in
`transfer_service.py` and still decides at creation. The line worth holding is
that the screen never says **why the rule exists**, only what the box currently
is.

A box that is not in the local cache is refused too, with that as the reason.
Nothing can be said about it, and adding it blind is exactly what would refuse
the list at the end.

## The document waiting moved to `core`

Asking for a manifest is «start a job, then ask until it is done», and the
shipment had it written inside its repository because it was the only one that
needed it. The transfer is the second, so it became `awaitDocument` — the same
thirty lines, now in one place instead of two.

This completes block 3 of [Phase 10](phase-10-operational-parity.md).
