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
| 1 | Scanner integration | `mobile_scanner` with camera permission flows on Android and iOS, Spanish permission rationale. | 🟠 Medium | ⬜ Pending |
| 2 | Code parsing and routing | Recognize box, pallet, and `DN-` donation codes; unknown codes get an honest error. | 🟠 Medium | ⬜ Pending |
| 3 | Box record from scan | Resolve from local cache first, fetch when online; offline shows the cached record with its staleness. | 🟠 Medium | ⬜ Pending |
| 4 | Continuous scan mode | Keep the camera open for repeated scans, haptic/sound feedback per read; reusable by later operational phases. | 🟠 Medium | ⬜ Pending |
| 5 | Tests and manual test plan | Parsing unit tests; documented manual plan for camera behavior on physical devices. | 🟠 Medium | ⬜ Pending |
| 6 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 3 → 4 → 5 → 6.
