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

## 6. Operator-facing messages in Spanish for team errors

**Blocks:** nothing today. It removes copy the client should not be holding.

The team surface hits five refusals whose message reaches an operator directly:
`EMAIL_TAKEN`, `USERNAME_TAKEN`, `INVALID_ROLE`, `ACCOUNT_DISABLED` and
`PROTECTED_CAMPAIGN`. The server phrases them in English; the people who use
this application read Spanish.

**What the application does today:** rewrites those five, and only those five,
by code — business-rule refusals only, with the server's own message shown for
anything not on the list. It is presentation copy, not a duplicated rule, and
the roadmap records it as a line worth watching.

**Shape that would work:** those messages in Spanish, as the campaign endpoints
already answer («No eres miembro de esta campaña»). The client would then drop
its map and go back to showing the server's words for every business refusal.
Whether the backend answers in one language or negotiates it is a decision for
that side; either way the client stops holding copy.

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
