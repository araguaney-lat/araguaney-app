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
| 1 | Donations repository | `GET /v1/donations` and `GET /v1/donations/{code}` behind a sealed outcome. | 🟠 Medium | ✅ Done |
| 2 | The list | What is expected at this centre and what was received, as the two questions the server itself separates. | 🟠 Medium | ✅ Done |
| 3 | The record | The declared contents, the photos, and the state it is in. **Not the donor** — see below. | 🟠 Medium | 🟨 Partial |
| 4 | Receiving | `POST /v1/donations/{code}/receive`, online only, with the reason said on screen. | 🔴 High | ✅ Done |
| 5 | What the donor declared | `GET /v1/donations/{code}/suggestions` for each free-text line, so the contents are not typed twice. | 🟠 Medium | ✅ Done |
| 6 | The photos | Reading a photo through its signed link, and asking the server to read a label out of one. | 🟠 Medium | ✅ Done |
| 7 | From the scanner to here | A scanned donation code opens its record instead of jumping to capture. | 🟢 Low | ✅ Done |
| 8 | Verify on a device | A real code, a real reception, at a door. | 🟢 Low | ⬜ Pending |

## The donor is not in the contract

`DonationOut` carries the code, the status, the declared items, the photos and
the centres. **It carries nothing about who donated**, although the model has
the relationship. The panel's own reception screen shows no donor either, so
this is not a gap between the two clients: it is what the endpoint publishes.

Whether that is a privacy decision or an oversight is the backend's answer to
give — `DonationPublicOut` says «sin un solo dato del donante» about the public
QR, and this is the centre-facing schema. Recorded as a question in
[`docs/backend-requests.md`](../backend-requests.md), not as a demand: receiving
works without it, and asking for personal data that somebody decided to withhold
would be the wrong request to make loudly.

## Marking is the exception, not the norm

`ReceiveIn` takes only the lines that went wrong; anything unmarked the server
counts as received. The screen follows that exactly, which is what makes the
normal case — everything arrived — a single button. What travels is what
somebody looked at and decided.

## Extras are not built yet

`ReceiveIn.extras` carries what arrived without being announced, and the
repository takes it. No screen fills it in: adding an unannounced line means
picking a catalogue product and a quantity at the door, which is the capture
form's job and duplicating it here would be a second way to do the same thing.
The reception registers what was declared; what came extra is captured.

This graduates block 9 of [Phase 10](phase-10-operational-parity.md).
