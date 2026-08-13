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
| Repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `SENTRY_DSN` |
| Repository variables | `API_BASE_URL`, `WEB_BASE_URL` |

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
