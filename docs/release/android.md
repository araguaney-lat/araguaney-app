# Android release

The laptop is an editor. CI is the binary factory: what gets distributed is
built by `.github/workflows/release.yml`, with a pinned toolchain, from a tag.

## What has to exist before the factory works

These are external prerequisites; the repository cannot supply them.

| Requirement | Where it lives |
|---|---|
| Google Play developer account | Registered, identity verified, paid |
| Upload keystore | Generated on the publisher's machine, stored outside the repository |
| Play App Signing | Enabled when the app is created in the console |
| Android app registered in Firebase | Package `lat.araguaney.araguaney_app`; produces `google-services.json` |
| Repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `GOOGLE_SERVICES_JSON`, `SENTRY_DSN` |
| Repository variables | `API_BASE_URL`, `WEB_BASE_URL` |

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

## Distribution

Play internal testing is the standing channel during development. Production
rollout is a decision about the product, not a step in this pipeline.

The bundle produced by the workflow is an artifact, not an automatic upload:
publishing is still a deliberate act by a person with console access. Wiring the
upload into CI is worth doing once the manual path has been walked at least
once, and not before — an automated publish that nobody has ever done by hand is
an automated way to publish the wrong thing.
