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
| 1 | Reports repository | The seven routes behind a sealed outcome, scoped by campaign. | 🟠 Medium | ✅ Done |
| 2 | The summary | Six of the ten numbers, the ones somebody acts on. | 🟠 Medium | ✅ Done |
| 3 | By category, completed | With the campaign chosen rather than assumed. | 🟠 Medium | ✅ Done |
| 4 | Shrinkage | Its own section, and reachable from a shipment's reception where the discrepancy is found. | 🟠 Medium | ✅ Done |
| 5 | Activity and countries | The seven most recent days, and the countries. | 🟢 Low | ✅ Done |
| 6 | The export | `POST .../export.csv` produces a job; the file leaves for the system viewer. | 🟠 Medium | ✅ Done |
| 7 | Weight | `GET /v1/dashboard/weight`, with the goal when the campaign set one. | 🟢 Low | ✅ Done |
| 8 | Verify on a device | Against a campaign with real movement. | 🟢 Low | ⬜ Pending |

## One screen, not five

Every route hangs off a campaign, so the campaign is chosen once at the top and
everything below answers for it. Five screens would mean choosing it five times,
or carrying it through five routes.

The order is the order of the questions: how much have we collected, what state
are the boxes in, did what we sent arrive, are we short of anything.

## What was left out of the summary on purpose

Ten numbers arrive and six are drawn. Active centres and total units are
answered better by the sections underneath, and the rejection rate is a
percentage of a percentage — a nine-cell grid on a phone is a grid nobody reads.

Nothing is hidden silently: the export hands over the whole thing, and the panel
still has the tables.

## Two things a report must not do

**Say nothing when it has nothing.** Shrinkage over zero reconciled boxes is not
«0%», it is «no reception has been squared up yet» — a percentage calculated on
nothing looks like a fact.

**Cut a list without saying so.** The activity list draws the seven most recent
days out of however many there are, and says which of the two numbers it is
showing. Silently truncating reads as «that was all there was».

## The document waiting was already shared

`awaitDocument` came out of the shipment manifest during Phase 27; the CSV is
its third caller and needed no new code.

This graduates block 12 of [Phase 10](phase-10-operational-parity.md).
