# Phase 18 — Pre-registered donations

> Somebody registers a donation on the website, gets a code, and drives it to a
> centre. The panel has a screen for what happens next. This application has
> one endpoint and no screen.

---

## What already exists here, and how little of it

`GET /v1/donations/{code}` is called: the scanner resolves a donation code and
the result sheet shows it. That is the whole of it. There is no list, no way to
receive one, and no way to see what the donor said they were bringing.

So the scanner can answer «this is donation X» and then stop, on the one screen
where the next step is obvious: the boxes are on the floor and somebody has to
take them.

## Receiving is the operation, and it is the phone's

`POST /v1/donations/{code}/receive` is guarded by `require_center_role` — it is
a centre's own operation, not administration's. It happens at a door, with a
vehicle waiting, and it is precisely the kind of thing nobody wants to walk to a
computer for.

`GET /v1/donations/{code}/suggestions` is the other half: what the donor
declared, matched against the catalogue, so the person receiving does not type
the same list a second time.

## The seventeen routes that are not ours

`POST /v1/public/donations`, its confirmation, the management token, the photo
upload and deletion, cancelling — those are how a **donor** registers and
manages a donation from the website, without an account. They are the public
web's, and building them here would mean this application grew a second
audience.

Two of the photo routes are the exception worth arguing about:
`GET /v1/donations/{code}/photos/{photo_id}/url` and
`POST /v1/donations/{code}/photos/{photo_id}/read-label` belong to the receiving
side — looking at what the donor photographed, and asking the server to read a
label out of it. They are in scope here; the donor's upload is not.

## Offline

Reading a donation is cacheable and should be. **Receiving is not.** It is a
write against shared state — the same reasoning that keeps sealing and shipping
online — and two people receiving the same donation from two phones would
produce two truths about the same pallet of boxes.

---

## Objectives

1. List the donations heading for this centre, and read one.
2. Receive one at the door, from the phone.
3. Show what the donor declared instead of asking somebody to type it again.

## Non-objectives

- Anything a donor does. Registering, confirming, cancelling, uploading photos
  and managing a donation by token are the public website's.
- Receiving offline.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Donations repository | `GET /v1/donations` and `GET /v1/donations/{code}` behind a sealed outcome, with the read model caching the list. | 🟠 Medium | ⬜ Pending |
| 2 | The list | What is expected at this centre, what arrived, and what was received, in the order somebody asks those questions. | 🟠 Medium | ⬜ Pending |
| 3 | The record | The donor, the declared contents, the photos, and the state it is in. | 🟠 Medium | ⬜ Pending |
| 4 | Receiving | `POST /v1/donations/{code}/receive`, online only, with the reason said on screen. | 🔴 High | ⬜ Pending |
| 5 | What the donor declared | `GET /v1/donations/{code}/suggestions` so the contents are not typed twice. | 🟠 Medium | ⬜ Pending |
| 6 | The photos | Reading a photo, and asking the server to read a label out of one. | 🟠 Medium | ⬜ Pending |
| 7 | From the scanner to here | A scanned donation code leads to its record and to receiving, instead of ending at an identification. | 🟢 Low | ⬜ Pending |
| 8 | Verify on a device | A real code, a real reception, at a door. | 🟢 Low | ⬜ Pending |

This graduates block 9 of [Phase 10](phase-10-operational-parity.md).
