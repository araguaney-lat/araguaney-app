# Phase 12 — Measuring a pallet with the camera

> Long-term goal: the height a pallet is closed with should be measured rather
> than eyeballed, using the camera the operator already has in their hand, and
> it should be honest about how well it knows the number.

---

## Why this belongs in the mobile client

The charter of this application is narrow on purpose: it is a thin layer over
`/v1` that adds **what a phone does better than a browser** — the native camera,
capture without signal, and push. Measuring a physical object is squarely in
that list. It is not business logic; it is a sensor, like the QR scanner.

The rule it feeds already exists on the server, and this phase does not touch
it:

- `Pallet.height_cm` is a column and `PalletCloseIn.height_cm` is accepted
  today. The application already sends it — typed on a keyboard in
  `close_pallet_sheet.dart`.
- A shipment carries a `height_profile`, and the server computes
  `height_warnings` against each pallet's height. The backend's own comment
  states the decision plainly: it **warns and never blocks**.

So the phase changes *how a number is obtained*, not what the number means or
who judges it. **The application measures; the server judges.** It must not draw
the limit, colour a field red, or say «excede» — that threshold lives in the
shipment's profile, and putting a copy of it in the client is the mistake Phase
11 spent two pull requests documenting.

## What this is not

- **Not AR.** ARKit and ARCore would do this, and Apple's Measure app is the
  obvious reference, but ARCore requires Google Play Services for AR and a
  device on Google's compatibility list — a much shorter list than the Android
  floor this project deliberately targets. It would also mean real native code
  on two platforms in a repository that has almost none, a proprietary
  dependency needing the same seam as `PushService`, and no `foss` build. And
  the accuracy advantage is not obvious in the conditions that matter: a
  warehouse with poor light and a pallet wrapped in shiny stretch film, which is
  close to the worst input a feature tracker can be given.
- **Not a replacement for the field.** The measurement is a suggestion over the
  number somebody can still type. If the tool cannot see well enough, the
  keyboard is still there and nothing is lost.
- **Not a verdict.** No pass/fail, no limit line.

## How it works

The geometry needs no new dependency. `mobile_scanner` — already in the project
for the QR scanner — exposes `Barcode.corners`: the four vertices of the code in
image coordinates. Four points of a square of known physical size determine the
homography from the image plane to the marker's plane, which is exactly what
corrects perspective.

1. A printed marker hangs on the **front face** of the pallet.
2. The operator frames it; the app finds the marker and its corners.
3. The operator taps **two points: the floor and the top of the load**.
4. Both taps are mapped through the homography and the distance between them is
   read in millimetres.
5. The number is shown as an estimate with its uncertainty, and the operator
   confirms or corrects it before it travels.

## The three things that must be said out loud

**It only measures what is coplanar with the marker.** If the load overhangs the
front of the pallet, what gets measured is the front, not the overhang. This is
the failure mode that does not look like one, so the screen has to say it rather
than assume the instruction was read once.

**Error grows with the distance being measured.** A three-pixel slip on a marker
spanning a hundred pixels becomes centimetres at a metre and a half. Two
consequences, both mandatory:

- The marker is **A4-sized**, not a box label. A four-centimetre label would
  multiply the same pixel error by roughly four times as much.
- Below a minimum marker size in the frame, the application **refuses to give a
  number** instead of giving a bad one. The uncertainty here is genuinely
  computable from the marker's pixel span and the measured span, so it can be
  shown honestly — `≈ 152 cm ±4` — rather than asserted.

**The marker verifies itself.** The sheet carries a printed ruler beside the
code. If a tape measure disagrees with it, the printer scaled the page and the
sheet is reprinted at 100 %. Without that check, one printer setting biases
every measurement that center ever takes, silently — the same shape as every
defect Phase 11 turned up.

---

## Objectives

1. Obtain a pallet height from the camera, with a stated uncertainty.
2. Refuse rather than guess when the image cannot support a measurement.
3. Leave the typed field working exactly as it does today.

## Non-objectives

- Any judgement about the height. The server owns the profile and the warnings.
- AR, depth sensors, or any dependency that narrows the device floor.
- Measuring anything other than a pallet, for now.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Homography arithmetic | Four-point DLT and the inverse map, in Dart, in `lib/core/measure/`. Tested against synthetic cases whose answer is known by construction, including rotated and strongly tilted views. | 🟠 Medium | ⬜ Pending |
| 2 | Uncertainty and refusal | Propagate a pixel-localisation error through the map to a millimetre figure; define and test the marker-span floor below which no number is offered. | 🟠 Medium | ⬜ Pending |
| 3 | The printed marker | A shareable A4 PDF: the code, a printed ruler for the scale check, and the instruction to hang it on the front face. Printed once per center, not per pallet. | 🟢 Low | ⬜ Pending |
| 4 | Measuring screen | Camera preview, marker detection, two taps, the estimate with its uncertainty, and the coplanarity warning where it will be read. | 🔴 High | ⬜ Pending |
| 5 | Hook into closing a pallet | Offer the measurement as a suggestion over `height_cm` in `close_pallet_sheet.dart`, never replacing the typed field. | 🟢 Low | ⬜ Pending |
| 6 | Verification against a tape | Measure real pallets against a tape measure and record the observed error before this is offered as usable. A tool of this kind earns trust by being checked, not by compiling. | 🟠 Medium | ⬜ Pending |

Nothing here is blocked: no endpoint, no permission and no contract change is
needed. `height_cm` already exists and already travels.
