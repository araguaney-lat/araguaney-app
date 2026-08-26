# Phase 24 — Users beyond one centre

> The team directory manages the people of one centre. The panel has a Users
> module for administration that reaches all of them, and its routes live under
> `/v1/studio`.

---

## What already works, and where it stops

`POST /v1/centers/{center_id}/users` and its reinvite are called: a coordinator
can invite somebody to their own centre and resend an access. That covers a
centre.

It stops at two edges. A coordinator cannot see anybody outside their centre —
correct, and enforced by the server. And a national administrator, who can,
has no screen for it: `GET /v1/studio/users`, `POST /v1/studio/users`,
`PATCH /v1/studio/users/{id}` and its reinvite are all unused.

## `require_user_manager` is not `superadmin`

Worth stating because it decides whether this phase belongs to Phase 25 instead.
The studio's user routes are guarded by `require_user_manager`, which is a
narrower gate than the console's own `get_current_superadmin`. Users are
therefore administration, not studio, even though the routes share a prefix.

That is also why the panel shows «Usuarios» under Dashboard → administration and
again inside the studio: same data, two audiences.

## What a phone should be able to do

Inviting somebody is the operation with a real mobile case: a person turns up to
volunteer, and the coordinator has a phone in their hand. That already works for
a centre.

Beyond that, the honest scope is reading and one correction. Changing somebody's
role is a decision with consequences that outlive the moment, and doing it from
a phone between two pallets is not obviously better than doing it from a desk.

---

## Objectives

1. Find a person across centres, for whoever is allowed.
2. Read what they are: centre, role, state of their invitation.
3. Resend an access that never arrived.

## Non-objectives

- Deleting accounts. `DELETE /v1/auth/me` exists for the account's own owner and
  the panel does not offer administrative deletion either.
- Making role changes a routine mobile operation.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Users repository | `GET /v1/studio/users`, `POST` and the reinvite behind a sealed outcome. `PATCH` deliberately not wired — see below. | 🟠 Medium | ✅ Done |
| 2 | Search across centres | **The endpoint does not search.** Filters by centre, role and state, plus a text box that narrows what was loaded and says so. | 🟠 Medium | 🟨 Partial |
| 3 | The person's record | Centre, role, whether the second factor is on, whether the terms are still pending. | 🟠 Medium | ✅ Done |
| 4 | Resend an access | The operation that has a real case away from a desk. | 🟢 Low | ✅ Done |
| 5 | Invite beyond one centre | `POST /v1/studio/users`, with the centre chosen rather than assumed. | 🟠 Medium | ✅ Done |
| 6 | Verify on a device | With a real invitation that arrives. | 🟢 Low | ⬜ Pending |

## «Search» was the wrong word, and the screen says the right one

`GET /v1/studio/users` takes `center_id`, `center_role`, `is_active`, `limit`
and `offset`. **There is no `q`.** So the phase's task 2 could not be built as
written, and the honest version is two different things on one screen:

- the filters the server understands, which narrow what is asked for;
- a text box that narrows **what already arrived**, labelled «Filtrar lo
  cargado» and with a line underneath saying exactly that.

Calling it «buscar» would make a name that does not appear look like a person
who does not exist, when they may be on the next page. When the text matches
nothing, the screen says how many rows it looked at.

Recorded as request 12: a `q` over name, username and email would make this a
search and let the label be honest in one word.

## What was left out, and why it is not dead code

`PATCH /v1/studio/users/{id}` can change somebody's role, centre and whether
their account is active. It is not in the repository at all.

The phase's own non-objective says role changes should not become a routine
mobile operation, and the reason holds: a decision whose consequences outlive
the moment is not better made between two pallets. Writing the method «because
it exists» would have left an untested call nobody uses, which is the shape
dead code takes when it is added early.

## The password never exists here

`StudioUserCreate` has a `password` field and this application never fills it.
The server generates one and emails it; a client that never touches it cannot
leak it. The record says so out loud, on the screen where somebody might go
looking for one.
