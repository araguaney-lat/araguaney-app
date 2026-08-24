# Phase 19 — Reports for the centre

> Seven report routes exist, are generated, and are called by nothing. The panel
> has a Reports module offered to every role; this application has none.

---

## What the routes answer

All seven hang off a campaign and are guarded by `require_campaign_access`, so
they are scoped to what the person can already see: activity over time, totals
by category, by centre, by country, a summary, shrinkage, and a CSV export.

`GET /v1/dashboard/national` — the one this application already calls — narrows
itself to the caller's centre and answers a single number per category. That is
a fragment of the same question, which is why «Stock por categoría» reads like
a screen that lost the rest of itself.

## What a phone should show, and what it should not

A report on a phone is not the panel's report made narrow. Two things change:

- **A number somebody acts on beats a table somebody studies.** What a
  coordinator asks a phone is «are we short of anything» and «did what we sent
  arrive», not «show me twelve columns».
- **The export is a file, not a view.** `POST .../export.csv` produces a job,
  and the application already knows how to hand a finished file to the system
  viewer — that is what the shipment manifest does. Rendering a spreadsheet is
  not this application's job and will not become one.

**Shrinkage is the one that earns its place.** It is the difference between what
was sent and what was received, and the person who needs it is standing in front
of the boxes that do not match.

---

## Objectives

1. Answer «how are we doing» without opening the panel.
2. Put shrinkage where the discrepancy is discovered.
3. Hand an export to the system rather than drawing it.

## Non-objectives

- Reproducing the panel's tables. A phone that shows twelve columns shows none.
- Charts for their own sake.
- Anything offline. A report is a question about now.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Reports repository | The seven routes behind a sealed outcome, scoped by campaign. | 🟠 Medium | ⬜ Pending |
| 2 | The summary | `GET /v1/reports/campaign/{id}/summary` as the screen somebody opens first. | 🟠 Medium | ⬜ Pending |
| 3 | By category, completed | What «Stock por categoría» is a fragment of, with the campaign chosen rather than assumed. | 🟠 Medium | ⬜ Pending |
| 4 | Shrinkage | Reached from a reception, where the discrepancy is found. | 🟠 Medium | ⬜ Pending |
| 5 | Activity and countries | Two reads that only make sense with a campaign selected. | 🟢 Low | ⬜ Pending |
| 6 | The export | `POST .../export.csv` produces a job; the file leaves for the system viewer, like a manifest. | 🟠 Medium | ⬜ Pending |
| 7 | Weight | `GET /v1/dashboard/weight` needs only a centre role and is not called. | 🟢 Low | ⬜ Pending |
| 8 | Verify on a device | Against a campaign with real movement. | 🟢 Low | ⬜ Pending |

This graduates block 12 of [Phase 10](phase-10-operational-parity.md).
