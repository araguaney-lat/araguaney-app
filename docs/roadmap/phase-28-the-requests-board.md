# Phase 28 — The requests board

> A centre says what it needs; the platform matches it against what exists. The
> routes answer, the panel has a page, and the panel does not offer it.

---

## The fact that decides this phase

`/dashboard/requests` is **commented out** in the web's own navigation
(`src/lib/nav-config.ts`). The page exists, six routes answer, and no link
reaches it.

So this is not a module the phone is missing relative to the panel. It is a
module the platform has not decided to ship. Building it here first would mean
this application shipping a product decision the panel has not made.

## What it is

`POST /v1/requests` takes a title and a description — plain words, not a form of
quantities. `GET /v1/requests/{id}/matches` runs the description through
`needs_matching`, which asks an AI which categories are being requested and what
stock exists for each, and **returns an empty list when the AI is unavailable**,
so the board keeps working without the shortcut.

There is a message thread per request, and a status a national administrator
moves.

## Why a phone would be good at it

Because the input is a sentence. «Nos quedamos sin suero» typed with one thumb
is a lower barrier than a form, and the person who knows what is missing is the
person on the floor, not the one at the desk.

That is the argument for building it, and it does not become valid until the
panel decides the board is live.

---

## The answer, and what it leaves open

Asked and answered on 2026-08-25: **build it**. The endpoints are live, the
panel's page exists, and the argument for the phone — the input is a sentence —
does not get better by waiting.

What the answer does not settle is the panel's navigation entry, which is still
commented out in `nav-config.ts` and belongs to the other repository. Until it
is uncommented, a request opened from a phone is answered from a phone: the
board works end to end here, and the panel's copy of it stays unreachable. That
is a one-line change over there and a decision for whoever owns it, not a gap in
this application.

## Objectives

1. Read the board and write on it from a phone.
2. Treat an empty matching as the normal answer it is.
3. Offer moving a request's state only to whoever the backend lets.

## Non-objectives

- Inventing a state machine. The four states are the server's and it decides
  which move it accepts; this offers the four and lets it refuse.
- Caching. A request is a conversation, and an old copy of a conversation
  invites replying to something already answered.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the state | Record that the board exists in the backend, has a page in the panel, and is not linked there. This file. | 🟢 Low | ✅ Done |
| 2 | Ask the other repository | Whether the board is unfinished, paused or abandoned. Until that is answered, nothing here is worth building. | 🟢 Low | ✅ Done — answered on 2026-08-25: build it. See below. |
| 3 | The list and the record | Only if the answer is «live». | 🟠 Medium | ✅ Done |
| 4 | Creating one | A sentence, and the matches the server returns for it — with the empty list treated as normal and not as a failure. | 🟠 Medium | ✅ Done |
| 5 | Verify on a device | Against a real request, a real reply, and the matching both on and off. | 🟢 Low | ⬜ Pending |

## Recorded for the other repository

Is `/dashboard/requests` paused or abandoned? The route, its six endpoints and
its AI matching all work; only the navigation entry is commented out.
