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
| 1 | Pallet operations | Create/close pallets, add sealed boxes by scan (reusing continuous scan mode), pallet weighing. | 🔴 High | ⬜ Pending |
| 2 | Shipment views and milestones | Shipment detail, logistics milestones timeline, manifest access. | 🟠 Medium | ⬜ Pending |
| 3 | Transfers | Between-center transfer participation. | 🟠 Medium | ⬜ Pending |
| 4 | Reception and incidents | Register what actually arrived (reconciliation) and incident capture. | 🔴 High | ⬜ Pending |
| 5 | Coordinator views | Risk reviews, campaign membership, volunteer management scoped to the center. | 🔴 High | ⬜ Pending |
| 6 | National dashboard | Aggregated read-only views for national administrators. | 🟠 Medium | ⬜ Pending |
| 7 | Messaging / notification center | In-app messaging surface complementing push. | 🟠 Medium | ⬜ Pending |
| 8 | Riverpod 3.x + codegen migration | When `riverpod`/`riverpod_generator` realign with stable Flutter's `flutter_test` pins; mechanical by design. | 🟠 Medium | ⬜ Pending |

---

## Suggested order

Decided at prioritization time, block by block.
