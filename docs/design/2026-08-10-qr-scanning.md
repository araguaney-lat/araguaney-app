# QR scanning (Phase 04)

> Design accepted on 2026-08-10. Covers code parsing, code resolution, the
> camera screen, and the screens a scan lands on. Scope matches
> [`docs/roadmap/phase-04-qr-scanning.md`](../roadmap/phase-04-qr-scanning.md).

## Problem

The native camera is one of the three reasons this application exists. A person
holding a sealed box needs the record for the label in front of them, and
typing a code with gloves on next to a pallet is not a workflow. This phase
turns a scan into the right screen.

## What the QR actually contains

The backend builds the QR payload as a URL to the public record, not as a bare
code (`backend/app/utils/qr.py`): `{base}/b/{code}` for boxes, `{base}/p/{code}`
for pallets, `{base}/d/{code}` for donations.

Code prefixes come from the services that mint them: `BX-` for boxes,
`TM-` for pallets, `DN-` for donations. One caveat worth recording: the
description of the public QR endpoint in the contract mentions `BOX-` and
`PAL-`. That is stale documentation upstream, not the format in use — the
generators are `intake_service`, `box_code_service` and `pallet_service`.

## What the contract can and cannot resolve

| Scan | Authenticated route | Public route |
|---|---|---|
| `BX-` box | none by code — `/v1/boxes/{box_id}` takes an id | `GET /b/{code}` → `BoxPublicOut` |
| `TM-` pallet | none by code — `/v1/pallets/{pallet_id}` takes an id | `GET /p/{code}` → `PalletPublicOut` |
| `DN-` donation | `GET /v1/donations/{code}` | — |

There is no authenticated endpoint that translates a code into an identifier.
The public fichas fill that gap: they return typed JSON and their Turnstile gate
lives in the web proxy, not in the API route, so the application can call them.
Adopting them meant widening `swagger_parser.yaml` beyond `/v1` — done in its
own commit, with the client regenerated rather than hand-written.

## Design

### 1. Parsing is pure — `lib/features/scanning/domain/`

`ScannedCode` is a sealed type: `BoxCode`, `PalletCode`, `DonationCode`,
`UnrecognizedCode`. `parseScannedCode` accepts both forms a camera can produce:

1. If the payload is a URL whose path is `/b/…`, `/p/…` or `/d/…`, the last
   segment is the candidate code and the segment names the kind.
2. Otherwise the whole payload is the candidate code.
3. The kind is decided by the code's own prefix. When the prefix is unknown but
   the URL path already said which kind it was, the path wins.

Rule 3 is what makes an old label keep working: a code minted before a prefix
changes still resolves through the path, and a bare code with a known prefix
still resolves without a URL. Anything else is `UnrecognizedCode`, which the
interface reports honestly instead of guessing.

### 2. Resolution — `lib/features/scanning/data/scan_resolver.dart`

`ScanResolution` is sealed: `CachedBoxFound`, `PublicBoxFound`,
`PublicPalletFound`, `DonationFound`, `ScanNotRecognized`,
`ScanResolutionFailed`.

- **Box:** the local cache first, matched by code. A hit gives the operator's
  full record and works with no signal. A miss falls back to the public ficha,
  labelled as such on screen — it carries less than the operator's record and
  the difference should not be silent.
- **Pallet:** the public ficha. Pallets are not cached: their operations belong
  to later phases, and caching a read model for them now would be inventing
  scope.
- **Donation:** `GET /v1/donations/{code}`, read-only. Intake capture arrives in
  Phase 05; this phase routes to the record and says so.

Failures return `ScanResolutionFailed` with the `ApiFailure`, so the screen can
distinguish "no signal" from "the server does not know this code".

### 3. Camera — `lib/features/scanning/ui/scanner_view.dart`

`mobile_scanner`, formats restricted to QR. Continuous mode keeps the camera
open: each read gives haptic feedback, and the same code is ignored for a short
window so that holding the phone over one label does not fire a burst of
requests. The server rate-limits the public fichas, which is a second reason the
scanner only reaches the network when the cache cannot answer.

Camera permission is explained in Spanish before it is useful to ask, and a
denial leaves a screen that says what is missing and offers to retry rather than
a black rectangle.

### 4. Screens

`ScanResultView` renders each resolution: the public box ficha, the pallet
ficha, the donation summary, and the two failure shapes. A cached box skips it
and opens the existing `BoxDetailView` directly — the operator's record is
strictly better than anything this phase would draw.

`HomeView` gains the scan entry point.

### 5. Tests

Parsing and resolution are pure or database-backed, and both are covered:
URL and bare forms, each prefix, the path-wins fallback, unknown payloads,
cache hit versus public fallback, and each failure shape. Resolution against the
cache runs on real in-memory SQLite.

The camera itself cannot run in a widget test. Task 5 of the roadmap asks for a
documented manual plan instead, which lives in
[`docs/testing/manual-scanning.md`](../testing/manual-scanning.md).

## New dependency

`mobile_scanner`, plus `NSCameraUsageDescription` on iOS. Android's camera
permission arrives through the plugin's manifest merge.
