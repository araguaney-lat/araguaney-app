# Phase 25 — The studio

> The panel has a superadmin console with seven screens. This application knows
> the routes exist and calls none of them.

---

## The one phase whose answer might be «no»

Every other missing module in [the parity review](parity-with-the-panel.md)
has an argument for a phone: somebody is standing somewhere holding something.
The studio is the opposite. It is metrics, AI usage, email failures, the audit
log and platform settings — the screens somebody opens with a keyboard, coffee
and time.

Writing it down as a phase does not mean building it. It means the decision
stops being an omission and becomes a decision.

## What is in it, and which parts have a mobile case

| Studio screen | Routes | Worth a phone? |
|---|---|---|
| Metrics | the studio root | No. A dashboard read at a desk. |
| Users | `/v1/studio/users` and friends | **Already its own phase** — see [Phase 24](phase-24-users-beyond-a-center.md), because `require_user_manager` is a narrower gate than the console's. |
| Applications | `/v1/center-applications` | **Already its own phase** — [Phase 22](phase-22-center-applications.md). A queue that stalls costs a centre its start. |
| Emails | `GET /v1/email-failures`, resend | **Maybe.** An invitation that never arrived is somebody blocked right now, and resending is one tap. |
| AI usage | `GET /v1/studio/ai-usage` | No. |
| Audit | `GET /v1/studio/audit` | **Partly** — as a line on a record, which is [Phase 23](phase-23-incidents-and-audit.md), not as a browser. |
| Settings | platform configuration | No, and arguably never: configuration changed from a phone is configuration changed by accident. |

Read that table twice and the phase mostly dissolves, which is the point. Three
of its seven screens already have better homes elsewhere, three have no mobile
case at all, and one — email failures — is a single useful action.

## What is left, then

`POST /v1/studio/product-types/{pt_id}/promote` is the odd one: promotion also
exists at `/v1/product-types/{pt_id}/promote`, and [Phase 17](phase-17-product-catalogue.md)
takes it there. Two routes for the same act, one under each audience.

So this phase reduces to the email failures inbox and a written decision about
the rest.

---

## Objectives

1. Resend an access or a notice that failed to send.
2. Record, in writing, that the rest of the studio is not coming to the phone
   and why.

## Non-objectives

- Metrics, AI usage and platform settings on a phone.
- A second home for users, applications and audit, which have phases of their
  own.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Decide the shape | This file. Three studio screens belong to other phases, three have no mobile case, one does. | 🟢 Low | ✅ Done |
| 2 | Email failures | `GET /v1/email-failures` and `POST /v1/email-failures/{id}/resend`: who did not receive what, and one tap to try again. | 🟠 Medium | ⬜ Pending |
| 3 | Verify on a device | Against a failure that a resend actually fixes. | 🟢 Low | ⬜ Pending |
