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
| 3 | Transfers | Between-center transfer participation. | 🟠 Medium | ⬜ Pending |
| 4 | Reception and incidents | Register what actually arrived (reconciliation) and incident capture. | 🔴 High | ⬜ Pending |
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

## Suggested order

Decided at prioritization time, block by block.
