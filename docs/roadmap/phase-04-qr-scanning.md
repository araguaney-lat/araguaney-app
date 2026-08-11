# Phase 04 — QR scanning

> The native camera is one of the three reasons this application exists. This
> phase turns a scan into the right screen: a box code opens the box record, a
> pallet code the pallet record, a donation code (`DN-`) prefills the intake
> flow of Phase 05.

---

## Objectives

1. Fast, continuous scanning with the device camera (`mobile_scanner`).
2. Code resolution: box / pallet / donation codes each route to their destination.
3. Scanning works against the local cache when offline.

## Non-objectives

- Scan-driven mutations (adding boxes to pallets, etc.): they belong to the phases that own those operations.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Scanner integration | `mobile_scanner` restricted to QR, camera permission flows on Android and iOS, Spanish permission rationale. | 🟠 Medium | ✅ Done |
| 2 | Code parsing and routing | Recognize `BX-` box, `TM-` pallet and `DN-` donation codes, both as bare codes and inside the URL the backend puts in the QR; unknown codes get an honest error. | 🟠 Medium | ✅ Done |
| 3 | Box record from scan | Resolve from the local cache first; a box outside the cached window falls back to the public ficha, labelled as such. Offline the reason is stated rather than reported as a missing box. | 🟠 Medium | ✅ Done |
| 4 | Continuous scan mode | Keep the camera open for repeated scans, with haptic feedback per read and the same code throttled so one label does not fire a burst. Sound was dropped: it would mean another dependency for a cue a vibration already gives in a noisy warehouse. | 🟠 Medium | ✅ Done |
| 5 | Tests and manual test plan | Parsing, throttling and resolution covered automatically; manual plan for camera behavior on physical devices in `docs/testing/manual-scanning.md`. | 🟠 Medium | ✅ Done |
| 6 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## What the QR contains, and what the contract can resolve

The payload is a URL to the public record, not a bare code
(`backend/app/utils/qr.py`): `{base}/b/{code}`, `/p/{code}`, `/d/{code}`. The
prefixes are `BX-`, `TM-` and `DN-`; the `BOX-`/`PAL-` pair mentioned in the
contract's public QR endpoint is stale documentation upstream.

No authenticated route translates a code into an identifier, for boxes or for
pallets. The public fichas `GET /b/{code}` and `GET /p/{code}` fill that gap:
they return typed JSON and their Turnstile gate lives in the web proxy rather
than in the API route. Adopting them widened `swagger_parser.yaml` past `/v1`,
in its own commit and with the client regenerated.

Donations are the exception: `GET /v1/donations/{code}` resolves by code with
the session, so a `DN-` scan opens the real record.

---

## Suggested order

1 → 2 → 3 → 4 → 5 → 6.
