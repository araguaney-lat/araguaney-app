# Phase 26 — The shipment, from dispatch to delivery

> Phase 15 taught the application to open a shipment, fill it, close it and
> dispatch it. What happens after it leaves has six routes and no screen.

---

## Where Phase 15 stopped, and why it stopped there

It stopped at `ship`. That was the right first half: opening, filling, closing
and dispatching are what a centre does with its own boxes, and they happen where
the boxes are.

What comes after is the journey: milestones along the way, a reception at the
other end, the declaration a border asks for, and the moment somebody marks it
delivered. The application already reads a reception —
`GET /v1/shipments/{id}/reception` is called — and can do nothing about it.

## The four operations, and who each belongs to

**Corrected on 2026-08-25 against `app/routers/shipment.py`.** The table below
said «coordinator» for three of these four and was wrong; the roles are what the
router actually requires:

| Route | Role | What it is |
|---|---|---|
| `POST .../milestones` | **`require_national_admin`** | «It crossed», «it stopped», «it is held». Written from the road. |
| `POST .../reception` | **`require_national_admin`** | What actually arrived, box by box. It is the reconcile, and it leaves the shipment in `RECONCILED`. |
| `POST .../delivered` | **`require_national_admin`** | The last state. Not a centre's to declare. |
| `POST .../declaracion.json` / `.xlsx`, `.../manifest.xlsx` | `require_coordinator` | Documents, produced by the server. |

That changes what this phase is. It is **not** the coordinator's missing half of
the shipment; it is national administration's, plus two documents a coordinator
can ask for. The mobile argument survives intact — somebody beside a truck at a
checkpoint has a phone and not a desk, whatever their role — but the phase no
longer belongs where a «serve the people who operate» ordering would put it.

The old table also contradicted this file's own non-objectives, which already
said reconciling a reception requires `national_admin` and is out of scope.
There is only one reception route, so «registering» and «reconciling» were the
same call under two names.

## Reception is where shrinkage is discovered

Registering a reception is what produces the difference between sent and
received, which [Phase 19](phase-19-center-reports.md) then reports. The two
should land together: a reception that finds a discrepancy should be able to
say so, and the shrinkage report should be reachable from it.

**It cannot be done offline**, for the same reason sealing cannot: two people
receiving the same shipment produce two truths.

## Documents are handed over, not drawn

The declaration and the spreadsheet manifest join the PDF manifest that already
works: the server produces the file and the system viewer opens it. This
application does not render a spreadsheet and will not start.

---

## Objectives

1. Write a milestone from the road.
2. Register a reception, and see the discrepancy it produces.
3. Ask for the declaration and the spreadsheet manifest.
4. Mark a shipment delivered, for whoever holds the role.

## Non-objectives

- Rendering documents.
- Anything offline.
- Reconciling a reception, which requires `national_admin` and is a decision
  already recorded as out of scope in Phase 15.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Milestones | `POST /v1/shipments/{id}/milestones` and the timeline that already reads them, written from beside the truck. | 🟠 Medium | ⬜ Pending |
| 2 | Registering a reception | `POST /v1/shipments/{id}/reception`, online only, with what was expected shown beside what arrived. | 🔴 High | ⬜ Pending |
| 3 | The discrepancy | What the reception produced, and a way to raise an incident from it — the two already exist separately. | 🟠 Medium | ⬜ Pending |
| 4 | Delivered | `POST /v1/shipments/{id}/delivered`, offered only to the role that has it. | 🟢 Low | ⬜ Pending |
| 5 | Declaration and spreadsheet | Three more documents through the path the PDF manifest already uses. | 🟢 Low | ⬜ Pending |
| 6 | Verify on a device | A shipment followed from dispatch to delivery. | 🟠 Medium | ⬜ Pending |

This graduates blocks 2 and 4 of [Phase 10](phase-10-operational-parity.md).
