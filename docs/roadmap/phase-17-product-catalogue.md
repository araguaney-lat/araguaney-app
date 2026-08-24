# Phase 17 — The product catalogue

> The person who discovers that a product is missing from the catalogue is
> holding it. Today they have to remember it, find a computer, and hope they
> still remember it.

---

## Why this one first among the missing modules

Every other gap in [the parity review](parity-with-the-panel.md) is work the
panel does better or just as well. This one is the opposite: **the catalogue is
edited at the moment a box is being packed**, which is exactly where the phone
is and the computer is not. A volunteer capturing a donation finds a brand the
catalogue does not have, and the options today are to pick something close —
which quietly corrupts the inventory — or to stop.

It is also the module the barcode scanner was built for. Phase 13 taught the
application to read a GTIN off a package and find the product; when the lookup
fails, the honest next step is «then let me add it», and there is nowhere to go.

## What the panel has, and what nobody sees

`/dashboard/catalog` and `/dashboard/catalog/new` are real pages and **are not
in the panel's navigation** — nothing links to them, so reaching the catalogue
means typing the URL. That is worth naming before building the mobile side: the
module is not missing here and present there. It is unreachable in both, for
different reasons.

## Who is allowed

`app/routers/product_type.py` guards its writes with `require_national_admin`.
So this is not a screen for whoever is capturing: it is a screen for the person
who coordinates nationally, and the volunteer's path is to ask for the product
rather than create it.

That changes the design. A «no está en el catálogo» dead end for a volunteer is
not solved by giving them a form that will answer 403 — it is solved by letting
them say what is in their hand and having somebody with the role resolve it.
Which means this phase has two halves and only one of them is a form.

## Promotion is not editing

`POST /v1/product-types/{pt_id}/promote` exists because the catalogue has two
tiers: what a centre proposed and what the platform accepts. Promotion is the
act of accepting one. It has its own route and its own role, and folding it
into «edit» would hide a decision inside a save button.

## The GTIN list is a relationship, not a field

`GET /v1/product-types/{pt_id}/gtins` and
`DELETE /v1/product-types/{pt_id}/gtins/{gtin_id}` mean a product can carry
several barcodes — the same tin in two presentations, a relabelled import.
Unlinking one is how a wrong scan gets corrected, and it is the operation that
makes Phase 13 trustworthy over time.

---

## Objectives

1. Find a product in the catalogue from the phone, by name or by barcode.
2. Add one when it is missing, for whoever holds the role.
3. Correct a product's barcodes when a scan turns out to point at the wrong
   thing.
4. Give a volunteer somewhere to go when the catalogue does not have what they
   are holding.

## Non-objectives

- Deleting a product. The panel does not offer it either and a catalogue entry
  with history behind it is not something to remove from a phone.
- Editing categories or units as a taxonomy. Those are the platform's, not a
  centre's.
- Working offline. The catalogue is cached for reading; writing to it needs the
  server, and a product invented offline could not be validated against what
  already exists.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Catalogue repository | `GET /v1/product-types`, `/search`, `/{id}`, `/{id}/gtins` behind a sealed outcome, with the local Drift cache still answering reads. | 🟠 Medium | ⬜ Pending |
| 2 | Product record | Name, category, unit, presentation, its barcodes, and whether it is proposed or accepted. Reachable from the picker and from a scan. | 🟠 Medium | ⬜ Pending |
| 3 | Search that asks the server | `GET /v1/product-types/search` and `GET /v1/catalog/search`, which exist and nothing calls: the local cache answers what is cached and the server answers the rest. Closes block 14 of Phase 10. | 🟠 Medium | ⬜ Pending |
| 4 | Create a product | The form, for `national_admin` only, reachable from a failed barcode lookup so it lands where the gap was found. | 🔴 High | ⬜ Pending |
| 5 | Edit and promote | `PATCH` for the fields, `promote` as its own action with its own words, because accepting a proposal is a decision and not a save. | 🟠 Medium | ⬜ Pending |
| 6 | Unlink a barcode | `DELETE /v1/product-types/{pt_id}/gtins/{gtin_id}`, which is how a wrong scan gets corrected. | 🟢 Low | ⬜ Pending |
| 7 | The volunteer's path | Somebody without the role says what they are holding and it reaches whoever can create it. Needs a decision on the vehicle — a message thread already exists — and possibly a backend request. | 🟠 Medium | ⬜ Pending |
| 8 | Verify on a device | Scanning a package the catalogue does not know, and going from that dead end to a created product. | 🟢 Low | ⬜ Pending |

## Recorded for the other repository

The catalogue pages are not linked from the panel's navigation. Whether that is
an oversight or a decision is the panel's call, and it is worth answering before
this phase ships: if the module is deliberately hidden there, hiding it here
would be consistent, and if it is an oversight then both should link it.
