# Phase 14 — The account: profile, password and second factor

> Long-term goal: nobody should have to leave the application, or ask somebody
> else, to get back into their own account.

---

## Why this before anything larger

The application could capture, seal, palletise and scan, and still had no answer
to the first thing that happens with real people: **«olvidé mi contraseña»**.
There was no way to ask for a reset, no way to change a password on purpose, no
way to turn a second factor on or off, and no screen that said who you are and
what you are allowed to do.

Fifteen endpoints existed, were generated, and were used by exactly one screen —
the forced password change. This phase spends them.

## What is included, and what is not

| Included | Left out |
|---|---|
| Requesting a password reset, before logging in | Registering an account — operators are invited, not signed up |
| Changing the password deliberately | Uploading an avatar — needs an image picker and multipart |
| Turning the second factor on, with its backup codes | Deleting the account |
| Turning it off, which also demands a code | Verifying an email address |
| Reading the profile: name, user, mail, centre, role | |
| Changing your own name | |
| Accepting pending terms | |

Registration and email verification belong to the web: a person reaches a centre
through an invitation, which the team directory already sends. Account deletion
is left out on purpose rather than by oversight — Play requires an in-app path
only for applications that let somebody create an account, which this one does
not.

## The recovery mail carries a link, not a code

`POST /v1/auth/forgot-password` makes the server send an email, and that email
contains **a link to the web**, not a code to type back into the application.

So the screen ends in an instruction rather than in a second field. Offering a
box for a code the person does not have — or worse, asking them to fish the
token out of a URL — would be pretending the flow finishes here. Somebody locked
out of their account is the worst person to mislead.

Finishing it inside the application would need deep links, which means an
`assetlinks.json` served from the web domain. That is a change to the other
repository and is recorded there rather than half-built here.

**The server answers the same whether or not the address has an account**, and
the screen repeats that answer word for word. Saying «ese correo no está
registrado» would turn a recovery screen into a way of finding out who has an
account.

## The second factor, and the one thing that must not be rushed

Turning it on is three steps in a deliberate order: the server hands over a
secret, demands a code generated from it, and only then starts requiring it at
login. That middle step exists so a mistyped or half-scanned secret cannot lock
somebody out of their own account.

**The backup codes are handed over once.** They arrive with the confirmation and
the server never shows them again; losing them together with the phone means
somebody in administration has to reset the account. The screen therefore has no
back arrow while they are on it, offers to copy them, and requires an explicit
«los guardé» before it can be left.

**Turning it off also demands a code.** It is not a formality: it is what stops
whoever finds an unlocked phone from removing the second barrier before taking
the account with them.

## Nothing here is cached

Every screen in this phase asks the server. A cached profile would show a role
or a centre that stopped being true, and this is precisely the screen somebody
opens to find out what they are allowed to do. Passwords and second factors
cannot be changed offline in any case.

---

## Objectives

1. Get back into an account without asking anybody.
2. Change a password because you decided to, not because you were forced.
3. Turn the second factor on and off, safely in both directions.
4. Say who you are and what role you hold.

## Non-objectives

- Registration, email verification and account deletion.
- Anything that works offline. None of it can.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Account repository | The auth endpoints behind a sealed outcome, including the two views of the same user that `/me` and `/me/profile` return. | 🟠 Medium | ✅ Done |
| 2 | Password recovery | «¿Olvidaste tu contraseña?» on the login screen, the neutral answer repeated as the server phrased it, and the truth that the link opens the browser. | 🟠 Medium | ✅ Done |
| 3 | Deliberate password change | The forced screen parameterised rather than duplicated: same form, different reason for being there. | 🟢 Low | ✅ Done |
| 4 | Second factor | Setup with its QR and its written secret, confirmation, backup codes shown once, and a disable that demands a code. | 🔴 High | ✅ Done |
| 5 | Profile screen | Identity, role in Spanish, the three security actions and pending terms, reached from the menu. | 🟠 Medium | ✅ Done |
| 6 | Verify on a real phone | The second factor needs a real authenticator app and a real login round trip. | 🟠 Medium | ⬜ Pending |

## Recorded for the other repository

Finishing a password reset inside the application needs Android App Links, which
require `assetlinks.json` served from `araguaney.lat`. Until then the mail's link
opens the browser, which works and is what the screen says.
