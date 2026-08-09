# API contract snapshot

`openapi.json` is a vendored copy of the OpenAPI specification published by the
[Araguaney backend](https://github.com/araguaney-lat/araguaney). The Dart client
under `lib/core/api/generated/` is produced from this file and from nothing else.

## Why a snapshot instead of fetching the live specification

- **Reviewable diffs.** A contract change arrives as a readable diff in a pull
  request instead of appearing silently the next time someone regenerates.
- **Deterministic builds.** The generated client depends on a file in the
  repository, not on whichever backend happened to be reachable at build time.
- **Forks build offline.** Anyone can clone this repository and compile without
  access to a running backend.

The snapshot is stored with sorted keys and fixed indentation so that a refresh
diff shows what changed in the contract, not what changed in the serializer.

## Refreshing the snapshot

Do this in its own commit, separate from any feature work.

1. Obtain the specification from a running backend:

   ```bash
   curl -s http://localhost:8000/openapi.json \
     | python3 -c 'import json,sys; json.dump(json.load(sys.stdin), open("api/openapi.json","w"), indent=2, ensure_ascii=False, sort_keys=True)'
   printf '\n' >> api/openapi.json
   ```

2. Regenerate the client and format the output:

   ```bash
   dart run swagger_parser
   dart run build_runner build --delete-conflicting-outputs
   dart format lib/core/api/generated
   ```

3. Run `flutter analyze` and `flutter test`, then commit both the snapshot and
   the regenerated client together.

CI enforces step 2: the `api-client` job regenerates from the committed snapshot
and fails if the committed client differs. Never edit generated files by hand.

## Generation scope

The snapshot is kept complete and faithful to what the backend publishes, but
`swagger_parser.yaml` restricts generation to `/v1/**`. Left out are the health
probe, the third-party webhook, and the public by-code pages, which serve HTML
or PNG to a browser rather than data to a typed client.

## Known upstream defect

The backend exposes `GET /health/jobs` and `HEAD /health/jobs` under a single
`operationId`, which the OpenAPI specification does not allow and which makes
two generated methods collide. It does not affect this application because the
generation scope excludes that path, and it has been reported upstream.
