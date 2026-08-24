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
| 1 | Centres repository | `GET /v1/centers`, `GET /v1/centers/{id}` behind a sealed outcome, cached for reading. | 🟠 Medium | ⬜ Pending |
| 2 | The record | Name, country, state, address, contact — reachable from a transfer and from a shipment. | 🟠 Medium | ⬜ Pending |
| 3 | Name the other centre when possible | For a session that can resolve it, the transfer row names the centre instead of staying silent. The silence stays for everybody else. | 🟠 Medium | ⬜ Pending |
| 4 | Create and edit | `national_admin` only; the destination of an approved application. | 🟠 Medium | ⬜ Pending |
| 5 | Verify on a device | Against a transfer between two real centres. | 🟢 Low | ⬜ Pending |
