# Phase 31 — Speaking more than one language

> The application was written in Spanish on purpose, and the rule that said so
> also said what it would take to change: «mover los textos a `app_es.arb` es
> una fase, no una nota al pie». This is that phase.

---

## What changed, and why now rather than later

`CLAUDE.md` justified Spanish-in-the-widget with a condition — *no hay un
segundo idioma de operación que sostener* — and Araguaney is going to have one.
So the condition expired, and the rule with it.

The obvious plan was to build the remaining phases first and translate at the
end, when the application is finished. **The two halves of this work age in
opposite directions**, which is what settled it:

- **Writing translations is cheap and stays cheap.** 457 strings cost the same
  to translate in March as today.
- **Extracting them, and threading `AppLocalizations` through everything that
  produces text, is the expensive half and it grows with every screen built.**
  `operatorMessage` had 73 call sites; eight phases from now it would have
  half again as many.

So the extraction happened now and the translations wait. There is also a
history in this repository that argued for not deferring: the version gate sat
written and unwired for six phases, and the screen list stayed incomplete
because nobody derived it. «Later, when the application is complete» is the
sentence that preceded both.

## Only Spanish is declared, deliberately

`app_es.arb` is the only ARB in the repository, so `supportedLocales` is
`[es]` and the system resolves to Spanish whatever the phone says. **Nothing
looks half-translated because nothing else is offered.**

The day a second language is ready, it is one file and one line. That is the
whole point of doing the expensive half first.

## What this cost, structurally

Anything that produces text a person reads now receives the language. The
layers that cannot hold a `BuildContext` stopped producing sentences and started
producing facts:

| Was | Is |
|---|---|
| `ApiFailure.operatorMessage` getter | a method taking `AppLocalizations` |
| `SessionAbsent(failureMessage: String)` | `SessionAbsent(failure: ApiFailure)` |
| `TeamChanged(notice: String)` | `TeamChanged(notice: TeamNotice)` |
| `ManifestFailed(String)` | the failure, and separately what the server said |
| Seven status tables returning Spanish | the same tables taking the language |
| A form enum holding labels as constants | an enum resolving its label when drawn |

`context.l10n` rather than `AppLocalizations.of(context)!` at the call sites.
That is not sugar: declaring a local inside an arrow function means converting
its body, and a third of these call sites are arrow functions.

## Three things the work turned up

**A pallet `CLOSED` and a shipment `CLOSED` differ in Spanish and Portuguese and
coincide in English.** «Cerrada» and «cerrado». One shared status table would
have looked correct right up until the first translation, which is the argument
for a table per object even where the words repeat.

**Translating the event timeline exposed an invented fixture.** The test pinned
`'CLOSED → IN_TRANSIT'`, which was wrong twice: a raw key is not something a
person should read, and `IN_TRANSIT` is not a shipment status at all — it
belongs to transfers. Nobody could have seen it while the keys were printed raw.

**Counts were Spanish grammar written in Dart.** Every `n == 1 ? 'caja' :
'cajas'` encodes a rule that Portuguese happens to share, English happens to
share, and Russian does not. They are ICU plurals now, where a translator can
change the rule without touching code.

## What is stored is not what is shown

The offline queue kept the rendered sentence of a refusal. It keeps the
server's own words alongside the code now, and the screen resolves the code
against the copy table when it knows it.

**What is written to the database is read days later, possibly with the
application in another language.** Writing today's rendering into a row would
freeze a language in there.

## Diagnostics are not translated

Exception messages, asserts and log lines are English. Nobody operating sees
them; they go to Sentry, and Sentry is read by whoever wrote them. Translating a
log is work that helps nobody and hides the string you are searching for.

---

## Objectives

1. Every string a person reads comes from a key.
2. Adding a language is a file, not a migration.
3. Nothing is offered half-translated.

## Non-objectives

- English and Portuguese themselves. See the tasks below.
- The Spanish comments in the code, which are a phase of their own —
  [Phase 32](phase-32-comments-in-english.md).
- `CLAUDE.md`, which stays in Spanish by its author's decision for now.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | The machinery | `app_es.arb`, `flutter gen-l10n`, the `context.l10n` extension, and `MaterialApp` no longer pinning a locale. | 🟠 Medium | ✅ Done |
| 2 | The shared vocabulary | Seven status tables, categories, milestones, incident types, roles and thread types, all taking the language. | 🟠 Medium | ✅ Done |
| 3 | Failures and refusals | `operatorMessage` as a method, and the layers with no context carrying facts instead of sentences. | 🔴 High | ✅ Done |
| 4 | The screen strings | 457 keys, including the ones that interpolate and the counts, which are ICU plurals. | 🔴 High | ✅ Done |
| 5 | Keys and descriptions in English | Named for what the string does rather than derived from the sentence, which stops describing its value the moment the sentence is edited. | 🟠 Medium | ✅ Done |
| 6 | `app_en.arb` | The 717 strings in English, complete before the locale was declared. | 🔴 High | ✅ Done |
| 7 | `app_pt.arb` | **Not written.** It needs a reader who speaks it — see below. | 🔴 High | ⬜ Pending |
| 8 | Choosing a language | A setting in the profile, defaulting to the phone. | 🟠 Medium | ✅ Done |
| 9 | The server's half | Answered by two languages existing: codes, not translated messages. | 🟠 Medium | ✅ Done |
| 10 | The store listing | The English listing, beside the Spanish one it translates. | 🟢 Low | ✅ Done |

## Two languages, and the second one arrived whole

717 strings. `supportedLocales` is `[en, es]` now, so a phone in English gets an
English application and a phone in anything else gets Spanish — **entire**,
either way. Nothing is half-translated because nothing partial was declared.

## Following the phone is the default, not an option

The setting in the profile offers «el del teléfono» first and it is what a fresh
install does. Nobody chose this language inside the application; they chose it
when they set up their phone, and asking again would treat it as a decision they
did not make.

Choosing by hand exists for the case that does happen: a shared centre device,
set up by one person and used by another.

## What the second language cost, and where

**Two hundred tests broke at once.** They assert Spanish copy, and with English
declared the simulated phone resolved to English. The fix is one file —
`test/flutter_test_config.dart` pins the test locale — and the reason it belongs
there rather than in each test is that **the language is not what any of them
checks**: they check behaviour, and the text is how they look at it. The one
place where language *is* the subject is `test/core/i18n/language_test.dart`.

**A language name is not translated.** «Español» is «Español» in the English
list, because a picker exists so somebody who reads only one language can find
theirs. The literal check caught it in the code and it went into the ARB
instead — with the same value in both files, on purpose. That is the first
exception to «every string is translated», and it is a real one rather than a
convenience.

## Portuguese is still not written, and that is the decision

The Spanish in this application is written with care: «No es tu contraseña» is a
decision, and so is refusing to name a threshold. A translation that keeps the
meaning and loses the judgement reads like a product that does not know why it
says what it says.

Writing 717 Portuguese strings is easy. Knowing whether they sound like a person
is not, and it cannot be checked from here. So the file does not exist yet:
**declaring a language nobody has read would break the rule this phase is built
on** — that nothing is offered half-done — in a way that is invisible from
inside, which is the worst kind.

The English is in the same position in one respect and not in another: it can be
verified against the Spanish by anybody in this repository, and the audience for
it —donors, partner organisations— is one somebody here can read for.

## What the sweep missed, and what now catches it

Sixty-two strings survived the extraction and were found weeks later by reading
the code, not by using the application. They were the ones a sweep is worst at:
single words in a `switch` beside keys that were already extracted
(`'Despachar'`, `'Privado'`, `'Sin rol'`), Spanish grammar written as Dart
(`boxes == 1 ? 'caja' : 'cajas'`, in six places), and text built by joining
details — `'lote $batch'`, `'vence ${date}'`, `'cerrada ${date}'`.

**A missed string looks perfectly correct in Spanish.** It only breaks the day a
second language exists, which is after the moment anybody would go looking. So
the rule stopped being remembered and became a test: `no_spanish_literals_test`
scans `lib/` for accents, Spanish punctuation and words that cannot be anything
else. It is deliberately narrow — it gives up some recall to raise no false
alarms, because a check that cries wolf gets an exception added to it and then
it is not a check. It found two more while it was being written.

Two things came out of the same pass:

- **The queue stored a rendered count.** `'3 cajas'` went into the row and is
  read days later, possibly with the application in another language. The number
  was already a column of its own; the words are rendered when the screen is
  drawn.
- **Four exception messages were in Spanish.** Diagnostics are English by the
  rule above — nobody operating reads them, and Sentry is read by whoever wrote
  them.

## Recorded for the other repository

`docs/backend-requests.md` request 6 asked for named codes **and** Spanish
messages. A second language settles it: **codes, not messages.** A named code is
translated once here into every language the application has; a message the
server writes exists in one language, and answering in Spanish is now wrong for
half the audience.

So half of that request was withdrawn on 2026-08-25 and the other half stands:
give the actionable refusals codes of their own, starting with
`NOT_THREAD_PARTICIPANT`.
