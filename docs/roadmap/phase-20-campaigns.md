# Phase 20 — Campaigns

> The application can add and remove members of a campaign. It cannot list the
> campaigns, read one, or create one — and the capture screen picks a campaign
> from a sheet that has no record behind it.

---

## What is here and what is not

Two routes are called: `POST /v1/campaigns/{id}/members` and its delete. Four
are not: the list, the record, creation and editing.

That produces a specific oddity. `campaign_sheet.dart` lets somebody choose a
campaign while capturing, and there is nowhere to find out what that campaign
is — when it opened, what it is for, who else is in it. The choice is offered
and the context is not.

## Two different permissions in one module

`app/routers/campaign.py` mixes them: membership is `require_coordinator`, and
creating or editing a campaign is `require_national_admin`. The panel splits
this across two navigation groups for the same reason — «Campañas» for everyone
and «Campañas» again under administration.

Worth keeping that split visible here rather than showing a create button that
answers 403.

## The general campaign is not like the others

`PROTECTED_CAMPAIGN` already exists in the refusal copy: nobody can be removed
from the general campaign, because it is where everything that does not belong
to another campaign goes. A campaign record has to say that about itself rather
than let somebody discover it by being refused.

---

## Objectives

1. Read a campaign: what it is, when it runs, who is in it.
2. List the campaigns this person can capture into.
3. Create and edit one, for whoever holds the role.

## Non-objectives

- Campaign membership management, which already exists and works.
- Offline. A campaign that closed while somebody was in a basement should not
  still be offered — though what the capture queue already caches keeps its own
  rule, from Phase 06.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Campaigns repository | The four unused routes behind a sealed outcome. | 🟠 Medium | ✅ Done |
| 2 | The list | From the menu for coordination, and from the capture sheet as an ⓘ beside each option. | 🟠 Medium | ✅ Done |
| 3 | The record | Dates, purpose, its members, whether it is the general one, and its reports. | 🟠 Medium | ✅ Done |
| 4 | Create and edit | `national_admin` only, and the button absent rather than refused. | 🟠 Medium | ✅ Done |
| 5 | Verify on a device | Against a centre that participates in more than one. | 🟢 Low | ⬜ Pending |

## Three permissions, not two

The phase expected two — membership for coordination, creating for national
administration. Checking `app/routers/campaign.py` found a third: **listing and
reading a campaign are `require_coordinator` too.**

So a volunteer picks a campaign while capturing —`/campaigns/mine` needs only a
centre role— and cannot open what they picked. The interface follows that
exactly: the menu entry and the ⓘ in the capture sheet appear for coordination
and above, and nobody else is shown a door that answers 403.

## The goal is only editable

`CampaignCreate` has no `weight_goal_kg` and `CampaignUpdate` does. The form
offers the field only when correcting, because a field the create silently
discards would be lying about what is being saved.

## What the record borrows

Its members come from the team repository, which already called that route for
the campaign-members screen. Its reports are one tap away, now that
[Phase 19](phase-19-center-reports.md) exists — a campaign record that could not
answer «how is it going» would be a list of dates.
