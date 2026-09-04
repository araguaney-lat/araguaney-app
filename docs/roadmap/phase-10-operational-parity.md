# Phase 10 — Operational parity backlog

> Long-term goal: everything the web dashboard does, the application does,
> minus what the offline boundary forbids. This phase is a **prioritized
> backlog, not a committed scope**: when a block is scheduled it gets split
> into its own phase with proper tasks, following the same rule the backend
> roadmap uses. Every item is online-only by the Phase 06 boundary.


> **Seven of these blocks graduated on 2026-08-24.** The backlog's own rule is
> that a block becomes its own phase when it is scheduled, and the parity review
> scheduled them: block 2 and 4 into [Phase 26](phase-26-shipment-to-delivery.md),
> block 3 into [Phase 27](phase-27-create-a-transfer.md), block 9 into
> [Phase 18](phase-18-preregistered-donations.md), block 12 into
> [Phase 19](phase-19-center-reports.md), block 13 into
> [Phase 23](phase-23-incidents-and-audit.md), and block 14 into
> [Phase 17](phase-17-product-catalogue.md).
>
> The rows stay here so the surface remains visible, and because the review also
> showed what this list never contained: the catalogue, campaigns, centres, the
> application queue, the audit log and the studio were absent from it entirely.
> See [parity with the panel](parity-with-the-panel.md).

---

---

## Objectives

1. Keep the candidate surface visible so nobody mistakes "not yet" for "never".
2. Split blocks into real phases only when they are prioritized.

## Non-objectives

- Committing dates or order today.
- Anything that writes offline beyond intake capture: that boundary is a domain rule.

---

## Candidate blocks

| # | Block | Description | Complexity | Status |
|---|-------|-------------|------------|--------|
| 1 | Pallet operations | Create and close pallets, add and remove sealed boxes by scan without leaving the camera, tare and gross weights. Online only, and coordination only — the server enforces both. | 🔴 High | ✅ Done |
| 2 | Shipment views and milestones | Reading the journey was done in Phase 15; **writing a milestone on 2026-08-25** ([Phase 26](phase-26-shipment-to-delivery.md)), from beside the truck. | 🟠 Medium | ✅ Done |
| 3 | Transfers | Participating in a transfer was done in Phase 10; **starting one on 2026-08-25** ([Phase 27](phase-27-create-a-transfer.md)), choosing the boxes by scanning them. All nine transfer routes are called now. | 🟠 Medium | ✅ Done |
| 4 | Reception and incidents | Reading a reception and raising incidents were done in Phases 15 and 23; **registering the reception on 2026-08-25** ([Phase 26](phase-26-shipment-to-delivery.md)), box by box. | 🟠 Medium | ✅ Done |
| 5 | Coordinator views | Resolving a risk review, the center's team directory, adding somebody to the center, resending an access, and moving people in and out of a campaign — everything scoped to the caller's own center, which the server enforces. **Reading the directory is open to the whole center**; managing it is not. | 🔴 High | ✅ Done |
| 6 | Aggregates for the home screen | `GET /v1/dashboard/national` needs only a center role and scopes itself to the caller's center; `GET /v1/dashboard/weight` is session-scoped too. **Unblocked on 2026-08-20**: the backend gave the untypeable QR route its own tag, and both are generated now. What remains is building the screen. **Done on 2026-08-20**: the home screen reads `centerAggregatesProvider` for the day's counts and the sealed weight, and «Stock por categoría» is its own screen. | 🟠 Medium | ✅ Done |
| 7 | Messaging / notification center | Threads, replies, marking read on open, and the unread counter on the home screen. Opening a campaign thread is included; **private threads and attachments are not** — see below. | 🟠 Medium | 🟨 Partial |
| 8 | Riverpod 3.x + codegen migration | Still blocked, and now verified rather than assumed — see below. | 🟠 Medium | 🚫 Blocked |
| 9 | Pre-registered donations | A donor registers online and arrives with a code. **Done on 2026-08-25** by [Phase 18](phase-18-preregistered-donations.md): the list, the record, receiving, the catalogue suggestions and the photos with their label reader. | 🔴 High | ✅ Done |
| 10 | Shipment workflow | The application reads a shipment and asks for its manifest; it cannot list shipments, create one, add or remove pallets, close, dispatch, or export the customs declaration. All of it is coordinator-level and already in the client.  **Promoted on 2026-08-22** to [Phase 15](phase-15-shipment-workflow.md), where its tasks live. | 🔴 High | ✅ Done |
| 11 | Profile and account security | Reading and editing the profile, changing the password on purpose rather than because the server forces it, enabling or disabling the second factor, accepting terms, the avatar, and recovering a forgotten password. Fifteen endpoints, none reached from the application. The design has the screen (Ajustes / Perfil).  **Promoted on 2026-08-21** to [Phase 14](phase-14-account-and-security.md), which is where its tasks live. | 🟠 Medium | ✅ Done |
| 12 | Reports for the center | Seven report routes answered and nothing called them. **Done on 2026-08-25** by [Phase 19](phase-19-center-reports.md): summary, shrinkage, by category, countries, activity, the weight dashboard and the CSV export. | 🟠 Medium | ✅ Done |
| 13 | Traceability and printed labels | `GET /v1/boxes/{id}/events` and `GET /v1/pallets/{id}/events` — the same timeline shipments already show, for the two objects an operator actually holds — plus the PDF labels for boxes and pallets, which today can only be printed from the web panel. **Half done on 2026-08-25**: [Phase 23](phase-23-incidents-and-audit.md) task 4 shipped both timelines through one shared widget, and the box label is on screen (`box_label_view.dart`, reachable from four places). **Still pending:** the PDF labels, `POST /v1/boxes/labels/pdf` and `POST /v1/pallets/{id}/label.pdf`, and the pallet label. | 🟢 Low | 🟨 Partial |
| 14 | Better search when capturing | `GET /v1/catalog/search`, `GET /v1/catalog/barcode/{gtin}` and `GET /v1/intakes/donors/search` exist and the capture form used none of them. **`catalog/barcode` on 2026-08-21** ([Phase 13](phase-13-product-barcode.md)); **product search on 2026-08-25** ([Phase 17](phase-17-product-catalogue.md)), through `/v1/product-types/search`. The donor search is still unused. | 🟢 Low | 🟨 Partial |

---

## What block 1 established for the blocks after it

Two pieces were built to be reused, not just to serve pallets:

- **`ContinuousScanView`** scans one label after another without closing the
  camera, and keeps a log of what the server said about each. Reception
  (block 4) is the same shape of work: someone with a stack in front of them and
  their hands full.
- **`ScannerCamera`** holds the camera, the torch and the denied-permission
  copy. Two screens scan today; the text a person reads when the camera is
  blocked has to be the same in both, and duplicating it guarantees that one day
  it will not be.

Also worth carrying forward: the weight discrepancy is computed and published by
the server, and shown here without adjectives. How much a difference matters is
a judgement that belongs to coordination, not to a colour in a mobile screen.

---

## What block 4 could not include, and why

The roadmap assumed the destination center registers what arrived. The backend
does not allow it: `POST /v1/shipments/{id}/reception` requires
`national_admin`. What a center coordinator can do is **read** the reception —
"le importa qué llegó de lo suyo", says the router — and **raise** incidents,
because the sending center is who notices something is missing.

So this block shipped what the application's actual audience can do, and
reconciliation is left as work for whoever builds a national administration
surface. It is not a small omission and it is not an oversight: a reconciliation
form on a phone, for a role that works from a desk, would have been screens
nobody opens.

Two properties of the backend model worth keeping if that form is ever built
here: **only exceptions travel** — whatever is not marked counts as received,
because shrinkage is the minority — and each exception opens its incident **on
the server**. The weight tolerance that decides whether a difference becomes an
incident lives there too, and the client must not learn it.

---

## What block 2 reads, and what it does not write

**Annotating a milestone is closed to national administration.**
`POST /v1/shipments/{id}/milestones` requires `national_admin`, the same shape
of limit reconciliation hit in block 4. What a center coordinator can do is
**read** the journey and **ask for the manifest**, and that is what shipped: a
timeline that puts state changes and logistics milestones in the same column,
because the question someone asks a shipment record is "where is it", not "which
of these two kinds of event moved it".

A milestone this build does not recognize is shown by its own code instead of
being dropped. The backend's vocabulary can grow — the contract is
additive — and an old binary must not make a shipment lose a step of its journey.

**The manifest is a job, not a file.** The endpoint answers with an export job
and the document is assembled elsewhere, so the client polls. Polling has a
bound: when it runs out the screen says the manifest is still being assembled
and to ask again, because the job stays alive on the server and a spinner with
no end is worse than a sentence. The bound is a client-side courtesy, not a
server limit, and it carries no information about the server's own timings.

---

## Two gaps block 3 leaves named

**Creating a transfer is not in the application.** It needs a destination center
and a selection of sealed boxes — desk work, and the part of the flow least
likely to happen on a phone. Participation, which is the roadmap's own word, is
what shipped.

**The application cannot name the other center.** `GET /v1/centers` requires
`national_admin`, and `TransferOut` carries only identifiers. So a transfer is
shown by direction — incoming or outgoing, which is the distinction a
coordinator actually works from — and the other center stays unnamed. Fixing it
properly means `TransferOut` carrying `from_center_name` and `to_center_name`,
which is a backend change — request 3 in
[`docs/backend-requests.md`](../backend-requests.md).

Also worth recording: the client mirrors the server's state machine to decide
which buttons to offer, and a test pins that table. It is duplication, chosen
knowingly over offering three buttons where two fail; the server still decides,
and its rejection is what the screen shows.

---

## What block 5 closed, and where it drew its lines

The block finished in two passes. Resolving a risk review came first, for the
reason below; the team surface came after, and it is what a coordinator
actually needs from a phone: someone shows up to help, and they have to exist
in the system and be in the campaign before they can capture anything.

**Reading the team is not a privilege.** `GET /v1/centers/{id}/users` is open to
anyone with a center role, so the directory is too: knowing who you work with
is not coordination. Adding somebody, resending an access and moving people in
and out of a campaign are coordination, and the server checks it on every call.

**The center is never chosen.** It is the one on the session. A national
administration belongs to no center, so the directory says so instead of asking
which center to look at — picking one is desk work, and this screen is for the
center you are standing in.

**Two refusals are shown before they happen**, on the same principle the
transfer buttons follow: the general campaign offers no way out of it, because
it is where everything without a campaign lands and the server answers 422; and
a disabled account offers no resend, because the server refuses that too.
Both still fail on the server if reached another way — the check here only
avoids promising something that cannot be delivered.

**One thing this block does that no other does: it writes its own copy for five
refusals.** The server answers `EMAIL_TAKEN`, `USERNAME_TAKEN`, `INVALID_ROLE`,
`ACCOUNT_DISABLED` and `PROTECTED_CAMPAIGN` in English, and the people who
operate read Spanish. Only business-rule refusals are rewritten, only for codes
listed by name, and anything else still shows what the server said. It is
presentation copy for a known code, not a second copy of a rule — but it is a
line worth watching: if that map grows past a handful of entries, the right fix
is Spanish messages from the backend, not a bigger dictionary here.

---

## Why resolving came before the rest of block 5

Phase 07 wired a notification that opens a risk review and lets someone read why
it was raised — and then stops. We built that dead end ourselves, and closing it
costs one endpoint.

The sheet shows the reason while the decision is being made, and offers reject
with the same visual weight as approve. Hiding the harder option behind an extra
step would make the difficult decision the uncomfortable one, and coordination
needs to be able to take it as fast as the easy one.

---

## What messaging left out, and one thing it revealed

**Private threads are not created from the phone.** Doing so means picking
recipients from among a campaign's members — a selection that belongs on a desk.
Reading and replying to a private thread works: what is missing is starting one.

**Attachments are not here either.** Uploading one needs a presigned URL, a file
picker and storage configured. The text arrives, which is what gets read and
answered from a phone; a thread that has attachments says so and points at the
web panel.

**And one thing worth deciding, not fixing quietly:** the server answers a
non-member trying to open a campaign thread with «No eres miembro de esta
campaña», and the application showed «No tienes permiso para hacer esta
operación» — the generic. Whether `ForbiddenFailure` should carry the server's
message is a decision about the Phase 02 policy, not about messaging.

**It was decided; see the section on refusals that name a rule below.** The
short version: the answer is not «echo the server's 403», and this particular
case still reads generic — because it is answered with the catch-all code.

---

## Refusals that name a rule

Reviewing every 403 the backend can answer turned the messaging question into a
different one. The message is not what separates a refusal worth reading from
one that is not: **the code is**.

The backend answers `FORBIDDEN` for a permission check — «this is not yours to
do» — and a code of its own when a specific rule refused: `SELF_REVIEW`,
`NOT_CAMPAIGN_MEMBER`, `ACCOUNT_DISABLED`, `EMAIL_NOT_VERIFIED`. The first kind
leaves nothing for the person to do but ask someone who can. The second names
something they can act on, and swallowing it turns an explanation into a wall.

So `ForbiddenFailure` now speaks when the code is one this build knows, with
copy this repository owns, and stays generic otherwise — including for a named
code it does not recognize, because the contract is additive and an old binary
cannot tell whether what arrived is fit to read. It never echoes the server's
403 text: those messages describe the check («This export job belongs to another
user»), sometimes in English, and are written for whoever reads a log.

Two refusals stopped being walls as a result, both in features already shipped:
resolving a review you opened yourself now says to escalate, and an offline
capture parked for a campaign you do not belong to now says to ask to be added —
which, since the previous block, is something a coordinator can do from the
phone.

The five business-rule refusals block 5 was rewriting in its own repository moved
into the same table, so there is one place that owns operator copy for named
codes instead of one per feature. It should stay small: request 6 in
[`docs/backend-requests.md`](../backend-requests.md) asks for those messages in
Spanish, and now also for the thread case to carry a code of its own instead of
the catch-all — the client cannot fix that one from here.

---

## Block 8 is blocked, and it was checked

The pin on Riverpod 2.6 was recorded as an assumption. It was resolved against
the actual solver: `riverpod >=3.0.0-dev` cannot coexist with `drift_dev`
and the `flutter_test` pins of the Flutter version this repository builds with —
a three-way conflict, not a matter of raising one bound. Nothing in the
application's own code stands in the way; the providers are already written by
hand and the migration is mechanical when the constraint clears.

Recording it here so the next person does not spend the same afternoon
discovering it: the check to repeat is bumping `riverpod` in `pubspec.yaml` and
reading what `flutter pub get` says. Until that resolves, the block is not
pending work — it is waiting on the ecosystem.

---

## What the backend offers and this application deliberately ignores

Reviewed route by route on 2026-08-20 against the backend's routers, so the next
person does not have to rediscover it:

- **Studio** (`/v1/studio/**`, `/v1/requests/**`) is a desk product with its own
  audience — needs matching, AI usage, audit, user administration. It requires
  `require_user_manager` or superadmin, and none of it belongs on a phone.
- **Center administration** (`/v1/centers`, `/v1/campaigns` write side,
  `/v1/product-types` write side, `/v1/incidents` global, center applications)
  is national administration or platform work, from a desk.
- **Email failures** (`get_current_superadmin`) is operations tooling.
- **The public donor flow** (`/v1/public/donations/**`, `/b/{code}`, `/d/{code}`,
  `/p/{code}`) is the website's, and the QR codes this application prints point
  at it on purpose.

Everything else a center role can call is either used already or listed as a
block above. There is no fifth category.

---

## Suggested order

Decided at prioritization time, block by block.
