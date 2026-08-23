# Phase 16 — The screens phase 11 never reached

> The design system closed at fourteen of fourteen tasks. It was counted against
> a list of seven screens, and the list left out every screen somebody sees
> before they are logged in.

---

## How a complete phase left a gap

Phase 11 has a table titled «Screen by screen, after the foundation». It names
cajas, registrar entrada, pendientes de envío, escanear código, tarimas,
transferencias and revisiones — the seven screens the design deck draws. Login,
the second factor challenge, password recovery and the forced password change
are not on it, so they were never scheduled, never redesigned, and never noticed
as missing when the phase was declared done.

Two things follow from that, and both are visible on a phone.

**The mark is on exactly one screen.** `assets/icon/ic_mark.png` is used by
`home_view.dart` and nowhere else. It was added in Phase 08, when the launcher
icon and the splash were made — months after the session screens were written in
Phase 02. The application therefore shows its tree on the system splash, hides
it for the entire login, and shows it again on the home screen. Somebody signing
in sees the brand, then a plain form, then the brand.

**Five screens pass a border the theme did not ask for.** `login_view.dart`,
`totp_challenge_view.dart`, `forgot_password_view.dart`,
`change_password_view.dart` and `totp_setup_view.dart` each hand
`border: OutlineInputBorder()` to every field — Material's square, unrounded
default, written before the design system existed.

The first draft of this file claimed those fields therefore ignore the theme.
They do not, and the emulator said so before the claim reached a pull request:
the login draws the design's filled, twelve-point fields exactly like every
other screen. `InputDecorator` picks `enabledBorder` when a field is idle and
`focusedBorder` when it is focused, and both of those come from the theme
because the screens leave them null. `decoration.border` is only the fallback.

Which makes the real defect narrower and more interesting. The fallback is
reached in one state: **when a field has a validation error.** The theme
declares `border`, `enabledBorder` and `focusedBorder` and stops there, so
`errorBorder` and `focusedErrorBorder` are null everywhere in the application,
and every screen falls back to whatever its `border` is. On the five screens
above that is the square default; everywhere else it is the theme's rounded one.
So «escribe tu contraseña» is the moment the login stops looking like the rest
of the application — a state nobody screenshots, on the screen where getting it
wrong is routine.

There are two fixes and both are needed: drop the five hand-written borders, and
give the theme the error borders it never declared. The second is the one that
matters, because until it exists the error state is not designed anywhere — it
is inherited from whatever each screen happened to pass.

This is the seventh time this repository has paid for the same shape: **work
written before a rule existed, kept out of the audit because the list that
decides what gets audited was maintained by hand.** The status labels, the
category labels, the fixtures, the README totals. The fix here is the same fix
as there — derive the list rather than keep it.

---

## Objectives

1. Put the mark on the screen where the application introduces itself.
2. Design the error state of a field, which no screen declares today, and drop
   the hand-written borders that stand in for it on five of them.
3. Give somebody without a centre somewhere to go instead of a form they cannot
   fill.
4. Extend phase 11's screen table to cover every screen, so that «done» means
   the application and not a subset of it.

## Non-objectives

- Redesigning the session flow. The fields, the order and the copy stay; this
  is the dressing phase 11 already paid for, applied where it was missed.
- A second brand asset language. The tree that is already in the repository is
  the tree that goes on the login.
- Animating anything else. See below for why the login is the one place where
  motion has an argument, and everywhere else it would be decoration.

---

## The mark on the login, and why it needed a third file

`ic_mark.png` is 144 × 129 pixels, sized for the thirty logical pixels the home
header draws it at. A login mark wants around eighty, which is 240 physical
pixels on a three-times display — the existing file would be stretched to nearly
twice its size, and this is a detailed illustration where that shows.

The opposite file is no better. `ic_splash.png` is 1152 × 1152 and carries a
cream disc behind the tree, because the system splash needs one; drawing it on
the login would put a pale circle on a pale background in the light theme and a
visible disc in the dark one, and would decode half a megabyte for eighty
pixels.

So the phase adds `ic_mark_lg.png`: the same artwork, cropped to the tree and
sized 320 × 288, which covers eighty logical pixels up to a three-and-a-half
times display without stretching. It is derived from `ic_foreground.png`, the
launcher icon's foreground layer, which is the highest-resolution copy of the
bare tree the repository holds — the crop was taken from its alpha bounding box
so the framing matches `ic_mark.png` exactly.

Three files of the same tree is one more than anybody wants, and the reason is
worth writing down: **each is a different decoding cost for a different size**,
and a single file would make one of the three uses pay for the other two. That
stops being true the day the mark exists as a vector, which is also what Phase
09 needs for the iOS icon.

## The animation, and what it must not cost

The login is the one screen with an argument for motion, and it is not
decoration: the system splash shows this tree, and Flutter's first frame
replaces it. Without motion the tree cuts to a form. A short fade and rise makes
the handover read as one arrival instead of two screens.

Three constraints shape it into something small:

- **It cannot delay the fields.** Somebody reaching this screen has been logged
  out — often mid-shift, which is exactly when Phase 14 exists for. The
  animation is a wrapper around what is drawn; the form is interactive from the
  first frame and nothing waits for the tween to finish.
- **It runs once and does not loop.** A logo that keeps moving on the screen
  where a password is typed is a thing to look away from.
- **It obeys the system's accessibility setting.** When
  `MediaQuery.disableAnimationsOf` is true, the final state is drawn
  immediately. Motion sensitivity is not a preference to override for a brand.

### What richer animation would take, and why not yet

Recorded because the question was asked, and because the answer changes the day
the mark becomes a vector.

| Approach | What it needs | What it gives |
|---|---|---|
| Tween on the raster (**chosen**) | Nothing. No package, no new artwork. | Fade, rise, a slight scale. Reads as arrival. |
| Lottie (`lottie` package) | Somebody animating the tree in After Effects and exporting JSON. One pure-Dart dependency. | Real motion — leaves falling, branches settling. |
| Rive (`rive` package) | The artwork rebuilt in the Rive editor. A heavier runtime whose state machines this screen would not use. | The same, plus interactivity nothing here wants. |
| Drawing the tree stroke by stroke | The mark as an SVG with ordered paths — it does not exist; the tree is raster. Then `flutter_svg` and a painter over `PathMetric`. | The strongest effect and by far the most work. |

The last three all begin with the same missing thing: artwork this repository
does not have. Two of them need a designer before they need a programmer. The
first is a dozen lines against a file that is already here, and on the phones
this ships to it is also the only one that costs nothing to draw.

---

## Somebody who does not have a centre yet

The application opens at a sign-in and offers no registration, deliberately: a
person reaches a centre through an invitation. But the web has a public page —
`/registrar-centro` — where a centre applies to join the platform, and the
application never mentioned it. Somebody who heard about Araguaney, installed
this, and does not have a centre met a form that explained nothing.

**The form is not brought here, and not out of laziness.** It sits behind a
browser anti-abuse check; rebuilding it natively would mean running that check
inside an embedded web view, where it is worth less, with its configuration
carried in the binary. The application then ends in an email whose link opens
the web — the same shape as the password reset in Phase 14, and closing it
in-app needs App Links and an `assetlinks.json` served from the domain, which
is a change to the other repository.

So the login carries a link and the browser does the rest.

### The destination follows the phone, the interface does not

The texts of this application are Spanish because Spanish is the language a
collection centre is operated in, and `MaterialApp` fixes `Locale('es')` for
that reason. There is exactly one `app_es.arb`; there is no English.

The public page is different: it genuinely exists in both, at two different
paths — `/registrar-centro` in Spanish, unprefixed because Spanish is the web's
default, and `/en/register-center` in English, which is a different slug and not
the same one translated. Whoever taps this link is not operating a centre yet,
so sending them to the Spanish form while holding an English phone would lose
something for nothing. The link reads
`View.of(context).platformDispatcher.locale` — the phone's language, not the
application's, since asking `Localizations` would answer `es` forever.

Writing the test taught the same lesson the screens keep teaching: the widget
harness starts at `en_US`, so the Spanish case had to set its locale explicitly.
Assuming the default would have asserted the English behaviour under a Spanish
name and passed.

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the gap | Record that phase 11's screen list omitted the session screens and that «14 of 14» was counted against it. This file. | 🟢 Low | ✅ Done |
| 2 | A mark sized for a login | `ic_mark_lg.png` cropped from the launcher foreground, with the three-file decision written down. | 🟢 Low | ✅ Done |
| 3 | The mark on the login | Above the name, with a one-shot fade and rise that does not delay the form and obeys the reduced-motion setting. | 🟠 Medium | ✅ Done |
| 4 | Design the error state, and drop the five borders | `errorBorder` and `focusedErrorBorder` in the theme, which no screen declares today, and the hand-written `OutlineInputBorder()` removed from the session and second-factor fields. Pinned by a test on a field that is actually in error. | 🟠 Medium | ⬜ Pending |
| 5 | The way out for somebody without a centre | A link on the login to the web's public application form, opening the browser at the page in the phone's language. The form itself stays on the web, and the file says why. | 🟢 Low | ✅ Done |
| 6 | Complete phase 11's screen table | Every screen listed, with the session ones marked, so the phase's total describes the application. | 🟢 Low | ⬜ Pending |
| 7 | Verify on a device | The handover from the system splash to the login is the point of task 3, and it cannot be judged from a widget test. The link's destination is worth one tap on a real phone too. | 🟢 Low | ⬜ Pending |
