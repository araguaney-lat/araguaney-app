# CLAUDE.md — Araguaney App (cliente móvil Flutter)

> Contexto para asistentes de código. Define **qué** es este repositorio y con **qué reglas** se trabaja en él.
> El diseño detallado vive en `docs/design/`. El backend y sus reglas de dominio viven en
> [`araguaney-lat/araguaney`](https://github.com/araguaney-lat/araguaney).

---

## REGLA #1 — Git: nunca push a main

**NUNCA hagas `git push` directamente a `main`, sin importar la situación.**

Todo cambio sigue este flujo sin excepción:

1. Crear rama desde `main`:
   ```
   git checkout main && git pull
   git checkout -b feat/mi-feature   # o fix/, refactor/, chore/, docs/
   ```
2. Hacer commits en la rama.
3. Esperar que el usuario pida explícitamente el push: `"haz push"` / `"push"`.
4. Solo entonces: `git push -u origin <rama>`.
5. El PR también requiere aprobación explícita: `"crea el PR"` / `"abre el PR"`.

**Comandos bloqueados sin aprobación explícita:** `git push` (cualquier rama), `gh pr create`,
cualquier operación destructiva de git (`reset --hard`, `branch -D`, etc.).

**Nunca más de 1 PR abierto a la vez.** Antes de crear un PR: `gh pr list --state open`.
Si ya hay uno abierto, se trabaja sobre esa rama.

## REGLA #2 — Este repositorio es público: revisa el diff antes de pushear

Después del push no hay vuelta atrás: GitHub conserva los commits por SHA aunque se
edite o aplaste la rama. Antes de `git push` y de `gh pr create`, leer el diff completo
con ojos de lector externo, incluido uno adversario, y confirmar que no va nada de esto:

- Credenciales, tokens, identificadores de proyectos de infraestructura (Firebase,
  Sentry DSN privados, keystores, `google-services.json`).
- Parámetros de controles de seguridad del backend: umbrales, límites, ventanas.
  Se publica el mecanismo, nunca el valor que determina cuándo salta.
- Texto que explique cómo evadir un control del sistema.
- Archivos colados por un `git add -A` sin revisar.

## REGLA #3 — Los PR se escriben en inglés y español, en registro formal

Título en inglés. Cuerpo con `## English` primero y `## Español` después, con el mismo
contenido. Registro formal: se describe el cambio, no el proceso de escribirlo.
Estructura mínima: qué problema resuelve, cómo, qué **no** cambia, cómo se verificó,
plan de prueba cuando el cambio se toca desde la interfaz.

---

## 1. Qué es esta aplicación

Cliente móvil (Android/iOS, Flutter) de la plataforma Araguaney. Es una **capa fina**
sobre la API `/v1` del backend:

- **Cero lógica de negocio propia.** Validaciones, máquinas de estado, scoping de
  tenant y controles de riesgo viven en el backend y se aplican allá. Si una feature
  parece pedir lógica en el cliente, lo correcto casi siempre es un endpoint nuevo.
- Aporta lo que el móvil hace mejor que la web: escaneo QR con cámara nativa, captura
  de donaciones sin conexión y notificaciones push de eventos operativos.
- Puede correr un binario de hace meses: el contrato `/v1` es solo-aditivo y
  `GET /v1/client/version` publica la versión mínima soportada.

## 2. Decisiones de arquitectura

| Tema | Decisión |
|---|---|
| Estructura | Feature-first: `lib/features/<feature>/{data,domain,ui}` + `lib/core/` |
| Estado | Riverpod, línea 2.6 con providers manuales (`Notifier`). La migración a 3.x + codegen está pendiente de que `riverpod`/`riverpod_generator` sean compatibles con los pins de `flutter_test` del Flutter stable vigente |
| HTTP | `dio` + cliente Dart **generado** del snapshot OpenAPI vendoreado en `api/openapi.json` |
| DB local | Drift (SQLite tipado): cache de lectura + cola de captura offline |
| Auth | JWT del backend; refresh token en Keychain/Keystore (`flutter_secure_storage`), access token solo en memoria; interceptor que rota en 401 |
| Push | Firebase Cloud Messaging detrás de una interfaz propia; el sabor `foss` compila sin Firebase |
| QR | `mobile_scanner` |
| Errores | Sentry Flutter |
| Sabores | `dev` / `prod` (y `foss`) vía `--dart-define` |

**El cliente generado no se edita a mano.** Para adoptar capacidades nuevas del
backend: actualizar el snapshot en su propio commit y regenerar. El diff del snapshot
es revisable y los builds son deterministas; un fork compila sin acceso al backend.

## 3. Frontera offline (regla de dominio, no limitación)

- **Lectura offline total:** catálogo, stock y cajas del centro se cachean en Drift y
  se refrescan con conexión.
- **Escritura offline: solo la captura de donaciones (intake).** Es la única operación
  que depende solo de lo que la persona tiene enfrente. Sellar cajas, armar tarimas y
  cerrar envíos dependen de estado compartido que puede estar cambiando en otro
  dispositivo; decidirlo a ciegas produciría dos verdades sobre la misma caja. Exigen
  conexión y la interfaz explica por qué.

La cola de captura porta las mismas invariantes que la captura offline de la web:

1. **La llave de idempotencia (`capture_id`) se genera antes del primer intento** y no
   cambia nunca. Reintentar es el caso normal al salir de un sótano.
2. **El catálogo local conserva la visibilidad por campaña del servidor.** Un producto
   elegible sin señal tiene que ser uno que el servidor va a aceptar.
3. **La cola es por usuario.** Un dispositivo se comparte; cambiar de sesión nunca
   envía capturas de otra persona.
4. **Nada se descarta solo.** Un rechazo de negocio deja de reintentarse y espera una
   decisión explícita de una persona, con el motivo del servidor visible.

Los códigos de caja se reservan con señal para gastarse sin ella
(`box_code_reservations` en el backend); una captura rechazada no devuelve sus códigos
al bloque, porque la etiqueta física ya puede estar pegada.

## 4. Convenciones de código

- **Identificadores en inglés** (funciones, variables, clases, archivos, rutas).
  **Prosa de producto en español** (textos de interfaz, mensajes de error al operador).
  **Prosa para contribuidores en inglés** (commits, PR, README/CONTRIBUTING/SECURITY).
- **Toda la documentación del repositorio va en inglés**, incluido todo `docs/`.
  Esta regla difiere a propósito del repositorio del backend (donde el roadmap y el
  razonamiento de dominio quedaron en español): aquí la audiencia primaria de `docs/`
  es quien evalúa, compila o contribuye desde fuera. La única excepción es este
  archivo, que mantiene el español por consistencia con su par del backend.
- Nombres de tests en inglés; la frase explicativa va en el docstring o el mensaje del
  `assert`.
- Archivos chicos y enfocados; feature-first, no por tipo.
- `flutter analyze` limpio y `dart format` aplicado como gate de todo PR.
- Lo que toca Drift o la cola offline se prueba contra SQLite real en memoria, no
  contra dobles: la mitad de los errores de esa capa viven en las transacciones.

## 5. Seguridad del cliente

- Tokens: refresh en Keychain/Keystore, access solo en memoria. Nunca en SharedPreferences
  ni en disco plano.
- Nada de secretos en el repo: `google-services.json`, keystores y DSN van por
  configuración local o CI, con plantillas documentadas.
- Los mensajes de error al operador son genéricos; el detalle va a Sentry.

## 6. Definition of Done (por tarea)

- Comportamiento nuevo cubierto por test (unit o widget según corresponda).
- `flutter analyze` sin issues, `dart format` aplicado, `flutter test` en verde.
- Sin lógica de negocio duplicada del backend.
- Sin secretos ni configuración de infraestructura en el diff.
- Si toca la cola offline: las cuatro invariantes de la sección 3 siguen cubiertas por tests.
