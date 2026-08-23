# Phase 11 — Design system

> The application works and looks like nothing. Every screen so far took
> Flutter's defaults: one seed colour expanded into a palette by algorithm,
> Roboto everywhere, stock component shapes, and no dark theme at all. The
> mobile design specifies none of that — it specifies two typefaces, an explicit
> palette, and every screen in light and dark.
>
> This phase is the layer underneath the screens. It is written down late on
> purpose: the roadmap never had a design phase, and the home screen looked like
> scaffolding because it *was* scaffolding. Naming the gap is the first task.

---

## Objectives

1. Replace the generated palette with the design's own tokens, in both themes.
2. Ship the two typefaces the design uses and map them onto a `TextTheme`.
3. Give the recurring components — cards, fields, buttons, list rows — the shape
   the design draws, once, instead of per screen.
4. Make dark mode a supported theme rather than an accident of the platform.

## Non-objectives

- Redesigning individual screens. Those are separate work and follow this.
- Animation, illustration or brand assets beyond what the design already ships.
- iOS-specific styling: the design is one language for both platforms.

---

## Why this pays for itself first

Every existing screen improves without being touched, and every screen built
afterwards is born correct. Doing it the other way — screen by screen, each
carrying its own colours — is how the bottom bar ended up with a hardcoded
palette that nothing else shares.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the gap | Record that the design was never implemented and that the flat look is Flutter's defaults, not a platform limit. This file. | 🟢 Low | ✅ Done |
| 2 | Colour tokens | An explicit `ColorScheme` for light and dark from the design's values — cream, ink, gold and the humanitarian blue — instead of `ColorScheme.fromSeed`, which invents every shade from one seed. | 🟠 Medium | ✅ Done |
| 3 | Typefaces | Source Serif 4 and Hanken Grotesk vendored under `assets/fonts` with their licences, declared in `pubspec.yaml`, and a `TextTheme` that puts serif on headings. Both are variable fonts: one file per family covers every weight, requested by axis. | 🟠 Medium | ✅ Done |
| 4 | Component themes | Cards, inputs, buttons, list rows, dividers and snackbars declared once. Cards carry a border and no elevation, because eight competing shadows read worse than a line. | 🟠 Medium | ✅ Done |
| 5 | Dark theme | Both themes are offered and the system decides. A collection center works at night as often as by day. | 🟠 Medium | ✅ Done |
| 6 | Retire the hardcoded palette | Gone: the bar reads an `AppPalette` theme extension, which is also where the colours Material cannot name — the bar, the confirming gold — now live for any screen to use. | 🟢 Low | ✅ Done |
| 7 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ✅ Done |

---

## What the design specifies

Taken from `Araguaney Móvil.dc.html` and the tokens the web already uses:

- **Type:** Source Serif 4 for titles, Hanken Grotesk for body.
- **Light:** background `#F4F1EA`, cards `#FFFFFF`, ink `#2B2723`, muted
  `#8A8073`, gold `#D69A00`, blue `#1F5E8C`.
- **Dark:** background `#121316`, cards `#1E1F24`, gold accent `#F3C033`.
- **Shape:** minimum 44px touch target, titles in serif, blue means navigate and
  gold means confirm.

That last pair is a rule and not decoration: a screen where the confirm button
is blue teaches the wrong thing about every other screen. It is pinned by a
test, in both themes, for that reason.

---

## What the phase actually cost, and what it did not

The whole layer is one directory — `lib/core/ui/theme/` — plus two font files
and four lines in `app.dart`. Every existing screen changed appearance without
being edited: the titles are serif, the cards have a border instead of a
shadow, and the greys are the design's rather than Material's.

**What it did not do** is redesign anything. The home screen is better dressed
and still shows what it showed; the flat layout the design replaces is separate
work, screen by screen. Fixing the foundation first means those screens will not
each carry their own copy of the palette, which is exactly how the bottom bar
ended up with hardcoded colours in the first place.

---

## Screen by screen, after the foundation

The tokens are the floor, not the rooms. Each screen still has to be laid out
the way the design draws it, and that work is tracked here rather than in a
phase of its own, because it is the same phase seen from the other side.

| # | Screen | Design | Status |
|---|--------|--------|--------|
| 8 | Cajas | 08 — count, scrollable status filters, sealing from the row | ✅ Done |
| 9 | Registrar entrada | 06 — campaign in the header, box count, two fixed actions | ✅ Done |
| 10 | Pendientes de envío | 07 — readiness strip, per-capture contents, retry | ✅ Done |
| 11 | Escanear código | 04 — full-bleed camera, viewfinder, result as a sheet | ✅ Done |
| 12 | Tarimas y tarima abierta | 09, 10 | ✅ Done |
| 13 | Transferencias | 12 | ✅ Done |
| 14 | Revisiones | 13 | ✅ Done |

### The complete inventory, which is the point

The table above lists the screens the design deck draws. It was mistaken for a
list of the screens the application has, and that mistake is what Phase 16
exists to pay for: everything absent from it was invisible, so nobody scheduled
the login and nobody noticed when the phase was declared finished.

So here is the whole surface, every destination and every sheet, and what
dressed it. **Its source is `lib/features/*/ui/`** — a screen that is not on
this table is a missing row, not a screen that does not count. Three of the
values mean different things:

- **design NN** — the deck draws it and the row above tracked the work.
- **phase 16** — no design was drawn, but the screen needed the foundation
  applied on purpose rather than by inheritance. That is this phase.
- **foundation** — it takes the tokens, the type and the component themes and
  needs nothing of its own. Done by construction, which is what Phase 11 was
  for.

«Foundation» is a claim, not a shrug: it says somebody can open that screen and
find the design's colours, serif titles and bordered cards without a line of
per-screen styling. Where that turns out to be false, the row changes and the
work gets a number.

| Feature | Screen or sheet | Dressed by |
|---|---|---|
| account | `profile_view.dart` | foundation |
| account | `totp_setup_view.dart` | phase 16 |
| boxes | `box_detail_view.dart` | foundation |
| boxes | `box_label_view.dart` | foundation |
| boxes | `boxes_list_view.dart` | design 08 |
| catalog | `product_scan_view.dart` | foundation |
| dashboard | `stock_by_category_view.dart` | foundation |
| home | `home_view.dart` | foundation |
| incidents | `report_incident_sheet.dart` *(sheet)* | foundation |
| intake | `anonymous_exception_dialog.dart` *(sheet)* | foundation |
| intake | `box_draft_sheet.dart` *(sheet)* | foundation |
| intake | `campaign_sheet.dart` *(sheet)* | foundation |
| intake | `donor_sheet.dart` *(sheet)* | foundation |
| intake | `intake_detail_view.dart` | foundation |
| intake | `intake_form_view.dart` | design 06 |
| intake | `intake_list_view.dart` | foundation |
| intake | `intake_queued_view.dart` | foundation |
| intake | `intake_submitted_view.dart` | foundation |
| intake | `pending_captures_view.dart` | design 07 |
| intake | `product_picker_sheet.dart` *(sheet)* | foundation |
| messaging | `new_thread_sheet.dart` *(sheet)* | foundation |
| messaging | `thread_view.dart` | foundation |
| messaging | `threads_list_view.dart` | foundation |
| pallets | `close_pallet_sheet.dart` *(sheet)* | foundation |
| pallets | `pallet_detail_view.dart` | design 10 |
| pallets | `pallets_list_view.dart` | design 09 |
| risk_reviews | `resolve_review_sheet.dart` *(sheet)* | foundation |
| risk_reviews | `risk_reviews_view.dart` | design 13 |
| scanning | `continuous_scan_view.dart` | foundation |
| scanning | `scan_result_sheet.dart` *(sheet)* | foundation |
| scanning | `scanner_view.dart` | design 04 |
| session | `change_password_view.dart` | phase 16 |
| session | `forgot_password_view.dart` | phase 16 |
| session | `login_view.dart` | phase 16 |
| session | `totp_challenge_view.dart` | phase 16 |
| shell | `more_menu_sheet.dart` *(sheet)* | foundation |
| shipments | `create_shipment_sheet.dart` *(sheet)* | foundation |
| shipments | `pick_pallet_sheet.dart` *(sheet)* | foundation |
| shipments | `shipment_record_view.dart` | foundation |
| shipments | `shipments_list_view.dart` | foundation |
| team | `campaign_members_view.dart` | foundation |
| team | `invite_person_sheet.dart` *(sheet)* | foundation |
| team | `pick_person_sheet.dart` *(sheet)* | foundation |
| team | `team_directory_view.dart` | foundation |
| transfers | `transfer_detail_view.dart` | foundation |
| transfers | `transfers_list_view.dart` | design 12 |

Files under `ui/` that are neither a destination nor a sheet — `scanner_camera`,
`scanner_viewfinder`, `push_permission_card`, `app_shell` — are parts of the
screens above and are dressed with them.

### What redesigning the first screen turned up

The status labels never worked. `boxStatusLabel` mapped `open`, `sealed`,
`palletized`, `received` — lowercase, and two of them states the backend does
not have. The real values are `DRAFT`, `SEALED`, `SHIPPED`, `REJECTED`, so the
fallback returned the raw key and the screen showed «SEALED» to somebody reading
Spanish. It had been that way since Phase 03 and no test caught it, because the
fixtures used the same invented values as the code.

The box record was the exception, and by accident of good judgement: it decides
whether sealing is possible from `sealedAt`, not from the status text, so it
kept working while the label lied. The list now does the same.

Worth generalising, because this is the third time: **a value that the client
invents and the server never sends fails silently when there is a fallback.**
Category labels, box statuses — both found by looking at the screen against
production, neither by reading code or running tests.

### What redesigning the second screen turned up

Four more, and every one of them the same shape.

**The category labels were only half fixed.** `categoryLabel` lived inside
`stock_by_category_view.dart`, so the one screen that imported it read
«Medicamentos» and the product picker — the screen somebody actually uses to
find a product — still read `MEDICAL_SUPPLY`. A translation table that only one
screen imports leaves the others showing the server's key. It now lives in
`core/ui/`, which is the point: it is not a property of one screen.

**The fixtures were carrying invented categories too** — `medicamento`,
`insumo`, lowercase Spanish that no server sends. Exactly what hid the status
bug, in the same file, still there after that fix. Corrected to the real keys.

**The capture list was stating a fact it had not been told.**
`IntakeRepository.find_all` does not load the boxes and `IntakeOut.boxes`
defaults to an empty list, so `GET /v1/intakes` always answers `boxes: []`. The
list counted that and printed «0 cajas» on every row; the capture record drew a
«Cajas» heading over nothing. Neither is a missing value — both are false ones,
produced by a schema default rather than by an invented constant. The list now
omits the count and the record says the history does not carry the boxes. See
request 2 in `backend-requests.md`.

**The box record offered sealing on a rejected box.** It decided from `sealedAt`
alone, which is null for a box that was rejected before it ever got sealed — the
same good instinct that saved it from the label bug, one condition short. The
list had already been given both halves; the record now matches.

So the generalisation holds and widens: **the client must not fill a silence.**
An invented constant and a schema default are the same failure wearing different
clothes, and neither shows up in a test whose fixtures agree with the code.

### One thing the redesign did not import from the design

Design 06 draws a «Cumple WHO (≥ 365 días)» badge under the expiry field. That
is a campaign rule the server owns and enforces, and its threshold is exactly
the kind of value this repository does not publish. The client would have to
invent a number to draw the badge — the very mistake the section above is about.
The rejection message the server sends already says it, in words, at the moment
it matters.

### What redesigning the third screen turned up

**Reserving box codes was unreachable at the only moment it is useful.** The
top-up action lived inside the pending-captures screen, and that screen was
offered — from the home list and from the menu — only when `pending > 0`. So the
sequence was: you can reserve codes once you already have captures waiting,
which happens after you have been offline, which is after the moment reserving
would have helped. Meanwhile the home screen said «sin códigos de caja
reservados: sin señal no vas a poder sellar» and gave no way to act on it, which
turns a warning into a reproach. The menu entry is now unconditional and the
home warning is tappable.

**A parked capture could only be thrown away.** A business rejection stops the
queue retrying on its own — that is invariant 4 and it is right — but the only
decision the screen offered was «Descartar». Most rejections describe something
somebody can resolve elsewhere: an approval that is missing, a product that gets
created. Discarding inventory to resolve paperwork is the worse of the two
options, and it was the only one on screen. «Reintentar» sends the row back to
the queue with the same capture key, so it cannot duplicate, and if the reason
still stands the server parks it again with the same text.

**The design draws a denominator the system does not have.** Design 07 reads
«intento 1 de 5». There is no maximum: the queue retries while there is a reason
to, and a business rejection parks instead of counting. Writing «de 5» would put
a limit on screen that nothing enforces — the same mistake as the WHO badge in
design 06 and the invented labels of the two screens before. The attempt count is
shown without one.

**One layout defect the emulator caught and the tests could not.** The three
readiness cells are equal height, but their labels break into a different number
of lines, so the numbers sat at different heights and the row stopped reading as
a row. The values are now anchored to the bottom of each cell.

**«Etiquetas» is not implemented, and the second action reserves codes
instead.** The design's second button prints labels; the application cannot
print — PDF labels are a web-panel capability, tracked as Phase 10 task 13. The
slot goes to «Reservar códigos», which is the action that belongs next to the
count of codes and the one that was unreachable.

The per-capture contents come from the stored payload rather than a new column:
the payload is exactly what will be sent, so reading it to show it is free and
retroactive. The contract carries product identifiers and not names, so a name
is resolved against the local catalog and, when the catalog no longer has it,
the line says only the quantity and the unit. Somebody deciding whether to
discard a capture needs true data, not a complete-looking line.

### What redesigning the fourth screen turned up

The result stops being a screen and becomes a sheet over the camera. Checking a
pallet means scanning one box after another, and every answer used to cost a
push and a pop; closing the sheet leaves the camera pointing again. The sheet
identifies — it does not replace the record. Where there is a record with
actions behind it (a cached box, a donation to capture) the sheet leads to it
with a button.

**Two more status tables were showing the server's keys.** A pallet's status was
rendered raw in two places and a donation's in one: «OPEN», «REGISTERED». The
three tables — boxes, pallets, donations — now live together in
`core/ui/status_labels.dart`, and the file says why: a translation table hidden
inside one screen leaves the others speaking the backend's language. That is the
third time the same shape has been paid for, after the category labels and the
box statuses.

**The pallet fixtures used `DRAFT`**, which is a *box* status — pallets are
`OPEN`, `CLOSED`, `SHIPPED`. Incidents had it too. Same as the invented
categories two screens ago: fixtures that agree with nothing but themselves.

The camera now fills the screen with a transparent bar over it, and a viewfinder
marks where to put the label. The viewfinder crops nothing — `mobile_scanner`
reads the whole frame and a code outside the square still resolves. It is an
instruction, not a restriction, and the dimming around it exists so the white
text above and below stays readable over whatever the camera is pointing at.

### What redesigning the last three screens turned up

**Two more translation tables were hidden inside a screen**, which is the same
finding as the fourth screen's and the second's, now for the fifth and sixth
time. A transfer's status was translated inside the transfers screen and a
review's inside the reviews screen, so every other place that touched those
values — a row, a sheet, a future notification — would have printed
«REQUESTED». The file that holds them says why in one line: *una tabla de
traducción escondida en una pantalla deja a las otras enseñando el idioma del
backend.* All six tables now live in `core/ui/status_labels.dart`.

**Transferencias filters by direction, not by status**, and that is the design's
reading of the screen rather than a shortcut. What a coordinator needs to know
first is whether the transfer is theirs to answer: an incoming request waits on
them, an outgoing one waits on somebody else. Status is the second question and
it is on the row.

**The screen cannot name the other centre, and says so instead of guessing.**
The contract carries `from_center_id` and `to_center_id` and nothing
else, and both `/v1/centers` endpoints require a national administrator, so a
coordinator's token cannot resolve an identifier into a name. Printing the
identifier would be decoration; inventing a name would be worse. Recorded as
request 3 in `backend-requests.md`.

**Revisiones quotes the server's words rather than restating them.** The reason
a capture was flagged is the server's sentence, shown between quotation marks
and unedited. Paraphrasing it would put the client in the position of explaining
a control it does not implement — and the threshold that produced the sentence
is exactly the kind of value this repository does not publish.

**A second layout defect only the emulator caught.** An open pallet has no
weight, no height, no closing date and no shipment, so its subtitle was an empty
`Text('')` — a blank second line that made every open row taller than it needed
to be and left the code floating. The row now has no subtitle when it has
nothing to say, pinned by a test. Like the readiness cells two screens ago, no
test failed and nothing looked wrong in the widget tree: it was visible only on
a device.

### A counting error in the summary, fixed by counting

The README says its totals are the sum of the phase task tables «and nothing
else». They were not: the pending column had been one short since before this
phase, and every update since carried the error forward because each one edited
the total by hand rather than recounting. Counted from the phase files, the
project has **122 tasks**, not 121.

It is a small number and a familiar shape: a figure kept by editing instead of
by deriving drifts from what it claims to summarise, exactly like a label table
kept in one screen drifts from the values the server sends.
