# Android release

The laptop is an editor. CI is the binary factory: what gets distributed is
built by `.github/workflows/release.yml`, with a pinned toolchain, from a tag.

## The application id is permanent

`org.araguaney.app` — reverse DNS of the domain the project owns, which is also
what an App Links `assetlinks.json` on `araguaney.org` will have to match.

**Play binds a package name to an app entry forever.** It cannot be edited
later, it cannot be reused by another entry, and for somebody who already has
the application installed a new one is not an update but a second application.
The id was changed once, on 2026-08-27, from `lat.araguaney.araguaney_app`
before the first public release; the cost then was a handful of testers
reinstalling. After a public rollout the same change would mean asking every
centre to uninstall and install again.

Changing it means, in this order and not another:

1. Register an Android app with the new package in Firebase, and download its
   `google-services.json`.
2. Replace the `GOOGLE_SERVICES_JSON` secret with that file.
3. Only then merge the id change. **Reversing 2 and 3 stops the factory**: the
   Google Services Gradle plugin refuses a configuration file that does not
   contain the package being built, and fails the build rather than producing a
   binary that cannot receive notices.
4. Create the app in the Play console under the new id, configure the internal
   track, and paste the listing from [`store-listing.md`](store-listing.md).
   The upload keystore is reused; the Play signing key is per app and is new.

The iOS bundle id follows the same string. It costs nothing to set while no
build has reached App Store Connect, and it would cost the same as the Android
one afterwards.

### What was retired with the old id, on 2026-08-28

The Firebase Android app for `lat.araguaney.araguaney_app` was deleted, and its
Play entry with it. Two consequences worth knowing before somebody wonders:

- **Any device still running the old binary silently stops receiving notices.**
  Deleting a Firebase app invalidates its tokens. If an old build ever turns up
  in somebody's hands, that is why its notifications are gone — it is not a bug
  to chase.
- **The old package name is still reserved.** Deleting a Play entry does not
  free it; `lat.araguaney.araguaney_app` cannot be used again by anybody,
  including us. That was the price of the change and it is already paid.

The `google-services.json` in use declares both packages, because it was
downloaded while both existed. Nothing breaks: the Gradle plugin only requires
the package being built to be present. It can be downloaded again whenever
somebody wants the file to describe only what exists.

## What has to exist before the factory works

These are external prerequisites; the repository cannot supply them.

| Requirement | Where it lives |
|---|---|
| Google Play developer account | Registered, identity verified, paid |
| Upload keystore | Generated on the publisher's machine, stored outside the repository |
| Play App Signing | Enabled when the app is created in the console |
| Android app registered in Firebase | Package `org.araguaney.app`; produces `google-services.json` |
| Sentry project | Produces the DSN, and an auth token for uploading symbols |

### Repository secrets

| Secret | What it carries |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The upload keystore, base64-encoded |
| `ANDROID_STORE_PASSWORD` | Its store password |
| `ANDROID_KEY_ALIAS` | The key alias inside it |
| `ANDROID_KEY_PASSWORD` | That key's password |
| `GOOGLE_SERVICES_JSON` | `google-services.json`, base64-encoded |
| `SENTRY_DSN` | The project's DSN, whole, with its scheme |
| `SENTRY_AUTH_TOKEN` | A token with `project:releases`, `project:write` and `org:read` |
| `SENTRY_ORG` | The organisation **slug**, not its display name |
| `SENTRY_PROJECT` | The project **slug** |

The two slugs are the ones in the Sentry URL — lowercase, hyphenated, and
frequently nothing like the name shown in the interface. `sentry-cli` only
understands the slug, and given a display name it fails with an «organization
not found» that helps nobody.

The DSN is the odd one in this table: it ends up **inside the shipped binary**
and anybody can read it out of the APK, so it is not a credential in the strong
sense — it only permits sending events. It stays a secret anyway, because this
repository publishes no infrastructure identifiers. The auth token is a real
credential and must never leave the secret store.

### Repository variables

| Variable | Value |
|---|---|
| `API_BASE_URL` | `https://api.araguaney.lat` |
| `WEB_BASE_URL` | `https://araguaney.lat` |

These are variables rather than secrets on purpose: they are public addresses,
and seeing them in a build log is what makes a misconfigured build diagnosable.

### There is no `.env`

A mobile application reads no environment at run time — there is no process and
no server, only a compiled binary that already carries its values. Configuration
enters at **build time** through `--dart-define`, and `AppConfig` reads it with
`String.fromEnvironment`.

Bundling a `.env` as an asset, which some Flutter projects do, would put those
values inside the APK where unzipping reveals them. The only local template in
this repository is `android/key.properties.example`, for signing; the table
above is the equivalent for CI.

## Which Android versions this runs on

`minSdk` is **24 — Android 7.0, 2016** — and it is written down in
`android/app/build.gradle.kts` rather than inherited from
`flutter.minSdkVersion`. Inheriting it meant nobody had chosen it and a Flutter
upgrade could move it without anyone noticing; who can install the application
is a decision this project makes on purpose.

Two things hold that number where it is.

**The dependency floor.** Three plugins already require API 24 —
`flutter_secure_storage`, `shared_preferences_android` and
`url_launcher_android`. Firebase and `mobile_scanner` require 23,
`connectivity_plus` and Sentry 21. Going below 24 is not a trade-off today; it
does not compile.

**Who uses this.** Somebody capturing donations at a collection center brings
the phone they already own. In Mexico and Venezuela, where this ships first,
that is frequently a device from 2018–2021. Raising the minimum excludes
precisely the people least able to do anything about it, so it is raised only
when a dependency forces it — not for convenience.

### What degrades, and where

| Android | Behaviour |
|---|---|
| 7.0 – 12 (24–32) | Everything works. Notifications are granted at install time; the system shows no permission dialog, and the in-app invitation never appears because there is nothing to ask for. |
| 13+ (33+) | The system asks before delivering notifications and the answer can be no. The application explains what the notices are for **before** opening that dialog, and if it is denied, nothing insists — see Phase 07. Denied means no notices arrive at all; everything else keeps working. |
| 8.0+ (26+) | Notices land on the application's own channel (`araguaney_operaciones`, high importance), which can be silenced on its own in system settings without silencing the application. Below 26 channels do not exist and each notice carries its own importance. |

Nothing in the feature set requires a newer Android than 24. Push delivery,
QR scanning, the local database and secure storage all work at that floor; what
changes with version is the permission model above, not the capability.

### The device you test on

A development phone is a different question from `minSdk`. To exercise the
notification permission dialog — the failure most likely to reach production —
the test device or emulator has to run **Android 13 or newer**, because below
that the dialog does not exist. That is a requirement of the tool, not of the
people who use the application.

## Generating the upload keystore

```bash
keytool -genkey -v -keystore ~/araguaney-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep it somewhere that survives losing the laptop. With Play App Signing
enabled, Google holds the app signing key and this is only the upload key —
which can be rotated by asking Google, unlike the app signing key.

For CI, the same file becomes a secret:

```bash
base64 -i ~/araguaney-upload.jks | pbcopy   # macOS
base64 -w0 ~/araguaney-upload.jks           # Linux
```

Paste it into `ANDROID_KEYSTORE_BASE64`. The workflow decodes it, writes
`android/key.properties`, builds, and deletes both afterwards.

`google-services.json` travels the same way, in `GOOGLE_SERVICES_JSON`. The
workflow **fails without it** rather than building quietly: a release that
installs without notifications and says nothing is worse than one that does not
build.

`API_BASE_URL` and `WEB_BASE_URL` are checked for the same reason, and it is
worth knowing why they need a check of their own. `String.fromEnvironment` falls
back to its default only when the key is **absent**; `--dart-define=API_BASE_URL=`
defines it as an empty string, which wins. So a release built without those
variables would not quietly point at `localhost` — it would point nowhere, and
sign and upload all the same. The workflow stops instead.

## Building locally

Copy `android/key.properties.example` to `android/key.properties` and fill it
in. Both the keystore and that file are in `.gitignore`.

```bash
flutter build appbundle --release \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=API_BASE_URL=https://... \
  --dart-define=WEB_BASE_URL=https://...
```

**Without `key.properties` the release build still works**, unsigned. That is
deliberate: someone evaluating the repository can build and inspect the result
without asking anyone for a key. What they cannot do is upload it.

## What the release build does differently

- **R8 shrinking and resource shrinking**, with keep rules in
  `android/app/proguard-rules.pro`. Each rule there says what would break
  without it; the generated API models need none, because `json_serializable`
  generates Dart code rather than using reflection.
- **Obfuscation with split debug info.** The symbols are uploaded as their own
  artifact. A stack trace from an obfuscated binary without its symbols is a
  list of letters.
- **Sentry release tagging**, using `package@version+build` so a trace can be
  matched to the symbols from the same build. With no `SENTRY_DSN` the
  application starts normally and reports nowhere.

## What the first real release build taught us

Written down because none of it was visible until the bundle was actually
assembled.

- **`sentry_flutter` is pinned to `^9.0.0`.** The 8.x line still declares Kotlin
  language version 1.6, which the current toolchain refuses to compile. Anything
  that pulls it back below 9 breaks the release build while leaving debug builds
  perfectly happy.
- **R8 needs `-dontwarn com.google.android.play.core.**`.** Flutter's embedding
  references Play Core's deferred-components API; this application ships no
  deferred components, so those classes are not on the classpath and R8 stops
  with a list of missing classes that are not actually missing.
- **The bundle is around 77 MB.** Most of it is the ML Kit barcode model that
  comes with `mobile_scanner`, plus Firebase Messaging and one copy of the
  native libraries per architecture. Play splits it per device, so what an operator downloads is a
  fraction of that — but the number in the console will look alarming until you
  know why.
- **Two plugins still apply the Kotlin Gradle Plugin themselves**
  (`mobile_scanner`, `sentry_flutter`). Flutter warns that future versions will
  refuse to build in that case. It is a warning today and a broken release build
  eventually; the fix is upstream, and the toolchain pin is what buys time.

## The icon

Generated by `flutter_launcher_icons` from `assets/icon/`; the density folders
are output and are not edited by hand.

The source is the araguaney of the web logo, **cropped out of the gold ring that
surrounds it**. That ring cannot survive as an app icon: the launcher applies
its own mask — circle, squircle, teardrop, one per manufacturer — so a logo that
brings its own circle ends up either clipped or drawn as a circle inside a
circle. Icons are not logos at 48dp.

The foreground fills 92% of its layer, and `flutter_launcher_icons` insets it a
further 16% on each side, which lands the tree inside the 66dp of a 108dp layer
that every launcher is guaranteed to show. Outside that band each manufacturer
crops differently.

**There is deliberately no monochrome layer.** On Android 13+ that means a
themed icon falls back to the normal one — worse to look at, and honest: a
flowering tree flattened to one ink at 24dp needs a simplified drawing, not this
file in black. The same missing asset is why the status-bar icon is still a
generic box. Both want a vector original that does not exist yet.

`assets/icon/ic_launcher.png` doubles as the Play store icon: 512×512, opaque,
no border or shadow of its own, since Play rounds the corners itself.

## The splash

Since Android 12 there are **two owners of that screen**. The system draws its
own splash while the process starts — an icon masked into a circle on a colour,
and nothing else: no text fits, because anything outside the mask is cropped.
Then Flutter draws the application's first frame. The first one cannot be
removed.

So the only thing worth doing is making the second indistinguishable from the
first: same gold, same logo, same size, no wordmark and no spinner. What is
perceived is one presentation that lasts a little longer, rather than two.
`BrandSplash` writes its colours down instead of reading the theme for the same
reason — the theme has a dark variant and the system splash does not.

The tree travels on its cream disc because yellow on gold does not read.

**The v31 themes must keep a `NoTitleBar` parent.** Writing them with
`Theme.DeviceDefault` gives the activity the system ActionBar back, and a bar
with the application's name appears above the interface.

## After publishing a version

One step, in the backend's environment, and it is easy to forget because nothing
in this repository breaks without it.

`GET /v1/client/version` publishes two values that this application reads on
every start — the minimum it supports and the newest published. Both are
environment variables of the backend, never committed anywhere:

| Variable | Raise it | What the application does |
|---|---|---|
| `LATEST_CLIENT_VERSION` | Every time a version becomes **downloadable** | Mentions the update at the foot of the sign-in screen, and offers «Actualizar» or «Más tarde» at launch |
| `MIN_SUPPORTED_CLIENT_VERSION` | Only when an old version would produce **incorrect data** | Blocks it with a screen that has no way past |

```
railway variables --service <backend> --set LATEST_CLIENT_VERSION=1.0.0
```

Timing matters in one direction: raise `latest` when the build is actually
available to download, not when it is submitted for review. Announcing an update
that is not there yet sends somebody looking for a button that does not exist.

Raising the minimum is the expensive one and the backend repository has a runbook
for that decision — `docs/flujo/version-minima-del-cliente.md`. The short version:
never to push adoption, only when an old build would write something wrong, and
never without leaving time for the update to reach people first.

**A subtlety of how versions compare.** The gate parses semantic versions, where
`+3` is build metadata and does not participate in precedence — so `1.0.0+1` and
`1.0.0+3` compare **equal**. A minimum retires a version *name*, never one build
of it. Retiring a specific build means the next one carries a new name, not only
a new code.

The endpoint is cached at the edge for an hour, so a change takes up to that long
to be seen everywhere.

## Distribution

Play internal testing is the standing channel during development. Production
rollout is a decision about the product, not a step in this pipeline.

The bundle produced by the workflow is an artifact, not an automatic upload:
publishing is still a deliberate act by a person with console access. Wiring the
upload into CI is worth doing once the manual path has been walked at least
once, and not before — an automated publish that nobody has ever done by hand is
an automated way to publish the wrong thing.

Both the artifact and the file inside it are named after the version they carry,
read from `pubspec.yaml`: `araguaney-1.0.0+1.aab`. Play does not look at the
file name — it reads the manifest inside the bundle, and the signature covers
the contents rather than the name, so renaming one changes nothing about what
gets published. The name is for the person who has three bundles in a downloads
folder and needs to know which is which, which is a real failure mode once
`versionCode` starts climbing: uploading the wrong one is rejected only if its
code was already used, and accepted silently if it was not.
