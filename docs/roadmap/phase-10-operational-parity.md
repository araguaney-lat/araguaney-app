# Phase 10 — Operational parity backlog

> Long-term goal: everything the web dashboard does, the application does,
> minus what the offline boundary forbids. This phase is a **prioritized
> backlog, not a committed scope**: when a block is scheduled it gets split
> into its own phase with proper tasks, following the same rule the backend
> roadmap uses. Every item is online-only by the Phase 06 boundary.

---

## Objectives

1. Keep the candidate surface visible so nobody mistakes "not yet" for "never".
2. Split blocks into real phases only when they are prioritized.

## Non-objectives

- Committing dates or order today.
- Anything that writes offline beyond intake capture: that boundary is a domain rule.

---

## Candidate blocks

| # | Block | Description | Complexity | Status |
|---|-------|-------------|------------|--------|
| 1 | Pallet operations | Create and close pallets, add and remove sealed boxes by scan without leaving the camera, tare and gross weights. Online only, and coordination only — the server enforces both. | 🔴 High | ✅ Done |
| 2 | Shipment views and milestones | Milestones timeline and manifest access. The read-only shipment record itself arrives earlier, in Phase 07: a `shipment_delivered` notice needs somewhere to land. | 🟠 Medium | ⬜ Pending |
| 3 | Transfers | Participating in a transfer: reading it, approving, rejecting with a reason, dispatching and receiving, each offered only where the server's machine allows it. **Creating one is not here** — see below. | 🟠 Medium | 🟨 Partial |
| 4 | Reception and incidents | Reading a reception with its shrinkage, and raising and listing incidents on a shipment — everything a center can do. **Reconciling is closed to national administration** and stays out; see below. | 🔴 High | 🟨 Partial |
| 5 | Coordinator views | Campaign membership and volunteer management scoped to the center. Resolving a risk review lives here; the read-only list of them arrives earlier, in Phase 07, for the same reason as the shipment record. | 🔴 High | ⬜ Pending |
| 6 | National dashboard | Aggregated read-only views for national administrators. Reopening `/v1/dashboard/**` in the generated client means solving the `anyOf` response the generator cannot express today — see `swagger_parser.yaml`. | 🟠 Medium | ⬜ Pending |
| 7 | Messaging / notification center | In-app messaging surface complementing push. | 🟠 Medium | ⬜ Pending |
| 8 | Riverpod 3.x + codegen migration | When `riverpod`/`riverpod_generator` realign with stable Flutter's `flutter_test` pins; mechanical by design. | 🟠 Medium | ⬜ Pending |

---

## What block 1 established for the blocks after it

Two pieces were built to be reused, not just to serve pallets:

- **`ContinuousScanView`** scans one label after another without closing the
  camera, and keeps a log of what the server said about each. Reception
  (block 4) is the same shape of work: someone with a stack in front of them and
  their hands full.
- **`ScannerCamera`** holds the camera, the torch and the denied-permission
  copy. Two screens scan today; the text a person reads when the camera is
  blocked has to be the same in both, and duplicating it guarantees that one day
  it will not be.

Also worth carrying forward: the weight discrepancy is computed and published by
the server, and shown here without adjectives. How much a difference matters is
a judgement that belongs to coordination, not to a colour in a mobile screen.

---

## What block 4 could not include, and why

The roadmap assumed the destination center registers what arrived. The backend
does not allow it: `POST /v1/shipments/{id}/reception` requires
`national_admin`. What a center coordinator can do is **read** the reception —
"le importa qué llegó de lo suyo", says the router — and **raise** incidents,
because the sending center is who notices something is missing.

So this block shipped what the application's actual audience can do, and
reconciliation is left as work for whoever builds a national administration
surface. It is not a small omission and it is not an oversight: a reconciliation
form on a phone, for a role that works from a desk, would have been screens
nobody opens.

Two properties of the backend model worth keeping if that form is ever built
here: **only exceptions travel** — whatever is not marked counts as received,
because shrinkage is the minority — and each exception opens its incident **on
the server**. The weight tolerance that decides whether a difference becomes an
incident lives there too, and the client must not learn it.

---

## Two gaps block 3 leaves named

**Creating a transfer is not in the application.** It needs a destination center
and a selection of sealed boxes — desk work, and the part of the flow least
likely to happen on a phone. Participation, which is the roadmap's own word, is
what shipped.

**The application cannot name the other center.** `GET /v1/centers` requires
`national_admin`, and `TransferOut` carries only identifiers. So a transfer is
shown by direction — incoming or outgoing, which is the distinction a
coordinator actually works from — and the other center stays unnamed. Fixing it
properly means `TransferOut` carrying `from_center_name` and `to_center_name`,
which is a backend change and belongs in its roadmap rather than in a client
workaround.

Also worth recording: the client mirrors the server's state machine to decide
which buttons to offer, and a test pins that table. It is duplication, chosen
knowingly over offering three buttons where two fail; the server still decides,
and its rejection is what the screen shows.

---

## Suggested order

Decided at prioritization time, block by block.
