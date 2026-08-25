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
| 1 | Users repository | `GET /v1/studio/users`, `POST`, `PATCH` and the reinvite behind a sealed outcome. | 🟠 Medium | ⬜ Pending |
| 2 | Search across centres | For a session that can, with the centre named on every row. | 🟠 Medium | ⬜ Pending |
| 3 | The person's record | Centre, role, whether they ever signed in, whether their invitation is pending. | 🟠 Medium | ⬜ Pending |
| 4 | Resend an access | The operation that has a real case away from a desk. | 🟢 Low | ⬜ Pending |
| 5 | Invite beyond one centre | `POST /v1/studio/users`, for whoever manages users rather than a centre. | 🟠 Medium | ⬜ Pending |
| 6 | Verify on a device | With a real invitation that arrives. | 🟢 Low | ⬜ Pending |
