# Phase 32 — The commentary in English

> 2,697 of this repository's 3,349 comment lines are in Spanish. No identifier
> ever was. The gap is entirely the prose, and it is the prose that is worth
> the most.

---

## What is actually inconsistent

The rule in `CLAUDE.md` splits three ways: identifiers in English, repository
documentation in English, and *prosa de producto* in Spanish. Comments were
never named, and they drifted to Spanish along with the interface they describe.

That drift is now the only Spanish left in the code:

| | |
|---|---|
| Identifiers in Spanish | **0** |
| Documentation under `docs/` | already English |
| ARB keys and descriptions | English, since Phase 31 |
| **Comment lines in Spanish** | **2,697 of 3,349, across 235 files** |

## Why this is not a mechanical pass

These comments are the most carefully written text in the repository. They do
not describe what the code does — the code does that. They record **why**, and
usually why something obvious was not done:

> *«El motivo es del servidor: que la caja no está sellada, que ya está en otra
> tarima, que es de otro centro. Traducirlo aquí sería mantener dos versiones de
> la misma regla.»*

A translation that keeps the sentence and loses the argument turns that into
noise. Somebody has to read each one and decide what it was saying, which is
slow and cannot be scripted — a machine pass over 2,697 lines would produce
2,697 lines that look like comments and stop being reasons.

## Why it is its own pull request

Two directions, and both matter.

**A comment translation hides logic.** Mixed into a change that touches
behaviour, the diff is thousands of lines of prose with a few lines of code
inside it, and the code is what needed reviewing.

**And logic hides a comment translation.** A pure-comment pull request can be
verified mechanically — «does this diff touch anything that is not a comment?»
is a question with a yes-or-no answer, and that is a much stronger guarantee
than reading it.

So this phase changes no code. If a comment turns out to be wrong while it is
being translated — and some will, because reading 2,697 explanations carefully
is the best defect hunt this repository has had — the fix goes in its own
commit, named as a fix.

---

## Objectives

1. No Spanish left in the code, comments included.
2. The reasoning survives the translation.
3. A diff that can be checked to touch only comments.

## Non-objectives

- Changing behaviour. Anything found gets its own commit.
- `CLAUDE.md`, which stays Spanish by its author's decision for now.
- Interface text, which is a translation problem and not a code one —
  [Phase 31](phase-31-internationalisation.md).

---

## How to do it without ruining it

**By feature, not by file count.** A feature's comments argue with each other:
the offline queue's four invariants are explained across five files, and
translating one without the others produces four English sentences that no
longer agree.

**Read for the argument, not the sentence.** Where a comment says «esto sería»
it is rejecting an alternative, and the English has to reject it too. The
repository's recurring lines — that the client must not fill a silence, that a
value the client invents fails silently, that a table hidden in one screen
leaves the others speaking the backend's language — are the same argument in six
places and should read like it.

**Keep the quotations.** Several comments quote what the server says or what a
person would say. Those stay as they are; they are evidence, not prose.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the gap | Record what is inconsistent, how much of it there is, and why it is not a script. This file. | 🟢 Low | ✅ Done |
| 2 | `lib/core` | The layer everything else reads: the failure taxonomy, the queue, the theme, the session. Its comments are the ones most often quoted by the others. | 🔴 High | ✅ Done |
| 3 | `lib/features`, by feature | Capture and its queue first — the four invariants are the densest reasoning here. | 🔴 High | ✅ Done |
| 4 | `test/` | Test names are already English; their comments are not, and they carry the reason a test exists, which is usually a defect somebody once shipped. | 🟠 Medium | ✅ Done |
| 5 | Update the rule | `CLAUDE.md` says prose for contributors is English and product prose is Spanish. Comments belong to the first and should be named there. | 🟢 Low | ✅ Done |
| 6 | A check that keeps it | Something in CI that fails on a Spanish comment, so the drift cannot happen twice. | 🟠 Medium | ✅ Done — `test/core/i18n/comments_in_english_test.dart`, a ratchet: the list of files with Spanish can only shrink, and CI runs it with the rest of the suite. |

## Task 6 is the one that matters afterwards

Everything above is paid once. Without a check, the same 2,697 lines come back
one comment at a time, and the next person to notice will be looking at a number
this size again.

Something as crude as a diacritic-and-stopword scan over changed lines would
catch nearly all of it — it is what measured the problem in the first place, and
its false positives are English sentences containing the word «no», which are
cheap to allow.
