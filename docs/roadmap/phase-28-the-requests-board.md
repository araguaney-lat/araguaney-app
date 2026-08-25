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

## Objectives

1. Nothing yet. This phase waits on a decision in the other repository.

## Non-objectives

- Building it before the panel offers it.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the state | Record that the board exists in the backend, has a page in the panel, and is not linked there. This file. | 🟢 Low | ✅ Done |
| 2 | Ask the other repository | Whether the board is unfinished, paused or abandoned. Until that is answered, nothing here is worth building. | 🟢 Low | ⬜ Pending |
| 3 | The list and the record | Only if the answer is «live». | 🟠 Medium | ⬜ Pending |
| 4 | Creating one | A sentence, and the matches the server returns for it — with the empty list treated as normal and not as a failure. | 🟠 Medium | ⬜ Pending |

## Recorded for the other repository

Is `/dashboard/requests` paused or abandoned? The route, its six endpoints and
its AI matching all work; only the navigation entry is commented out.
