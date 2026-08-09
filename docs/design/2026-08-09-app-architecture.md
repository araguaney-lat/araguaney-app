# Diseño de arquitectura — Araguaney App

**Fecha:** 2026-08-09
**Estado:** aprobado
**Alcance:** decisiones de arquitectura del cliente móvil previas a la primera línea de código.

Este documento registra qué se decidió y por qué, incluidas las alternativas que se
evaluaron y se descartaron. Las reglas de dominio citadas (frontera offline, contrato
aditivo, controles de riesgo) se originan en el backend y están documentadas en el
repositorio [`araguaney-lat/araguaney`](https://github.com/araguaney-lat/araguaney);
aquí se referencian como restricciones que este cliente hereda, no como decisiones
propias.

---

## 1. Premisas

1. **La aplicación es una capa fina.** Toda regla de negocio vive en el backend y se
   aplica allá. El cliente captura, escanea, consulta y sincroniza. Si una feature
   exige lógica en el cliente, la primera pregunta es si al backend le falta un
   endpoint.
2. **El contrato es `/v1` solo-aditivo.** Un binario instalado hace meses debe seguir
   funcionando. El backend publica la versión mínima soportada
   (`GET /v1/client/version`) para que una instalación vieja pida actualización en
   lugar de fallar en silencio.
3. **El repositorio es público** y cualquier organización puede compilar su propia
   versión. Eso condiciona licencia, gestión de configuración (nada de proyectos de
   infraestructura propios en el repo) y la relación con servicios de terceros.
4. **El valor diferencial del móvil** sobre la web responsive existente es concreto:
   cámara nativa para escaneo QR continuo, captura sin conexión en entornos de baja
   cobertura y notificaciones push de eventos operativos. La paridad con el resto del
   panel web es objetivo de largo plazo, no criterio de la primera versión.

## 2. Elección de framework

**Decisión: Flutter.**

| Alternativa | Evaluación |
|---|---|
| **Flutter** | Un solo código para ambas plataformas con render propio (no webview). Ecosistema maduro para las necesidades específicas de este cliente: `mobile_scanner` (escaneo QR con cámara), Drift (SQLite tipado para cache y cola offline), tooling de análisis y formato de primera. Riesgo aceptado: Dart es un lenguaje minoritario y reduce el pool de contribuidores potenciales frente a TypeScript; se mitiga con arquitectura clara y documentación de contribución. |
| React Native + Expo | Compartiría lenguaje con el frontend web (TypeScript). Se descartó por la menor ergonomía de la capa SQLite/offline, mayor rotación del ecosistema y porque el flujo de builds empuja hacia servicios de pago. |
| Kotlin Multiplatform / Compose Multiplatform | El soporte iOS aún no tiene la madurez necesaria para apostarle un producto operativo. |
| PWA / Capacitor sobre la web existente | La web ya ofrece captura offline, pero no da push confiable en iOS, ni escaneo de cámara de calidad, ni presencia en tiendas. No aporta el diferencial buscado. |

## 3. Estructura del proyecto

- Organización **feature-first**, no por tipo:

```
lib/
  core/        # api (cliente generado), auth, db (Drift), push, config, i18n
  features/
    intake/    # data / domain / ui
    boxes/
    scan/
    pallets/
    shipments/
    dashboard/
test/          # espejo de lib/
api/
  openapi.json # snapshot vendoreado del contrato del backend
```

- Estado con **Riverpod** (codegen): testeable y sin la ceremonia de alternativas más
  pesadas. Se evaluó Bloc con arquitectura hexagonal estricta y se descartó: para el
  tamaño del equipo, el boilerplate cuesta más de lo que protege.
- Convenciones de idioma idénticas al backend: identificadores en inglés, prosa de
  producto en español, prosa para contribuidores en inglés.

## 4. Contrato con la API: cliente generado

- El backend (FastAPI) publica su especificación OpenAPI. Este repositorio **vendorea
  un snapshot** (`api/openapi.json`) y de él se genera el cliente Dart (dialecto
  `dio`). Nadie escribe modelos a mano dos veces.
- Actualizar el contrato es un PR que actualiza el snapshot y regenera el cliente: el
  diff es revisable, los builds son deterministas y un fork puede compilar sin acceso
  a ningún backend en vivo.
- Las pruebas de contrato del backend garantizan que un snapshot nuevo nunca rompe a
  un cliente viejo (compatibilidad aditiva dentro de `/v1`).

## 5. Autenticación

- Login directo contra `/v1/auth/login`; el backend emite access y refresh token y
  rota el refresh en cada renovación.
- **Refresh token en el almacén seguro de la plataforma** (Keychain en iOS, Keystore
  en Android) vía `flutter_secure_storage`. **Access token solo en memoria.** Nunca en
  SharedPreferences ni en archivos.
- Interceptor HTTP: ante 401, renueva, reintenta una vez y, si falla, cierra la sesión
  local.
- Los flujos de TOTP y de cambio forzado de contraseña ya existen en el backend; el
  cliente solo aporta las pantallas.

## 6. Modelo offline

### 6.1 Lectura

Disponible sin conexión en su totalidad: catálogo, stock y cajas del centro se cachean
en la base local (Drift) y se refrescan al abrir la aplicación y por acción explícita.

### 6.2 Escritura: la frontera es una regla de dominio

**Solo la captura de donaciones (intake) escribe sin conexión.** Es la única operación
que depende exclusivamente de lo que la persona tiene enfrente. Sellar una caja, armar
una tarima o cerrar un envío dependen de estado compartido que puede estar cambiando
en otro dispositivo; decidirlo sin conexión produciría dos verdades sobre la misma
caja, y ese error termina en un manifiesto incorrecto frente a una aduana. Estas
operaciones exigen conexión y la interfaz explica el motivo.

La cola de captura porta las mismas invariantes que la captura offline de la
aplicación web:

1. La llave de idempotencia (`capture_id`) se genera **antes** del primer intento y no
   cambia nunca: reintentar es el caso normal, no la excepción.
2. El catálogo local conserva la visibilidad por campaña del servidor: un producto
   elegible sin señal es uno que el servidor va a aceptar.
3. La cola es **por usuario**: un dispositivo compartido nunca atribuye la captura de
   una persona a la sesión de otra.
4. **Nada se descarta solo**: un rechazo de negocio deja de reintentarse y espera una
   decisión humana explícita, con el motivo del servidor visible.

Los códigos de caja se reservan con conexión para gastarse sin ella; una captura
rechazada no devuelve sus códigos al bloque, porque la etiqueta física con ese número
puede estar ya pegada a una caja.

### 6.3 Sincronización

En primer plano al abrir la aplicación, con contador visible de pendientes. La
instrucción operativa es la misma que en la web: al recuperar señal, abrir la
aplicación y esperar a que el contador llegue a cero. Queda abierta la puerta a
sincronización oportunista en segundo plano (p. ej. `workmanager`) como mejora
posterior que no cambia el diseño.

## 7. Notificaciones push

- **Firebase Cloud Messaging es la única pieza de Firebase que se usa.** No se adopta
  Firebase Auth, Firestore ni Analytics: autenticación, datos y almacenamiento son del
  backend propio.
- El acceso a FCM queda **aislado detrás de una interfaz interna** (`PushService`).
  Consecuencia deliberada: existe un sabor de build `foss` que compila sin ninguna
  dependencia de Firebase, con push desactivado. Eso permite a un fork operar sin
  proyecto de Firebase y deja abierta la distribución por canales que excluyen
  servicios propietarios (p. ej. F-Droid).
- Cada fork que quiera push usa su propio proyecto de Firebase. Los archivos de
  configuración (`google-services.json` y equivalentes) **no se versionan**; se
  documentan con plantillas.
- El lado servidor (registro de tokens por dispositivo y despacho de eventos) se
  implementa en el repositorio del backend como una fase propia de su roadmap.

## 8. Observabilidad

- Sentry (SDK de Flutter) para errores y crashes, con mensajes genéricos a la persona
  operadora y detalle técnico solo en el evento.
- El DSN se inyecta por configuración de build; el sabor `foss` y los forks pueden
  operar sin Sentry.

## 9. Licencia

**GNU GPL v3.0 o posterior, con permiso adicional bajo la sección 7 para distribución
por tiendas de aplicaciones** (ver `LICENSE` y `LICENSE-EXCEPTIONS.md`).

Razonamiento:

- El backend es AGPL-3.0. Cliente y servidor son programas separados que se comunican
  por red, así que no hay interacción de licencias entre repositorios; la elección del
  cliente se hace por sus propios méritos.
- Se busca copyleft: un fork de la aplicación debe publicar su código, coherente con
  el espíritu del proyecto.
- La distribución de software GPL por tiendas de aplicaciones tiene un conflicto
  conocido entre las condiciones de esas plataformas y la licencia. El mecanismo
  estándar para resolverlo es un permiso adicional bajo la sección 7 de la GPLv3, que
  autoriza expresamente la distribución por tiendas siempre que el código fuente
  completo siga disponible bajo la licencia.
- Se evaluaron AGPL-3.0 con acuerdo de licencia de contribuidor (fricción alta para
  contribuciones externas) y MPL-2.0 (permitiría forks propietarios). Ambas se
  descartaron.

## 10. Calidad y pruebas

- Piso de cobertura: 80 %. Pruebas unitarias y de widget para todo comportamiento
  nuevo.
- La capa de base local y la cola offline se prueban contra **SQLite real en
  memoria**, no contra dobles: la mayoría de los defectos de esa capa viven en el
  manejo de transacciones y un doble no los reproduce. (Mismo criterio que llevó a la
  web a probar contra una IndexedDB real.)
- Golden tests para pantallas críticas de representación (ficha y etiqueta de caja).
- Pruebas de integración del flujo captura → caja en emulador dentro de CI.
- Gates de PR: `flutter analyze` sin issues, `dart format` aplicado, `flutter test`
  en verde.

## 11. Infraestructura de desarrollo y distribución

- **CI: GitHub Actions.** En repositorios públicos los runners (incluidos los de
  macOS, necesarios para builds de iOS) no tienen costo, lo que permite construir y
  probar ambas plataformas sin servicios adicionales.
- **Android:** distribución por Google Play (internal testing → closed testing →
  producción). Firma con keystore propio, fuera del repositorio.
- **iOS:** el desarrollo y las pruebas locales no requieren cuenta de pago; la
  distribución (TestFlight y App Store) requiere membresía del Apple Developer
  Program y se activará cuando esa vía se priorice.
- **Sabores de build:** `dev` / `prod` (y `foss`) mediante `--dart-define`
  (URL de API, banderas de capacidades).

## 12. Riesgos aceptados y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Deriva entre cliente y API | Snapshot OpenAPI vendoreado + pruebas de contrato en el backend + contrato aditivo |
| Pool de contribuidores Dart menor que el de TypeScript | Arquitectura feature-first clara, CONTRIBUTING explícito, CI que hace evidente el estándar |
| Doble mantenimiento web + app | La app se mantiene fina: ante lógica nueva, primero se evalúa si falta un endpoint |
| Reimplementar la cola offline que ya existe en la web | Se reimplementan **invariantes documentadas como contrato**, no código traducido; las cuatro invariantes tienen pruebas propias en cada plataforma |
| Dependencia de servicios propietarios (FCM) | Aislada tras interfaz propia; el sabor `foss` compila sin ella |
