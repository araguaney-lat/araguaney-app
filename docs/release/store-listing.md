# Play store listing

The copy lives here rather than only in the console so it can be reviewed in a
pull request, and so the next person changing it can see why each line says what
it says. The console is where it gets pasted; this file is where it is decided.

Written in Spanish first, because everybody who installs this operates in
Spanish. **The English listing exists as of 2026-08-25**, when the interface got
a second language: the rule was «no listing until there is a language of
operation», and now there is one.

The Spanish listing stays the default. Play shows the English one only to a
store set to English, which is the same criterion the application itself uses —
the phone decides, unless somebody says otherwise.

## What this listing is for, and what it must not do

The people who install this are volunteers and coordinators at a collection
centre, usually because somebody at that centre told them to. **Nobody
discovers this application by browsing Play.** So the listing is not
advertising: it is confirmation that this is the right application and a
description of what it does on a phone.

Two things it must not claim:

- **That it works without connection, flatly.** Reading works offline and one
  write works offline — capture. Saying «funciona sin internet» would promise
  that sealing and shipping do too, and somebody would find out in a basement.
- **That it replaces the panel.** It does what a phone does better. Shipments,
  reports and the catalogue are still the web's.

## Fields

### App name (30 characters)

```
Araguaney
```

### Short description (80 characters)

```
Captura donaciones, escanea cajas y sigue los envíos de tu centro de acopio.
```

Seventy-five characters. It names the three things somebody does every day, in
the order they do them.

### Full description (4000 characters)

```
Araguaney es la aplicación móvil de la plataforma de logística humanitaria del
mismo nombre. Está hecha para quien trabaja en un centro de acopio: registrar lo
que llega, sellarlo en cajas, armar tarimas y despachar envíos.

QUÉ HACE

• Captura de donaciones. Registra lo que llegó —producto, cantidad, lote y
  caducidad— y genera las cajas con su etiqueta.
• Escaneo con la cámara. Lee la etiqueta QR de una caja o una tarima y abre su
  ficha, y lee el código de barras del envase de un producto para encontrarlo en
  el catálogo sin teclear su nombre.
• Cajas y tarimas. Consulta el inventario del centro, sella cajas y arma
  tarimas.
• Envíos. Abre un envío, mete tarimas, ciérralo y despáchalo.
• Avisos. Recibe notificaciones de lo que pasa en tu centro.

SIN SEÑAL

Un centro de acopio suele estar en un sótano, un almacén o una carpa. Por eso el
catálogo, el stock y las cajas se descargan y se pueden consultar sin conexión.

Y la captura de donaciones se puede hacer sin señal: queda guardada en el
teléfono y se envía sola cuando vuelve la conexión, sin duplicarse. Es la única
operación que funciona así, y a propósito: sellar una caja o cerrar un envío
dependen de lo que estén haciendo otras personas en ese mismo momento, y
decidirlo a ciegas produciría dos verdades sobre la misma caja.

PARA QUIÉN

Para el voluntariado y la coordinación de un centro de acopio con cuenta en la
plataforma. No es una aplicación para donar: si quieres donar, entra en
araguaney.lat.

Cada persona ve lo que su rol permite, y quien coordina un centro ve además lo
que exige una decisión suya.

CÓDIGO ABIERTO

El código de esta aplicación es público y se puede auditar. Cualquiera puede
compilarla desde su repositorio sin pedirnos permiso ni claves.
```

Around 1,600 characters, well inside the limit. Long enough to answer «is this
the right app and what will it do», short enough that somebody reads it.

## The English listing

Same three fields, same claims, same restraint. It is a translation of the
decisions above and not a second piece of copy: if one changes, both change.

### App name (30 characters)

```
Araguaney
```

### Short description (80 characters)

```
Capture donations, scan boxes and follow your centre's shipments.
```

Sixty-four characters. The same three things, in the same order.

### Full description

```
Araguaney is the mobile application of the humanitarian logistics platform of
the same name. It is built for the people working at a collection centre:
registering what arrives, sealing it into boxes, building pallets and
dispatching shipments.

WHAT IT IS FOR

· Registering a donation at the counter, with or without a connection.
· Scanning the QR code of a box, a pallet or an announced donation.
· Finding a product by the barcode on its package.
· Following a shipment from the moment it is opened until what arrived is
  registered.
· Reading how the campaign is going: stock by category, shrinkage, weight.

WITHOUT A CONNECTION

Capturing a donation works in a basement. What is captured waits on the phone
and is sent on its own when there is signal again, once — never twice, however
many times it is retried.

Reading works too: the catalogue and the centre's boxes are downloaded so they
can be consulted without signal.

Everything else needs a connection, and the application says so rather than
failing: sealing a box, closing a pallet or dispatching a shipment are decisions
that two people can be making at the same time from two phones.

WHO IT IS FOR

You need an account at a collection centre that already uses Araguaney. This
application does not create accounts and is not open to the public; if your
centre is not registered yet, the application shows you where to apply.

MADE FOR REAL CONDITIONS

Old phones, bad signal, hands full. Large text, few taps, and nothing that
cannot be undone without asking first.
```

## Graphics

| Asset | Size | Where it comes from |
|---|---|---|
| App icon | 512 × 512 | `assets/icon/ic_launcher.png` — the tree on the cream, opaque, no border of its own since Play rounds the corners |
| Feature graphic | 1024 × 500 | Generated from the same tree on the design's cream |
| Phone screenshots | at least 2 | Captured from a **release** build, so there is no debug banner |

The screenshots come from a real session against production, which means they
show real counts. That is a deliberate choice over mocked data: a listing whose
screenshots do not match what the application looks like is a small lie that
somebody notices on their first launch.

## Content declarations, which are not copy

Play asks for these before it will publish to any track beyond internal, and
they are decisions rather than text:

- **Privacy policy**: `https://araguaney.lat/aviso-de-privacidad`, already
  served by the web.
- **Data safety**: the application handles account data and donor names typed
  by an operator. It does not collect location, contacts or advertising
  identifiers. Crash reports go to Sentry with no request bodies and no personal
  data — see `lib/main.dart`.
- **Ads**: none.
- **Target audience**: adults; this is a workplace tool.
- **Financial features**: none. The application never touches money.
