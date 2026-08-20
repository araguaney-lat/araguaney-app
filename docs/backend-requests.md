# What the mobile client needs from the backend

Five things this application cannot do because the `/v1` contract does not offer
them. Each was found while building a phase, and each is written here with what
it blocks and what the application does instead in the meantime — so that
whoever picks one up can judge whether it is worth doing, not just what to do.

Nothing here is urgent in the sense of broken. The application ships and works
without all five; what they change is how much of the operation it can cover and
how well it can explain itself.

These are requests, not decisions. The backend repository's roadmap is where
they become work, if they do.

---

## 1. Stock by category for the caller's center

**Blocks:** Phase 03, task 5 — the only task in that phase that never shipped.

`CategoryStockOut` and `CenterStockOut` exist, but only inside
`NationalDashboardOut` (a national aggregate) and the public campaign schemas.
`GET /v1/dashboard/weight` is session-scoped but answers a different question:
kilograms per campaign, not units per category.

**What the application does today:** nothing. The screen was not built, and the
roadmap says why.

**Why not compute it on the device:** summing `quantity` over cached boxes
grouped by category requires deciding which box statuses count as stock. That
rule lives in the backend, and a client copy of it would fork silently the day
it changed there.

**Shape that would work:** anything session-scoped returning category totals for
the caller's center — the same shape `CategoryStockOut` already has.

---

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

## 5. A single response schema for `GET /v1/public/qr/{code}`

**Blocks:** generating a client for the `dashboard` tag, which in turn blocks
Phase 10's national dashboard block.

That endpoint declares an `anyOf` response — box ficha or pallet ficha,
depending on the code. `swagger_parser` cannot express it: it emits a reference
to a sealed type it never generates, and the client stops compiling.

**What the application does today:** excludes the whole `dashboard` tag from
generation. Nothing under it is used — a scanned code resolves through the typed
box and pallet fichas — so the cost is deferred, not paid.

**Shape that would work:** one wrapper schema with a discriminator and both
shapes as optional members, instead of `anyOf` at the top level. The same
information, expressible by a code generator.

**Worth weighing:** this only matters when the mobile client needs
`/v1/dashboard/**`. If the national dashboard is never a mobile surface, the
exclusion can stay forever and this request can be closed.

---

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
