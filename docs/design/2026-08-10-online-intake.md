# Online intake and box operations (Phase 05)

> Design accepted on 2026-08-10. Covers the capture form, product selection,
> the homogeneous-box shape, how backend rejections surface, sealing, and the
> box label. Scope matches
> [`docs/roadmap/phase-05-intake-online.md`](../roadmap/phase-05-intake-online.md).

## Problem

This is the first write path. Everything before it read. Building it online —
with the network there to answer immediately — is what lets Phase 06 change
*when* a capture is submitted without changing *what* it contains.

## What the contract already decides

`IntakeCreate` requires exactly one field: `boxes`. Everything else —
`campaign_id`, `donor`, `donante_libre`, `donation_id`, `notes`,
`anonymous_exception_reason`, `capture_id` — is optional, and each carries a
rule that lives in the backend.

**The homogeneous-box invariant is the shape of `BoxDraft`.** One
`product_type_id`, one `batch`, one `expiry_date`, one `quantity`, one `unit`.
The interface cannot mix two products in a box because there is nowhere to write
the second one. No client-side rule enforces this; the schema does.

**`POST /v1/intakes` is idempotent on `capture_id`.** The backend returns the
capture it already registered rather than duplicating it, and resolves
concurrent retries through a unique constraint. That is what makes retrying the
normal case rather than a hazard.

## Design

### 1. The draft — `features/intake/domain/`

`IntakeDraft` and `BoxDraftInput` are immutable; every edit produces a new
draft. That matters more than usual here because of one field: `captureId` is
generated when the form opens and is never regenerated — not on edit, not on
failure, not on retry. `copyWith` cannot change it, and the test suite asserts
it survives every path through the form.

Clearing an identified donor needed its own method rather than a `copyWith`
argument: passing null to an optional parameter is indistinguishable from not
passing it, and "no donor" has to be expressible.

### 2. Submission — `features/intake/data/intake_repository.dart`

`IntakeSubmission` is sealed: `IntakeAccepted`, `IntakeNeedsDonor`,
`IntakeRejected`.

`IntakeNeedsDonor` exists as its own outcome because the interface answers it
differently. It is not a field to correct; it is a question for the person at
the counter. The backend escalates when a donation would stay anonymous beyond
what it is willing to accept, and the capture continues either by identifying
the donor or by recording why that was not possible.

**The client never learns the threshold.** It has no constant, no copy of the
rule, and no way to predict the escalation — it submits, and reacts to the
response. Anything else would fork a control the moment the backend tuned it.

The same applies to the donation terms: the checkbox is shown with a line
saying who has to accept them, and the server is what rejects
`TERMS_NOT_ACCEPTED`.

### 3. The form — one screen

Campaign and donor at the top, boxes as a list below, an add button that opens
one sheet per box. All the state lives in one place: nothing is lost by going
back, and reviewing before sending is looking down.

Products are chosen from the **local catalog** — search runs against Drift, so
it works with no signal and does not spend a request per keystroke. The catalog
already carries the campaign visibility the server served, which is the
invariant Phase 03 established.

The busy indicator is scoped to the request in flight. While a dialog waits for
a human to answer, the application is not submitting anything, and a spinning
indicator would say otherwise.

### 4. Sealing

`POST /v1/boxes/{box_id}/seal`, online only, with the state the server returns
written straight into the cache. The screen explains the requirement rather
than hiding the button: another device may be moving that box right now, and
deciding blind would leave two versions of the same box. A box that is already
sealed offers no seal action at all.

### 5. The label — drawn on the device

`qr_flutter` renders the QR locally, with the same payload the backend prints:
`{WEB_BASE_URL}/b/{code}`. Two labels for one box must not lead to different
places.

Rendering locally rather than fetching `qr.png` is an operational choice: a box
is labelled the moment it is sealed, and that moment can happen without signal —
which is exactly what Phase 06 will need. The batch PDF stays server-side,
where it belongs.

This adds one build-time value, `WEB_BASE_URL`, following the same pattern as
`API_BASE_URL`: injected by `--dart-define`, defaulting to localhost, with no
real environment committed to the repository.

### 6. Intake list and detail

`GET /v1/intakes`, consulted online. The reading that has to work without signal
is the inventory — catalog and boxes — not the history: nobody decides what to
do with a box by looking at the capture that created it. Each box in a capture
opens its label, so a box whose paper was lost can be relabelled without going
to the web panel.

### 7. Donation prefill

Scanning a `DN-` code opens its record, and from there a button starts a
capture bound to that donation. It sets `donation_id` and nothing else: the
items the donor declared are **not** turned into boxes. What gets registered is
what arrived; confusing the two would invent inventory.

## New dependencies

`uuid` for the capture key, `qr_flutter` for the label.
