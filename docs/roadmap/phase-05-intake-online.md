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
| 1 | Intake form | Campaign, optional donor identity, free-text legacy donor field; mirrors the web flow's semantics. | 🔴 High | ⬜ Pending |
| 2 | Product selection | From the local catalog with campaign visibility; search and category browsing. | 🟠 Medium | ⬜ Pending |
| 3 | Box composition | One product type + one batch + one expiry per box; the UI makes mixing impossible, the schema remains the guarantee. | 🔴 High | ⬜ Pending |
| 4 | Backend validation surface | Rejections (shelf life, controlled, required medicine fields) shown with the server's reason; nothing softened client-side. | 🟠 Medium | ⬜ Pending |
| 5 | Donation prefill | Scanning a `DN-` code prefills the intake from the pre-registered donation. | 🟠 Medium | ⬜ Pending |
| 6 | Box sealing | Online-only action with its reason stated in the UI; state change reflected in the local cache. | 🟠 Medium | ⬜ Pending |
| 7 | Client-rendered QR label | Display a box's QR for immediate labeling; batch PDF stays server-side. | 🟠 Medium | ⬜ Pending |
| 8 | Intake list and detail | The center's intakes with their outcome. | 🟠 Medium | ⬜ Pending |
| 9 | Tests | Widget tests for form/box invariant UI; flow tests with mocked API. | 🔴 High | ⬜ Pending |
| 10 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 3 (the capture core) → 4 → 5 → 6 → 7 → 8 → 9 → 10.
