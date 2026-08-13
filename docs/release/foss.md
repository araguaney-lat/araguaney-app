# The `foss` flavor

The repository promises that a `foss` build carries no proprietary dependency.
Push notifications are the only place that promise costs anything, and this
document says exactly what it costs and how it is kept.

## Why a flavor flag is not enough

`PushService` keeps Firebase out of every code path: `NoopPushService` is a
complete implementation, and nothing in the application can tell which one it
got. That is necessary and it is not sufficient.

A Dart dependency is not excluded by a `--dart-define`. The moment
`firebase_messaging` is in `pubspec.yaml`, its native libraries are part of
every artifact built from that `pubspec.yaml`, whatever the flavor says at
runtime. A build that never calls Firebase still contains it, and anyone
auditing the APK would find it there.

So the promise is kept the only way it can be: **the `foss` artifact is built
from a branch that does not have the dependency.**

## The branch

`foss` branches from `main` and carries one patch. It is deliberately small,
because it has to be rebased for every release:

1. Remove `firebase_core` and `firebase_messaging` from `pubspec.yaml`.
2. Delete `lib/core/push/fcm_push_service.dart` — the only file in the project
   that imports Firebase.
3. In `lib/core/push/push_providers.dart`, return `const NoopPushService()`
   unconditionally and drop the import.

Nothing else changes. Gradle needs no edit: the Google Services plugin is
applied only when `android/app/google-services.json` exists, and on this branch
it never does.

```bash
git checkout -b foss origin/main
# apply the three changes above
flutter build appbundle --release --dart-define=APP_FLAVOR=foss ...
```

Verifying the promise on that branch is one command:

```bash
flutter pub deps --style=compact | grep -i firebase   # must print nothing
```

## What a `foss` build does and does not do

It does everything the application does, minus notifications. Login, offline
reading, scanning, online capture and the offline queue are identical code
paths — none of them touches `PushService`. What is missing is that nobody
tells the device when a risk review opens or a shipment arrives; the same
information is in the application, one refresh away.

## The honest cost

Two artifacts built from two branches are not the same artifact. A change that
lands on `main` reaches `foss` only when someone rebases, and a release that
forgets to rebase ships an older `foss`. That is a real maintenance cost,
accepted knowingly, because the alternative was to keep the promise in words
while shipping Firebase inside the binary.
