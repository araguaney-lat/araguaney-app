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
