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

**What the measurement changed about that.** Writing the test first was worth
it, and not for the usual reason. The first version of it read
`InputDecorator.decoration.border` and reported that a field in error was drawn
in the resting line colour — which would have meant the error was not signalled
at all. That is false, and it is false because `decoration.border` is the
declared fallback and not what gets painted. Reading the painted border instead
— through the border painter, the way Flutter's own tests do it — says something
narrower: **Material's own M3 defaults were already resolving the colour to the
error colour.** What the five screens lost was the shape, four points of corner
radius instead of the design's twelve.

So the defect is smaller than the first draft of this file implied, and the fix
is still the same one. The theme now declares `errorBorder` and
`focusedErrorBorder`, which makes the error state a decision this repository
made rather than one Material made for it, and makes it independent of whatever
border a screen passes. The tests pin the shape and the colour, in both themes,
and were confirmed to fail without the change.

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

### Inside the application, but still the system's browser

The link first opened the browser beside the application, which meant somebody
tapping it left the sign-in screen and had to find their way back. It now opens
in **Custom Tabs** on Android and `SFSafariViewController` on iOS —
`LaunchMode.inAppBrowserView`, one argument in `url_launcher`, no new
dependency.

The distinction that matters is not cosmetic. Custom Tabs **is the system's
browser**: its engine, its process, the person's cookies, their password
manager, their anti-fraud protection. It is drawn inside this application's
task and the back button returns to the sign-in screen, and that is the whole
difference. So the objection recorded above — that the page's anti-abuse check
is worth less inside an embedded view — does not apply to it. That objection
was, and remains, about a `WebView`.

A `WebView` is an engine this application would host: its own cookie jar, no
password manager, and the ability to inject and read the page's JavaScript,
which would make this repository part of that page's security boundary. **The
rule this phase writes down is that nothing which asks for a password goes in
one.** The registration form asks for none; if the application ever links to
something that does, it stays in the real browser.

`LinkTarget` therefore defaults to `systemApp`, and a screen that wants the
in-app browser has to say so. The shipment manifest keeps opening outside on
purpose, and a test pins that: it is a signed PDF, and the system viewer is
where it can be saved, printed or sent onward.

The manifest gained a `<queries>` entry for `https`, because since Android 11
an application cannot see which browsers are installed unless it declares the
intent it wants to resolve. Without it, resolving a Custom Tabs provider can
fail on a phone whose default browser is not the emulator's.

### What is pressed has corners, not a pill

The foundation gave every filled and outlined button a `StadiumBorder`, so a
button sat next to a field with twelve-point corners and a card with fourteen
and matched neither. The design draws a rectangle with soft corners. Buttons now
carry the field's radius — one value for everything interactive — and cards stay
two points more open, which is what separates a surface from an action.

Text buttons are themed too. They draw no container, but they do draw a ripple
when pressed, and without the shape that ripple stayed the pill this change
removes.

This belongs to Phase 11 by subject and is recorded here by choice: reopening a
closed phase to append a row is worse than writing the correction where the work
happened. It is the same reason the inventory says what dressed each screen
rather than pretending the deck covered everything.

### A tonal button was a primary one

Found while measuring the shape change. `FilledButton.tonal` rendered with the
same background as `FilledButton` — both `#1F5E8C` — because
`FilledButtonThemeData` is read by **both** variants and the theme set
`backgroundColor: scheme.primary` on it, which beats the tonal variant's own
default. Two buttons asked for tonal and got primary, so the hierarchy between
them did not exist.

The theme no longer names those colours. Material 3 takes them from the
`ColorScheme` written above: primary from `primary`, tonal from
`secondaryContainer`, which is the design's soft gold. Nothing about the primary
button changes, and that was verified by reading the painted background rather
than assumed.

**Which moved a button.** With its own colour back, a tonal button says «gold
confirms». That is right for «Cerrar» on a pallet, which is a confirmation. It
is wrong for «Elegir producto», which opens a search — so that one becomes an
outlined button, blue and low-emphasis, and the rule holds on both.

**And it moved a test.** «Blue navigates and gold confirms» asserted the rule by
reading `filledButtonTheme.style.backgroundColor` — the value the theme
declares. Removing that value broke a test of a rule that still holds, which is
the second time in this phase that a test read a declaration instead of what is
drawn. It now checks the scheme, and a widget test reads the painted background
of both variants in both themes.

### Two messages that described something that had not happened

Found because a misconfigured emulator build made the sign-in fail and the
screen said «Ocurrió un error inesperado». The build was pointing at the website
instead of the API, which is nobody's fault but ours; what it exposed is worth
keeping.

**Wrong credentials claimed the session had expired.** The server answers a bad
password with `401 INVALID_CREDENTIALS`, and every 401 mapped to «Tu sesión
expiró. Inicia sesión de nuevo.» — on the screen where there is no session yet.
`UnauthorizedFailure` now consults the copy table first, so a named 401 speaks
and the generic one still describes an expiry.

**A test was pinning a response the server does not send.** "A real credentials
rejection still says what the server said" built its fixture as a
`BusinessRuleFailure` carrying a Spanish message. The server sends a 401 with
«Invalid credentials» in English. So the test agreed with the code and with
nothing else, and the defect above lived underneath it — the same shape as the
invented status labels, the invented categories and the pallet fixtures that
used a box status. It now uses the real shape.

**A locked account was told it was not their password.** The sign-in screen
treats a rate limit as «no es tu contraseña», which is right: that limit is not
counted per person and at the start of a shift the whole centre can exhaust it.
But `ACCOUNT_LOCKED` arrives with the same 429 and means the opposite — those
were this account's failed attempts. It now falls through to its own copy.

Neither new message names a number. How many attempts and for how long are
parameters of a server-side control, and this repository publishes the
mechanism and never the value. The server sends the remaining time in its own
message for whoever needs it.

### A URL written where a configuration already existed

The registration link carried `https://araguaney.lat/...` as two constants in
the widget, while `AppConfig.webBaseUrl` already exists, is injected with
`--dart-define=WEB_BASE_URL`, and is what draws the QR on a box label. A build
pointing somewhere else — a fork, or a development environment — would still
have sent people here. It now derives from the configuration, which is the
seventh time this repository has recorded the same shape: a value written into
a screen instead of read from where it is configured.

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Name the gap | Record that phase 11's screen list omitted the session screens and that «14 of 14» was counted against it. This file. | 🟢 Low | ✅ Done |
| 2 | A mark sized for a login | `ic_mark_lg.png` cropped from the launcher foreground, with the three-file decision written down. | 🟢 Low | ✅ Done |
| 3 | The mark on the login | Above the name, with a one-shot fade and rise that does not delay the form and obeys the reduced-motion setting. | 🟠 Medium | ✅ Done |
| 4 | Design the error state, and drop the five borders | `errorBorder` and `focusedErrorBorder` in the theme, and the hand-written `OutlineInputBorder()` gone from the session and second-factor fields. Pinned by tests that read the painted border of a field actually in error, in both themes. | 🟠 Medium | ✅ Done |
| 5 | The way out for somebody without a centre | A link on the login to the web's public application form, opening the browser at the page in the phone's language. The form itself stays on the web, and the file says why. | 🟢 Low | ✅ Done |
| 6 | Complete phase 11's screen inventory | Every destination and every sheet listed in Phase 11, derived from `lib/features/*/ui/`, with what dressed each one — a design, this phase, or the foundation. A screen missing from it is now a missing row rather than an invisible one. | 🟢 Low | ✅ Done |
| 7 | The registration link opens inside the application | Custom Tabs through `LinkTarget.inAppBrowser`, the default left outside, the shipment manifest pinned to the system viewer, and the `<queries>` entry Android 11 needs to resolve a browser. | 🟢 Low | ✅ Done |
| 8 | Buttons with corners instead of a pill | `StadiumBorder` retired from filled, outlined and text buttons in favour of the field's radius, pinned in both themes. | 🟢 Low | ✅ Done |
| 9 | A tonal button is not a primary one | The theme stops naming button colours so Material 3 reads them from the scheme, «Elegir producto» becomes outlined because gold would say confirm, and the painted background of both variants is pinned in both themes. | 🟢 Low | ✅ Done |
| 10 | Say what actually failed when signing in | A named 401 speaks instead of claiming the session expired, a locked account stops being told it is not their password, and the fixture that hid the first one is corrected to the shape the server sends. | 🟠 Medium | ✅ Done |
| 11 | The registration link reads its base from the configuration | `AppConfig.webBaseUrl` instead of two constants in the widget, so a build pointing elsewhere sends people to its own web. | 🟢 Low | ✅ Done |
| 12 | Verify on a device | The handover from the system splash to the login is the point of task 3, and it cannot be judged from a widget test. The in-app browser and the link's destination in both languages are worth one tap on a real phone too. | 🟢 Low | ⬜ Pending |
