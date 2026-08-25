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

## What shipped, and the two things it turned up

Tasks 1 to 4. Listing incidents, closing one, and the box and pallet timelines.

### The timeline was showing the server's keys

`describeShipmentEvent` rendered a state change as
`'${event.fromStatus} → ${event.toStatus}'` — raw. So the one screen that used
it read «CLOSED → SHIPPED» to somebody reading Spanish. **Eighth time this
repository has paid for the same shape**, after the box statuses, the
categories, the pallet and donation tables, the transfer and review ones.

It is now `describeEvent`, and it takes the label table as a parameter. That is
not ceremony: the same `QrEventOut` describes a shipment, a box and a pallet,
and «CLOSED» means a different thing in each of the three. A shared drawing with
a per-object vocabulary is what makes one timeline widget correct in three
places.

### Translating it exposed an invented fixture

The test asserted `'CLOSED → IN_TRANSIT'`, which was wrong twice over: it pinned
a raw key as though it were something a person should read, and **`IN_TRANSIT`
is not a shipment status at all**. `SHIPMENT_STATUSES` is `OPEN, CLOSED,
SHIPPED, DELIVERED, RECONCILED`; `IN_TRANSIT` belongs to transfers. The fixture
agreed with the code and with nothing the server sends, and it had been that way
since the shipment work.

Nobody could have noticed while the keys were printed raw. Making the screen
speak Spanish is what made the wrong word visible — which is the argument for
translating at the edge rather than «later».

## What the list decides

**Open first, oldest at the top.** An old open incident is exactly the one being
forgotten, and a list sorted by recency buries it.

**The description is quoted and unedited**, and so is the closing note, which is
the only thing left to whoever reported it. The contract requires that note and
the reason is that: somebody saw a box was missing, said so, and this sentence
is what they read afterwards. Closing without explaining turns a report into
silence.

**Closing needs national administration; listing needs only a coordinator.** The
button is absent rather than refused for everybody else.

## The timelines are at the foot of a record, and they are quiet

They answer «who sealed this?» about the object somebody is holding — the
question asked at bad moments, not on every open. So they go last, they draw
nothing while loading, and a failure to fetch them leaves the record intact:
what somebody came to see is above.

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
| 1 | Incidents repository | The centre's incidents and closing one, behind a sealed outcome that reads a 403 as an answer. | 🟠 Medium | ✅ Done |
| 2 | The list | Open first and oldest at the top, quoted, with a way to the shipment it belongs to. | 🟠 Medium | ✅ Done |
| 3 | Closing one | `national_admin` only, with the note required and what was reported quoted while it is written. | 🟠 Medium | ✅ Done |
| 4 | The timeline of a box and a pallet | One widget for the three records, with the status vocabulary passed in — which is what turned up the raw keys and the invented fixture. Closes block 13 of Phase 10 in part. | 🟠 Medium | ✅ Done |
| 5 | Who did this | The audit entry as a line on a record rather than a screen of its own. | 🟠 Medium | ⬜ Pending |
| 6 | Verify on a device | With an incident raised from the phone and resolved from the panel. | 🟢 Low | ⬜ Pending |
