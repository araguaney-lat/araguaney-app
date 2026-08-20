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
| 2 | Colour tokens | An explicit `ColorScheme` for light and dark from the design's values — cream, ink, gold and the humanitarian blue — instead of `ColorScheme.fromSeed`, which invents every shade from one seed. | 🟠 Medium | ⬜ Pending |
| 3 | Typefaces | Package Source Serif 4 and Hanken Grotesk, declare them in `pubspec.yaml`, and build a `TextTheme` that puts serif on headings and grotesque on everything else. Self-hosted: a build must not depend on fetching a font. | 🟠 Medium | ⬜ Pending |
| 4 | Component themes | Cards, inputs, buttons, list rows and dividers with the radii, borders and spacing the design draws, declared once in the theme. | 🟠 Medium | ⬜ Pending |
| 5 | Dark theme | The second theme the design already drew, wired to the system setting. | 🟠 Medium | ⬜ Pending |
| 6 | Retire the hardcoded palette | The bottom bar carries its own colours because there was nowhere else to put them. Once tokens exist, it reads them like everything else. | 🟢 Low | ⬜ Pending |
| 7 | Roadmap update | Mark tasks and update totals. | 🟢 Low | ⬜ Pending |

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
is blue teaches the wrong thing about every other screen.
