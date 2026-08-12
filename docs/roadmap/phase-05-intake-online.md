# Phase 05 — Online intake and box operations

> The first write path, with connectivity as a precondition. It exercises the
> whole domain surface the offline queue (Phase 06) will need — intake form,
> catalog selection, homogeneous boxes, backend validation — while the network
> is still there to answer immediately. Building online first means Phase 06
> changes *when* a capture is submitted, never *what* it contains.

---

## Objectives

1. Complete intake capture: donor (optional), campaign, items, boxes.
2. The homogeneous-box invariant expressed in the UI, enforced by the backend.
3. Backend rejections (shelf life, controlled products) surfaced honestly.
4. Box sealing, with the connectivity requirement explained.

## Non-objectives

- Offline capture (Phase 06).
- Pallet and shipment operations (Phase 10).
- Any client-side reimplementation of validation rules: the backend decides, the client displays.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Intake form | One screen: campaign, optional donor identity, free-text donor field, notes, and the boxes as a list. The capture key is generated on open and never regenerated. | 🔴 High | ✅ Done |
| 2 | Product selection | From the local catalog with the campaign visibility the server served; search by name, brand or active ingredient, and category chips. Runs against Drift, so it works with no signal. | 🟠 Medium | ✅ Done |
| 3 | Box composition | One product type + one batch + one expiry per box; the UI makes mixing impossible, the schema remains the guarantee. | 🔴 High | ✅ Done |
| 4 | Backend validation surface | Rejections shown with the server's reason, nothing softened client-side. The escalation that asks to identify a donor is its own outcome: the client holds no threshold and only reacts to the response, resubmitting with the same capture key. | 🟠 Medium | ✅ Done |
| 5 | Donation prefill | Scanning a `DN-` code opens the donation and starts a capture bound to it. Only `donation_id` is set: what the donor declared does not become boxes, because what is registered is what arrived. | 🟠 Medium | ✅ Done |
| 6 | Box sealing | Online-only action with its reason stated in the UI; state change reflected in the local cache. | 🟠 Medium | ✅ Done |
| 7 | Client-rendered QR label | Drawn on the device with the same payload the backend prints, so a box can be labelled the moment it is sealed even without signal. Adds `WEB_BASE_URL` as a build-time value. Batch PDF stays server-side. | 🟠 Medium | ✅ Done |
| 8 | Intake list and detail | The center's intakes with their boxes, consulted online; each box opens its label. | 🟠 Medium | ✅ Done |
| 9 | Tests | Draft, repository outcomes, form flow including the donor escalation and the resubmission with the same key, catalog search, sealing against real SQLite, and the label payload. | 🔴 High | ✅ Done |
| 10 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## Where the rules live

`IntakeCreate` requires one field, `boxes`. The homogeneous-box invariant is
the shape of `BoxDraft` itself — one product type, one batch, one expiry — so
the interface cannot mix two products in a box because there is nowhere to
write the second one. No client-side check enforces it.

`POST /v1/intakes` is idempotent on `capture_id`, which is why retrying is the
normal case rather than a hazard, and why the key is generated before the first
attempt and never regenerated.

The volume escalation and the donation terms are backend controls. The client
carries neither threshold nor condition: it submits and reacts to the answer.

---

## Suggested order

1 → 2 → 3 (the capture core) → 4 → 5 → 6 → 7 → 8 → 9 → 10.
