# Manual test plan — QR scanning

The camera cannot be exercised in a widget test: `mobile_scanner` needs a real
capture pipeline and a real permission dialog. Parsing, throttling and
resolution are covered by automated tests; what remains here is everything the
device itself decides.

Run this plan on a **physical** Android device, and on a physical iPhone before
the iOS release of Phase 09. A simulator has no camera and passes nothing.

## Preparation

- A center account with at least one box synchronised into the local cache.
- Printed or on-screen QRs for: a cached box, a box **not** in the cached
  window, a pallet, a donation, and any unrelated QR (a website, a Wi-Fi code).
- A way to cut connectivity — airplane mode is enough.

## 1. Permission

| # | Step | Expected |
|---|------|----------|
| 1.1 | First launch, tap **Escanear código** | The system asks for the camera. The iOS dialog shows the Spanish rationale from `Info.plist`. |
| 1.2 | Deny it | The screen explains that the camera is needed and offers **Reintentar**, not a black rectangle. |
| 1.3 | Grant it from system settings, return, tap **Reintentar** | The camera opens. |

## 2. Resolution by code type

| # | Step | Expected |
|---|------|----------|
| 2.1 | Scan a box that is in the cache | Its operator record opens: status, product, quantity, batch, expiry. |
| 2.2 | Scan a box outside the cached window, online | The public ficha opens, with the notice saying it carries less than the center record. |
| 2.3 | Scan a pallet | The pallet ficha shows status, center and box count. |
| 2.4 | Scan a donation | The donation summary lists its items and says capture arrives in a later phase. |
| 2.5 | Scan an unrelated QR | The screen says the code is not Araguaney's and shows what was read. |

## 3. Offline behavior

| # | Step | Expected |
|---|------|----------|
| 3.1 | Airplane mode, scan a cached box | Its record opens exactly as online. No spinner, no error. |
| 3.2 | Airplane mode, scan a box outside the window | "No hay conexión con el servidor…", not "no encontramos esta caja". The distinction is the point. |
| 3.3 | Restore connectivity, scan the same box again | The public ficha opens. |

## 4. Continuous mode

| # | Step | Expected |
|---|------|----------|
| 4.1 | Hold the camera over one label for ten seconds | One vibration, one screen. No burst of openings. |
| 4.2 | Go back, point at the same label again | It opens again immediately — the throttle is reset on return. |
| 4.3 | Scan three different boxes in a row, returning between them | Each opens on its first read, with no wait between them. |
| 4.4 | Scan in a dark room with the torch on | The torch toggles from the app bar and reads succeed. |

## 5. Device conditions

| # | Step | Expected |
|---|------|----------|
| 5.1 | Rotate the device while scanning | The preview follows without freezing. |
| 5.2 | Background the app while the camera is open, then return | The camera resumes; no crash and no frozen frame. |
| 5.3 | Scan a scuffed or partially covered label | Either it reads or it does not — it must never resolve to a different code. |

## Recording the result

Note the device model, OS version and application version with each run. A
scanning failure that only happens on one manufacturer's camera stack is the
kind of thing this table exists to catch.
