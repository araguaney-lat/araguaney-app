# Phase 10 — Operational parity backlog

> Long-term goal: everything the web dashboard does, the application does,
> minus what the offline boundary forbids. This phase is a **prioritized
> backlog, not a committed scope**: when a block is scheduled it gets split
> into its own phase with proper tasks, following the same rule the backend
> roadmap uses. Every item is online-only by the Phase 06 boundary.

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
| 2 | Shipment views and milestones | Reading the journey — state changes and logistics milestones in one timeline — and asking for the manifest, which the server generates as a job. **Annotating a milestone requires national administration** and stays out; see below. | 🟠 Medium | 🟨 Partial |
| 3 | Transfers | Participating in a transfer: reading it, approving, rejecting with a reason, dispatching and receiving, each offered only where the server's machine allows it. **Creating one is not here** — see below. | 🟠 Medium | 🟨 Partial |
| 4 | Reception and incidents | Reading a reception with its shrinkage, and raising and listing incidents on a shipment — everything a center can do. **Reconciling is closed to national administration** and stays out; see below. | 🔴 High | 🟨 Partial |
| 5 | Coordinator views | Resolving a risk review, the center's team directory, adding somebody to the center, resending an access, and moving people in and out of a campaign — everything scoped to the caller's own center, which the server enforces. **Reading the directory is open to the whole center**; managing it is not. | 🔴 High | ✅ Done |
| 6 | National dashboard | Aggregated read-only views for national administrators. Reopening `/v1/dashboard/**` in the generated client means solving the `anyOf` response the generator cannot express today — request 5 in `docs/backend-requests.md`. | 🟠 Medium | ⬜ Pending |
| 7 | Messaging / notification center | Threads, replies, marking read on open, and the unread counter on the home screen. Opening a campaign thread is included; **private threads and attachments are not** — see below. | 🟠 Medium | 🟨 Partial |
| 8 | Riverpod 3.x + codegen migration | Still blocked, and now verified rather than assumed — see below. | 🟠 Medium | 🚫 Blocked |

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
campaña», and the application shows «No tienes permiso para hacer esta
operación». That is the Phase 02 policy working as designed — only business-rule
failures show the server's words, technical ones stay generic — but here the
generic costs something concrete: the server's sentence tells the person what to
ask for, and the generic one does not. Whether `ForbiddenFailure` should carry
the server's message is a decision about that policy, not about messaging.

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

## Suggested order

Decided at prioritization time, block by block.
