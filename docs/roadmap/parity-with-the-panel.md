# What the panel does and this application does not

> Derived, not remembered. The lists below come from three sources that can be
> read again at any time: the panel's own navigation
> (`src/lib/nav-config.ts` in the web repository), the routes under
> `app/dashboard/` and `app/studio/`, and which operations of the vendored
> `api/openapi.json` this repository actually calls.

---

## Why this file exists

The roadmap was never a port of the panel, and that was right: this application
is a thin layer that adds what a phone does better — the camera, capture
without a signal, and notices. Phases 00 to 07 follow exactly that.

What went wrong is narrower and it is the same failure this repository keeps
paying for. **Phase 10 was where parity with the panel was supposed to live, and
it is excluded from the totals on purpose** — so the board could read as 88 %
complete while most of the panel had no counterpart here. And that backlog is
itself a hand-kept list of fourteen blocks that never mentioned the catalogue,
campaigns, centres, the application queue, the audit log or the studio.

A list nobody derives cannot contain what nobody thought to write down. The
screen table in Phase 11 failed the same way, and the fix is the same: derive
it.

## How to regenerate the coverage number

```
python3 - <<'EOF'
import re, pathlib
methods = {}
for f in pathlib.Path('lib/core/api/generated/clients').glob('*.dart'):
    if f.name.endswith('.g.dart'): continue
    for m in re.finditer(
        r"@(GET|POST|PATCH|PUT|DELETE)\('([^']+)'\)\s*\n\s*Future<[^\n]*?>\s+(\w+)\(",
        f.read_text()):
        methods[m.group(3)] = (m.group(1), m.group(2))
blob = '\n'.join(f.read_text() for f in pathlib.Path('lib').rglob('*.dart')
                 if 'generated' not in f.parts)
hand = set(re.findall(r"'(/v1/[^']*)'", blob))
unused = [v for k, v in methods.items() if k not in blob and v[1] not in hand]
print(f"{len(methods)} generated, {len(methods) - len(unused)} used, {len(unused)} unused")
EOF
```

**On 2026-08-24: 161 generated, 69 used, 92 unused.** Fifty-seven per cent of
the contract is generated and never spent. That number is not a target — plenty
of those routes belong to the donor-facing web and should never be called from
here — but it is the number that made the gap visible, and it belongs in a file
rather than in somebody's memory.

## The panel, module by module

Roles are the panel's own, from `nav-config.ts`.

| Panel module | Roles | Here |
|---|---|---|
| Inicio | coordinator, volunteer | ✅ |
| Nacional | national_admin | 🟡 «Stock por categoría» only; weight and summary missing |
| Cajas | all | ✅ |
| Tarimas | national_admin, coordinator | ✅ |
| Envíos | national_admin, coordinator | 🟡 opened, filled, closed and dispatched; reception, milestones, declaration and delivery missing — [Phase 26](phase-26-shipment-to-delivery.md) |
| Campañas | coordinator, volunteer | 🟡 members only; the campaign list and its editing missing — [Phase 20](phase-20-campaigns.md) |
| Registrar entrada | all | ✅ (printed labels missing) |
| Donaciones | all | ❌ [Phase 18](phase-18-preregistered-donations.md) |
| Escanear | all | ✅ |
| Transferencias | national_admin, coordinator | 🟡 read and resolved; cannot be created — [Phase 27](phase-27-create-a-transfer.md) |
| Revisiones | national_admin, coordinator | ✅ |
| Informes | all | ❌ [Phase 19](phase-19-center-reports.md) |
| Equipo | all | ✅ |
| Mensajes | all | ✅ (attachments missing) |
| Ayuda | all | ❌ — and deliberately: see below |

### Administration, inside the panel

| Panel module | Here |
|---|---|
| Campañas | ❌ [Phase 20](phase-20-campaigns.md) |
| Centros | 🟡 read, created and edited; deactivating stays on the panel — [Phase 21](phase-21-centers.md) |
| Usuarios | ❌ [Phase 24](phase-24-users-beyond-a-center.md) |
| Postulaciones de centro | ✅ [Phase 22](phase-22-center-applications.md) |
| Incidencias | ✅ [Phase 23](phase-23-incidents-and-audit.md) |
| Auditoría | ❌ [Phase 23](phase-23-incidents-and-audit.md) |

### The studio, the superadmin console

Seven routes — metrics, users, applications, emails, AI usage, audit, settings —
and none of them here. [Phase 25](phase-25-the-studio.md).

### Two routes the panel has and does not offer either

Worth naming so they are not mistaken for something this application lost.

- **`/dashboard/catalog` and `/dashboard/catalog/new`** exist as pages and are
  **not in the panel's navigation**: nothing links to them, so today somebody
  reaches the product catalogue by typing the URL. It is still the module most
  worth having on a phone, because the person who discovers that a product is
  missing is holding it. [Phase 17](phase-17-product-catalogue.md).
- **`/dashboard/requests`** is **commented out** of `nav-config.ts`. The board
  exists, the routes answer, and the panel does not offer it.
  [Phase 28](phase-28-the-requests-board.md) says what it would take and why it
  waits for the panel to decide first.

## What is deliberately not coming

- **The donor-facing flow.** `POST /v1/public/donations` and the sixteen routes
  around it are how a person registers a donation from the website: photos,
  a management token, cancelling. That is the public web's job. This
  application's side of a pre-registered donation is receiving it, which is
  Phase 18.
- **Registration and email verification.** Somebody reaches a centre through an
  invitation. Recorded in Phase 14 and unchanged.
- **Help articles.** They are long-form reading with a slug per article, served
  and translated by the web. A phone that can open the panel can open them.
- **Printing.** Labels, manifests and declarations as PDF or XLSX are produced
  by the panel. The application asks for one and hands it to the system viewer;
  it does not render them.

## Two defects this review turned up

Neither is a missing module, and both are cheap.

1. **`GET /v1/client/version` is never called.** `ClientVersionGate` exists,
   has tests, and no file invokes it. The minimum-supported-version mechanism
   that the architecture describes as the reason an old binary stays safe is
   not wired. [Phase 29](phase-29-the-version-gate.md).
2. **A national administrator cannot write from here.**
   `resolve_write_center_id` requires them to name a `center_id` in the body of
   every create, because they belong to no centre; `IntakeCreate` carries the
   field and this application never sets it. So the two superadmin accounts can
   read everything and register nothing.
   [Phase 30](phase-30-writing-as-national-admin.md).
