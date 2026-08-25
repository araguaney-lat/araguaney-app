# Phase 23 — Incidents and the audit log

> An incident can be raised from a shipment and never seen again. `GET
> /v1/incidents` and `POST /v1/incidents/{id}/resolve` are generated and called
> by nothing.

---

## Half a feature, shipped

`POST /v1/shipments/{id}/incidents` is called: a coordinator reading a shipment
can report that something is wrong. That is the half that happens at the boxes.

The other half — the list of what has been reported, and closing one — has no
screen. So the application can create a thing it cannot show, which is the
worst of the two halves to be missing: somebody reports a problem and has no way
to find out whether anybody looked.

Resolving is `require_national_admin`; listing is a centre role. Two audiences,
one module, and the list is the part that matters most for the centre that
raised it.

## The audit log is a different question

`GET /v1/studio/audit` answers who did what. On a phone it is not a browsing
tool — nobody scrolls an audit log on a phone — but it is the answer to one
question that gets asked at bad moments: **«who sealed this box?»**, «who closed
this shipment», «who approved that transfer».

So the shape is not a screen full of rows. It is a line on a record: the
shipment, the box, the pallet already have a timeline, and the audit entry
belongs next to it.

## What the events routes already offer

`GET /v1/boxes/{box_id}/events` and `GET /v1/pallets/{pallet_id}/events` are
generated, unused, and answer exactly that question for the two objects somebody
holds. They are cheaper than the audit log and closer to where the question is
asked, which is why they come first here.

---

## Objectives

1. See the incidents this centre reported, and whether anything happened.
2. Close one, for whoever holds the role.
3. Answer «who did this» on the object somebody is holding.

## Non-objectives

- An audit browser. The panel is where somebody reads the log as a log.
- Reporting an incident, which already works.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Incidents repository | `GET /v1/incidents` and `POST /v1/incidents/{id}/resolve` behind a sealed outcome. | 🟠 Medium | ⬜ Pending |
| 2 | The list | What this centre reported, open first, with the shipment it belongs to. | 🟠 Medium | ⬜ Pending |
| 3 | Resolving | `national_admin` only, with the resolution written where the reporter can read it. | 🟠 Medium | ⬜ Pending |
| 4 | The timeline of a box and a pallet | `GET /v1/boxes/{id}/events` and `GET /v1/pallets/{id}/events` on their records, which shipments already have. Closes block 13 of Phase 10 in part. | 🟠 Medium | ⬜ Pending |
| 5 | Who did this | The audit entry as a line on a record rather than a screen of its own. | 🟠 Medium | ⬜ Pending |
| 6 | Verify on a device | With an incident raised from the phone and resolved from the panel. | 🟢 Low | ⬜ Pending |
