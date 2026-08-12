# Versioning and the minimum supported client

An installed application is not a web deployment. A center may be running the
binary from three months ago on a phone nobody updates, against a backend that
moved on. Two mechanisms keep that from breaking silently, and they have to
agree with each other.

## Where the version comes from

`pubspec.yaml` holds both numbers in one line:

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        name  code
```

Gradle reads them through the Flutter plugin, so `versionName` and `versionCode`
are never edited in `build.gradle.kts`. `PackageInfo` reads the same values at
runtime, which is what travels in the `User-Agent` and what the version gate
compares. One source, three consumers.

## The rules

**`versionName` is semantic** — `MAJOR.MINOR.PATCH`. The backend compares it
against what `GET /v1/client/version` publishes, so it has to be parseable by
`pub_semver`. This is the number a person sees and the number a support
conversation quotes.

**`versionCode` only ever increases.** Google Play rejects an upload whose code
is not higher than the last one on the track, and there is no way to reuse a
number. It has no meaning beyond ordering; it is not tied to the name.

**Every uploaded build gets its own code**, including a rebuild of the same
version name. If an AAB reached a Play track, its code is spent.

## The gate it feeds

`ClientVersionGate` (`lib/core/api/client_version_gate.dart`) compares the
installed `versionName` against `min_supported_version` and `latest_version`
from `GET /v1/client/version`:

- below the minimum → the application says it must be updated;
- below the latest → it says there is an update available, without blocking;
- unreadable or unreachable → **never blocks**. A version check that fails
  cannot be what stops a center from working.

The consequence for releasing: raising `min_supported_version` on the backend
retires every installed binary below it. That is a backend decision with a
client cost, and it should be made knowing which versions are actually out
there — Play's console reports that per track.

## Releasing

1. Raise `version:` in `pubspec.yaml`, name and code both.
2. Commit that change on its own; the diff should be one line.
3. Tag it `vMAJOR.MINOR.PATCH` and push the tag.
4. The release workflow builds the signed bundle and publishes the debug
   symbols as artifacts.

The tag is what triggers the build, so the tag and the `version:` line have to
match. They are not checked against each other automatically yet; when the
first mismatch happens, that check belongs in the release workflow.
