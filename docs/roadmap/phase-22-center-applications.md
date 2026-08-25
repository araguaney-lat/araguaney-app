# Phase 22 — The centre application queue

> Phase 16 gave somebody without a centre a link to the public form. This is the
> other end of that link: the queue where a person decides.

---

## Why the two halves ended up apart

The sign-in screen now points at `araguaney.lat/registrar-centro`, because a
centre that is not on the platform had nowhere to go. What happens to that form
afterwards — somebody reads it, checks the backing organisation, approves or
rejects — has a screen in the panel and none here.

So this application opened a door and cannot answer it.

## Who decides, and what that means for scope

`require_application_reviewer` accepts a `national_admin` scoped to their own
country, or a `superadmin` who sees all of them. It is a small audience by
design: this is not a screen for a centre, it is a screen for whoever admits
centres.

That makes it a candidate for **not** building — except for one thing. An
application waits on a person, and the cost of it waiting is a centre that
cannot start operating. A queue whose whole purpose is not to stall is exactly
the kind of thing worth having on a phone.

## Rejecting takes a reason, and the reason travels

`POST /v1/center-applications/{app_id}/reject` carries one, and it reaches the
person who applied by email. So this is not a two-button screen: it is a screen
where one of the buttons opens a text field whose content somebody outside the
platform is going to read.

The same shape as resolving a risk review, and worth reusing rather than
reinventing.

---

## Objectives

1. Read the queue, and one application in full.
2. Approve, which creates a centre.
3. Reject with a reason written for the person who will read it.

## Non-objectives

- Submitting an application. That is the public web's form, and Phase 16
  explains why it stays there.
- Editing an application before deciding on it.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Applications repository | `GET /v1/center-applications` and the two decisions, behind a sealed outcome. | 🟠 Medium | ⬜ Pending |
| 2 | The queue | Who is waiting and since when, with the count that says whether anything needs a person. | 🟠 Medium | ⬜ Pending |
| 3 | The application | Centre, place, contact, backing organisation, links and the message they wrote — everything the decision rests on. | 🟠 Medium | ⬜ Pending |
| 4 | Approve | Creates a centre; the screen says so before it happens, because it is not undoable from here. | 🟠 Medium | ⬜ Pending |
| 5 | Reject with a reason | The sheet that already exists for risk reviews, with copy that says the reason will be read by the applicant. | 🟠 Medium | ⬜ Pending |
| 6 | Verify on a device | Against a real application, on a staging centre if one exists. | 🟢 Low | ⬜ Pending |
