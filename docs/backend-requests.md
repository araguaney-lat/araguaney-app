# What the mobile client needs from the backend

Eight things this application cannot do because the `/v1` contract does not
offer them — three of which are now resolved and kept here for what they cost
while they were open. Each was found while building a phase, and each is written
here with what it blocks and what the application does instead in the meantime —
so that whoever picks one up can judge whether it is worth doing, not just what
to do.

Nothing here is urgent in the sense of broken. The application ships and works
without any of them; what they change is how much of the operation it can cover
and how well it can explain itself.

These are requests, not decisions. The backend repository's roadmap is where
they become work, if they do.

---

## 1. A stock reading, not a capture reading — **resolved, and it already existed**

**Closed on 2026-08-20 without the backend adding anything.** Kept here because
how it was missed is the useful part.

The request asked for a status filter so category totals would mean stock rather
than capture. `GET /v1/dashboard/national` already answered exactly that:
`AggregateRepository.stock_by_category` filters `Box.status == "SEALED"` and
`tenant_scope` narrows it to the caller's center. The client now uses it.

It was invisible for two compounding reasons. The route's name says *national*
while its scope is the caller's own center — so it read as somebody else's
screen. And it sat behind the `dashboard` tag exclusion, so it was not in the
generated client to be discovered by accident.

Two lessons worth more than the request: **a name that describes the largest
caller misleads every smaller one**, and **an exclusion hides what it excludes,
including the answer to a question asked later**. The route-by-route review that
found it is now a habit recorded in Phase 01.

## 2. `GET /v1/intakes/{id}`

**Blocks:** the natural destination of a `risk_review` notification.

A risk review notice carries `intake_id`, but a single intake cannot be fetched:
`GET /v1/intakes` lists, and there is no by-id route.

**What the application does today:** the notice opens the center's risk reviews
(`GET /v1/risk-reviews`) with the one whose intake matches highlighted. That is
a good destination — it is where the *reason* can be read, which the notice
deliberately withholds — but it is one step away from the capture that caused
it.

**Worth weighing:** if the review is the right place to land, this request can
be closed as unnecessary. The current behaviour is not a workaround anyone would
call wrong; it is just not the capture.

### The listing does not carry the boxes either

`IntakeOut.boxes` is declared with an empty list as its default and
`IntakeRepository.find_all` does not load the relation, so every intake in
`GET /v1/intakes` arrives with `boxes: []`. The capture record screen therefore
rendered a «Cajas» heading with nothing under it, and the list said «0 cajas» on
every row — a fabricated fact rather than a missing one, and the same failure
mode as the invented status and category labels: **the client filled a silence
with a value the server never sent.**

The application now says so instead of counting: the row omits the count and the
record explains that the history does not carry the boxes. Either of two server
changes closes it — a by-id route that loads them, or a box count on the listing
— and the second is cheaper if the record is going to fetch by id anyway.

---

## 3. Center names on `TransferOut`

**Blocks:** naming the other center in a transfer.

`TransferOut` carries `from_center_id` and `to_center_id`, and `GET /v1/centers`
requires `national_admin`. A center coordinator therefore has no way to turn
either identifier into a name.

**What the application does today:** shows the **direction** — incoming or
outgoing — which is the distinction a coordinator works from, and leaves the
other center unnamed. Showing a raw UUID to someone on a loading dock would be
worse than showing nothing.

**Shape that would work:** `from_center_name` and `to_center_name` on
`TransferOut` and `TransferDetailOut`. Additive, and it does not widen who can
list centers.

---

## 4. A typed body for `POST /v1/pallets/{id}/add-box`

**Blocks:** nothing. It is a small correctness improvement.

The contract declares that request body as a free-form object
(`additionalProperties: true`), so the generated client takes `dynamic`. The key
the router reads is `code`, which this repository learned by reading
`pallet.py` rather than the contract.

**What the application does today:** writes `{'code': …}` by hand, with a test
that pins it so a drift in the backend shows up as a red test rather than a
silent failure in a warehouse.

**Shape that would work:** any declared schema with `code`. The generated client
would then carry the key, and the hand-written map and its test could go.

---

## 5. A response schema for `GET /v1/public/qr/{code}` — **resolved**

**Delivered on 2026-08-20**, and kept here rather than deleted: what it cost
while it was open is the useful part.

The route answers a box or a pallet and declares its shapes through `responses`
rather than a `response_model`, which the generator cannot express. The client's
only lever is excluding a tag — and the route shared `dashboard`, so excluding it
also removed `GET /v1/dashboard/national` and `GET /v1/dashboard/weight`, which
need only a center role and narrow themselves to the caller's own center. Six
routes were lost to avoid one, in a repository that showed no sign of it.

The backend moved the route to its own tag (`qr`). Note for anyone attempting
something similar: **FastAPI appends a route's tags to its router's tags**, so a
`tags=` on the decorator is not enough — the route keeps the inherited one. It
took a separate router.

This repository now excludes `qr` instead, and `DashboardApi` is generated with
`NationalDashboardOut` and `WeightDashboardOut` typed. `GET
/v1/dashboard/national/summary` still generates as `dynamic`, which is harmless:
it requires national administration and this application does not call it.

## 6. Named codes and Spanish messages for refusals an operator reads

**Blocks:** nothing today. It removes copy the client should not be holding, and
unblocks one refusal the client cannot improve on its own.

Two halves of the same request.

**(a) A code of its own where the refusal is actionable.** The application shows
the reason for a 403 only when the backend names the rule with a specific code —
`SELF_REVIEW`, `NOT_CAMPAIGN_MEMBER` — and stays generic for the catch-all
`FORBIDDEN`, whose message describes the check («This export job belongs to
another user») rather than the remedy. Some refusals that *are* actionable use
the catch-all anyway, and the clearest is opening a campaign thread as a
non-member: «No eres miembro de esta campaña» tells the person exactly what to
ask for, and the application cannot show it, because from the outside it is
indistinguishable from every other `FORBIDDEN`. A code —
`NOT_CAMPAIGN_MEMBER` already exists for the same idea in intake — would be
enough. Same for `NOT_THREAD_PARTICIPANT`.

**(b) Those messages in Spanish.** Nine codes reach an operator directly today:
`EMAIL_TAKEN`, `USERNAME_TAKEN`, `INVALID_ROLE`, `PROTECTED_CAMPAIGN`,
`ACCOUNT_DISABLED`, `EMAIL_NOT_VERIFIED`, `NOT_CAMPAIGN_MEMBER`, `SELF_REVIEW`
and the thread case above. Several are phrased in English; the people who use
this application read Spanish.

**What the application does today:** owns Spanish copy for the named codes it
knows, in one table in `lib/core/api/refusal_copy.dart`, and shows the server's
own message for every other business refusal. A named code it does not
recognize stays generic — safer than echoing something that may be English or
written for a log.

**Shape that would work:** actionable refusals carrying their own code, and
those messages answered in Spanish, as the campaign endpoints already do. The
client would drop the table and go back to showing the server's words. Whether
the backend answers in one language or negotiates it is a decision for that
side; either way the client stops holding copy.

---

## 7. Identity fields on `POST /v1/auth/refresh`

**Blocks:** nothing now — the client works around it with an extra request.

`POST /v1/auth/login` answers with `role`, `center_id` and `center_role`
alongside the tokens. `POST /v1/auth/refresh` answers with the tokens alone,
although the access token it mints carries those same claims inside.

That asymmetry has a cost, and it went unnoticed for months. Restoring a session
when the application opens goes through refresh, so every restart produced a
session with no role: a center coordinator came back as a volunteer — without
the actions their role allows, and without the screens that check for it — until
they signed out and in again. Nothing failed loudly, because the server still
enforced everything correctly; only the client's idea of who was using it was
wrong.

**What the application does today:** when a token arrives without
`center_role`, it asks `GET /v1/auth/me` and fills the gap. On failure the
session opens with no role at all, which offers less rather than more.

**Shape that would work:** the same three fields on the refresh response that
login already returns. The client would drop the extra call, and one request
would disappear from every cold start on a connection that cannot spare it.

---

## 8. Real values on `GET /v1/client/version` — **not a request; it is our step**

**Closed on 2026-08-24 without the backend adding anything.** Kept here because
how it was miscast is the useful part.

It was written as a gap: the route answers `{"min_supported":"0.0.0",
"latest":"0.0.0"}`, both placeholders, so the gate wired in Phase 29 evaluates to
«current» for every build that has ever existed.

That is all true and none of it is the backend's to fix. The values live in the
backend's **environment**, deliberately — `MIN_SUPPORTED_CLIENT_VERSION` and
`LATEST_CLIENT_VERSION`, set by whoever operates it when a version of this
application is published. And that repository already carries a runbook for
exactly this decision, `docs/flujo/version-minima-del-cliente.md`, which is more
careful than the request was:

- Raise `LATEST_CLIENT_VERSION` **when the version is downloadable**, not when it
  is submitted, so nobody goes looking for a button that is not there.
- Raise `MIN_SUPPORTED_CLIENT_VERSION` **only when an old version would produce
  incorrect data** — never to push adoption, which is what `latest` is for.
- Both being `0.0.0` is described there as the correct state until there is a
  published application. Which there was not, until now.

So the step belongs to this repository's release checklist, not to a backend
roadmap. It is recorded in
[`docs/release/android.md`](release/android.md#after-publishing-a-version).

**The lesson, which is the third time in a week:** what looked like a missing
capability was a capability whose documentation nobody had read. The same shape
as request 1, where the endpoint already existed, and as the barcode search
routes that Phase 10 listed as unused for months.

---

## 9. A `center_id` filter on the list endpoints

**What we need.** `GET /v1/boxes`, `/v1/pallets`, `/v1/shipments` and
`/v1/intakes` accept an optional `center_id` query parameter, scoped the way
`/v1/transfers` already scopes `from_center_id`: a national administrator may
name any centre, everybody else is ignored as they are today.

**Why.** `tenant_scope` returns `None` for a `national_admin`, so those
endpoints answer with every centre's rows. Since [Phase
30](roadmap/phase-30-writing-as-national-admin.md) the application writes into a
chosen working centre, and it narrows the lists to that centre **after** the
response arrives. That is correct on screen and wrong on the wire:

- The cached box window is the first 500 rows the server returns, in its order.
  For a national session those 500 are spread across the country, so the working
  centre's offline window is a fraction of what a coordinator gets on the same
  device — and offline reading of the boxes is the point of the cache.
- Rows for centres nobody asked about travel over a phone connection in a
  warehouse.

**What we do meanwhile.** Filter client-side. Every one of those read models
already carries its centre, so nothing is guessed; it is only wasteful.

**Not urgent.** It costs bandwidth and offline depth, not correctness.

---

## 10. A question, not a request: the donor on `DonationOut`

**What we noticed.** `DonationOut` publishes the code, the status, the declared
items, the photos and the centres. It publishes **nothing about who donated**,
although `Donation` has the relationship and loads it eagerly.

**Why it is a question.** The panel's own reception screen shows no donor
either, so the two clients agree; this is what the endpoint serves. And
`DonationPublicOut` is documented as «sin un solo dato del donante» for the
public QR, which reads like a deliberate line — but that schema is the public
one, and this is the centre-facing one.

**What we would use it for.** Confirming at the door that the person handing
over the boxes is the one who announced them. Today the code is the only thing
that matches, which is probably enough.

**Not a request.** If the omission is deliberate, this application is fine as it
is: [Phase 18](roadmap/phase-18-preregistered-donations.md) ships without it and
says so. Asking loudly for personal data that somebody chose to withhold would
be the wrong move; asking whether it was a choice is not.

---

## 11. `entity_id` on the audit log, and who may read it

**What we need.** Two changes to `GET /v1/studio/audit`, and the second one is a
decision rather than a line of code:

1. An optional `entity_id` filter, so «what happened to this box» is one query
   instead of paging through every entry of its type.
2. A way for a coordinator to read the audit of objects **in their own centre**.
   Today the endpoint requires `require_user_manager`: the platform or national
   operation.

**Why.** [Phase 23](roadmap/phase-23-incidents-and-audit.md) wanted to answer
«who did this» as a line on the record of the object somebody is holding — the
question asked at bad moments, in a warehouse, by whoever is holding the box.
That person is a coordinator or a volunteer, and the log is closed to them.

**Why the second point is a decision.** An audit log is not inventory: it names
people and what they did, and opening it more widely is a privacy call, not a
convenience. A narrower version would be enough for us — the actor's **name**
on operational events for objects of one's own centre, without the rest of the
log.

**What we do meanwhile.** Nothing, and the phase says so. The box, pallet and
shipment timelines already answer the operational half — when it was sealed,
when it moved — from `/events`, which any centre role can read. The task is
marked blocked rather than half-built: a screen that shows «who did this» for
one role and an empty space for the others would be worse than not offering it.

---

## 12. A `q` on `GET /v1/studio/users`

**What we need.** An optional `q` that matches full name, username and email,
the way `/v1/product-types/search` already does for the catalogue.

**Why.** The endpoint filters by centre, role and state, and pages. Finding «Ana»
therefore means either knowing her centre or paging until she appears. On a
phone, that is the difference between a screen somebody uses and one they open
once.

**What we do meanwhile.** The list filters what has already been loaded and
**says that is what it does** — the field is labelled «Filtrar lo cargado» and
the empty state reports how many rows it looked at. It is honest and it is not
a search.

**Not urgent.** It is a convenience, not a correctness problem; nothing is
hidden and nothing is claimed that is not true.

---

## Not requests

Recorded here so they are not mistaken for gaps:

- **`POST /v1/auth/login` returning two shapes** (`Token` on 200, `TotpPending`
  on 202) is correct and cannot be typed by a generated client, which is why
  that one call is written by hand. Nothing to fix.
- **Reconciling a reception requiring `national_admin`** is a decision, not an
  omission. The application ships what a center can do — reading the reception,
  raising incidents — and says so.
- **Message notifications not being wired** is a pending decision in the backend
  about a rule that does not teach people to silence everything. The client is
  ready for a new `kind`: an unknown one is displayed and simply does not
  navigate.
