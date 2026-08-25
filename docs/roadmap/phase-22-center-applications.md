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

## What approving actually does, and why the screen says it

`CenterApplicationService.approve` does three things in one call:

1. Creates the centre.
2. Registers the applicant as its **coordinator**, with a generated password and
   `must_change_password` set.
3. Emails them that password.

None of it can be undone from here, and two of the three are invisible from the
name of the button. So the confirmation names all three and says where the
password is going. A dialog that only asks «¿seguro?» informs nobody, and this
is the screen where being wrong creates an account for a stranger.

It also refuses, usefully, when a user already exists with that contact address
— the service says so rather than guessing, and the message reaches the person
deciding.

## The queue is a queue, not a history

`list_queue` filters `PENDING_REVIEW`, oldest first, and scopes by country for a
national administrator while a superadministrator sees every country. Deciding
one takes it out. So there is no «already resolved» section to build, and the
count in the header is the whole of what is waiting.

## Everything the decision rests on is on the card

Centre, place, contact, phone, address, backing organisation, links and the
message they wrote. Making somebody open a record to find out who backs a centre
turns a queue of three into three navigations, and the fields are short enough
to fit.

**The message is quoted and unedited**, like the reason on a risk review: they
are the applicant's words, and paraphrasing them would put this repository
between two people who are trying to evaluate each other.

## Rejecting is not the second button

`POST .../reject` carries a reason, and the reason **is emailed to whoever
applied** — outside the platform, probably with no other context than that
sentence. So the sheet says where the text is going before anybody starts
typing, and the field is required here as well as on the server: reaching the
server to be told would spend a request and a wait for something already known.

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
| 1 | Applications repository | The queue and the two decisions behind a sealed outcome that reads a 403 as an answer. | 🟠 Medium | ✅ Done |
| 2 | The queue | Who is waiting and since when, with the count in the header and pull to refresh. | 🟠 Medium | ✅ Done |
| 3 | The application on the card | Everything the decision rests on, without a second navigation, omitting what the response does not carry. The message quoted and unedited. | 🟠 Medium | ✅ Done |
| 4 | Approve | Names its three consequences before doing them — the centre, the coordinator account, and the password that is emailed — because none is undoable from here. | 🟠 Medium | ✅ Done |
| 5 | Reject with a reason | A sheet that says the reason is emailed to the applicant, and refuses to send an empty one. | 🟠 Medium | ✅ Done |
| 6 | Verify on a device | Against a real application. **Approving writes to production**, so it waits for one that is genuinely meant to be approved. | 🟢 Low | ⬜ Pending |
