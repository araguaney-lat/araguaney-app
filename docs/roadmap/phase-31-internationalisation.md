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
| 6 | `app_en.arb` | The 457 strings in English, complete before the locale is declared. Whoever writes them is not the person who wrote the Spanish, so the descriptions are the only context they get. | 🔴 High | ⬜ Pending |
| 7 | `app_pt.arb` | The same in Portuguese. **Needs a reader who speaks it** — see the note below. | 🔴 High | ⬜ Pending |
| 8 | Choosing a language | A setting in the profile, defaulting to the phone. Worth nothing until there is a second language, so it waits for one. | 🟠 Medium | ⬜ Pending |
| 9 | The server's half | Business-rule messages are written by the backend and shown verbatim by design. With more than one language that becomes a negotiation — request 6 stops being optional. | 🟠 Medium | ⬜ Pending |
| 10 | The store listing | Spanish-only by a written decision that this phase invalidates. | 🟢 Low | ⬜ Pending |

## A warning about tasks 6 and 7

The Spanish in this application is written with care. «No es tu contraseña» is a
decision, not filler; so is quoting the server's words rather than paraphrasing
them, and so is refusing to name a threshold.

Whoever writes the English and the Portuguese will be translating that, and a
translation that keeps the meaning while losing the judgement is worse than
none: it reads like a product that does not know why it says what it says.
**Have somebody who speaks Portuguese read it before it ships** — it is the
language furthest from whoever is likely to write it here.

## Recorded for the other repository

`docs/backend-requests.md` request 6 asked for named codes and Spanish messages.
With three languages it becomes: the server needs to answer in the language the
client asks for, or answer with codes the client can translate. The second is
cheaper and is already half done — every named code this application knows is
already translated here.
