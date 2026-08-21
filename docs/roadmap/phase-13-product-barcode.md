# Phase 13 — Finding a product by its barcode

> Long-term goal: identifying what is in a donor's box should be pointing the
> camera at the package, not typing a name into a search field while holding it.

---

## Why this belongs here, and how much of it already exists

Reading a printed code with the camera is what a phone does that a browser
cannot — the same clause of the charter that justifies QR scanning and offline
capture. It is a sensor, not business logic: the catalogue stays the server's.

Almost everything is already in place and unused:

| Piece | State |
|---|---|
| `GET /v1/catalog/barcode/{gtin}` | Exists; generated as `CatalogApi.barcodeLookup…` |
| `product_types.gtin` in the local cache | Column exists and the mapper fills it |
| `BoxDraftInput.gtin` → `BoxDraft.gtin` | Exists in the contract and travels; nothing writes it |
| A camera that can read a barcode | **Missing.** `ScannerCamera` is pinned to `BarcodeFormat.qrCode` |

That last line is not an oversight: the QR-only restriction is what stops the
box scanner reading a manufacturer's barcode off a carton that also carries our
label. It means the product scanner has to be a **separate entry point with its
own formats**, not a widened version of the existing one.

## What real packages actually carry

Seven packages from the kind of donation this receives were photographed before
any of this was designed — five from Mexico (`750…`) and two from Venezuela
(`759…`).

**Every one carries an EAN-13, and nothing else identifies the product.** No
DataMatrix appeared on any of them, which is worth recording because the
opposite was assumed: pharmaceutical traceability is migrating to GS1 DataMatrix
in several countries, and it has not reached these.

**Two of them also carry a QR — and it is not the product.** Both have the
manufacturer's logo inlaid in the middle of the code, which is the signature of
a marketing QR pointing at a web page. A product identifier is not designed with
a logo on top of it. The proof is in the same packages: both **also** have their
EAN-13, on a different face.

That last detail decides the design. The QR and the barcode are on different
faces, so they rarely compete for the same frame, and only one of them says what
the product is.

## The three answers

The scanner reads linear codes **and** QR, but it only ever looks up the linear
ones. Reading the QR is what makes it possible to explain the mistake instead of
doing nothing, which in a warehouse is the worst possible feedback: nobody can
tell a broken camera from a bad aim.

| What arrives | What happens |
|---|---|
| EAN-13, EAN-8, UPC-A or UPC-E | Looked up: local catalogue first, then the server |
| A QR of ours (`BX-`, `TM-`, `DN-`) | «Esa es la etiqueta de una caja, no el producto» |
| Any other QR | «Ese código lleva a una página del fabricante; el que identifica el producto es el de barras» |

**UPC-E is included, and expanded before it is asked about.** The four linear
formats cover both of the world's systems: EAN-13 and EAN-8 outside North
America, UPC-A and UPC-E inside it — and a substantial share of what gets
donated comes from the United States, so leaving UPC-E out would close that door
for no good reason.

It needs one transformation. A UPC-E is a UPC-A with runs of zeros suppressed so
it fits on a small package, and its check digit was computed over the expanded
twelve digits, not over the eight that travel. Sending it compressed produces a
scan that reads fine and that the server rejects afterwards. The expansion is
GS1's definition of the symbol — deterministic, one answer — so it belongs with
stripping non-digits rather than with anything the backend owns.

Only the reader can know an eight-digit code is a UPC-E and not an EAN-8: they
are the same digits and only the symbology tells them apart. So the flag travels
from whoever scanned.

**DataMatrix is deliberately absent too.** It did not appear in the sample, and
accepting it without parsing the GS1 application identifiers would send the
wrong digits to the endpoint. «Not supported» is better than «half supported»;
when a package turns up carrying one, this is the place to revisit.

**No check digit is verified in the client.** It would be duplicated logic, and
it is unnecessary: the check digit is part of the EAN/UPC symbology, so a code
the decoder returns has already passed it. What the client does is strip
non-digits, which the local lookup needs anyway.

## Offline, and where the answer comes from

The local catalogue already stores each product's `gtin`, with the campaign
visibility the server served. So a scan resolves **with no request at all** when
the product is in the downloaded catalogue — which is the case that matters,
because capture is what happens in a basement.

With signal, a code the device does not know goes to the endpoint, which answers
one of three ways:

- `source: local` with a `product_type` — the platform knows it and this device's
  catalogue does not. The product is usable: the server vouched for it.
- `source: open_food_facts` with a `prefill` — the platform does **not** have
  this product. Open Food Facts describes it, and that description is not a
  catalogue entry.
- `404 BARCODE_NOT_FOUND` — nobody knows it.

**A prefill is shown and never selected.** Creating a product type is the
server's decision, and a client that invents one puts inventory under a name the
platform never agreed to — the failure this project has already paid for three
times with invented labels. What the screen does is show what was learned and
leave the person choosing from the catalogue by hand.

---

## Objectives

1. Identify a catalogued product by pointing the camera at its barcode.
2. Answer every scan, including the ones that cannot be resolved.
3. Work with no signal whenever the product is in the downloaded catalogue.

## Non-objectives

- Creating product types from a barcode. That is the server's.
- Widening the box and pallet scanner. Its QR-only restriction is the point.
- Reading lot or expiry. See below.

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Formats per scanner | `ScannerCamera` takes its formats instead of hardcoding QR, so each screen declares what it expects to read. | 🟢 Low | ✅ Done |
| 2 | Look up by GTIN | Local catalogue first, then the endpoint; the three server answers mapped to a sealed outcome. | 🟠 Medium | ✅ Done |
| 3 | The scanning screen | Camera with the product formats, the three answers, and a hint that says to aim at the barcode. | 🟠 Medium | ✅ Done |
| 4 | Entry from the picker | «Escanear código» inside Elegir producto, returning the product to the box draft and recording its `gtin`. | 🟢 Low | ✅ Done |
| 5 | Verify on a real phone | The emulator's camera is synthetic and cannot read a printed code. This is verified against real packages or not at all. | 🟠 Medium | ⬜ Pending |

## Noticed while looking at the packages, not scheduled

One box prints its lot and expiry as inkjet text beside the barcode
(`LOTE:441…`, `CAD:ABR…`). Those are two fields somebody types today, and a
camera could read them. It is a different feature with a different failure mode
— a misread expiry is worse than no expiry — and it is written down here only
because it is the kind of thing that is only ever discovered by looking at real
boxes.
