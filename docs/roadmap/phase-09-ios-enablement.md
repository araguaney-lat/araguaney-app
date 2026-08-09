# Phase 09 — iOS enablement

> Deferred by an explicit cost decision: the Apple Developer Program costs
> USD 99/year and Android covers the field first. Local development needs no
> paid account; this phase activates when iOS distribution is prioritized.
> CI already runs on macOS runners at no cost in public repositories.

---

## Objectives

1. The application runs and is testable on iOS (simulator, then devices).
2. TestFlight as the iOS testing channel, built from CI.
3. Push working through APNs via the existing FCM setup.

## Non-objectives

- App Store production release: same criterion as Android, when the product is ready.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Apple Developer Program | Enrollment and verification. External prerequisite, USD 99/year. | 🟠 Medium | ⬜ Pending |
| 2 | Local iOS toolchain | Xcode installed, simulator run, camera/permission strings in `Info.plist` with Spanish rationale. | 🟠 Medium | ⬜ Pending |
| 3 | Signing and TestFlight from CI | Certificates/profiles managed via CI secrets; macOS runner builds and uploads to TestFlight. | 🔴 High | ⬜ Pending |
| 4 | APNs key in Firebase | Push flows through the same FCM channel on iOS. | 🟠 Medium | ⬜ Pending |
| 5 | Device verification pass | The manual test plans from earlier phases executed on physical iPhones. | 🟠 Medium | ⬜ Pending |
| 6 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

---

## Suggested order

1 → 2 → 3 → 4 → 5 → 6.
