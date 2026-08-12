import 'package:drift/drift.dart';

/// En qué punto está una captura encolada.
enum QueuedCaptureStatus {
  /// Esperando señal. Se reintenta sola.
  pending,

  /// El servidor la rechazó por una regla de negocio. **Deja de reintentarse**
  /// y espera una decisión de una persona: reintentar algo que ya fue
  /// rechazado da la misma respuesta para siempre.
  rejected,
}

/// Capturas hechas sin señal, esperando a salir del sótano.
///
/// Tres columnas sostienen las invariantes de la cola:
///
/// - [captureId] es la **clave primaria**. La llave de idempotencia se genera
///   antes del primer intento y no cambia nunca; que sea la clave de la tabla
///   hace imposible encolar dos veces la misma captura, y lo garantiza SQLite
///   en vez de una comprobación que alguien pueda olvidar.
/// - [userId] hace la cola de cada persona. Un dispositivo de centro se
///   comparte, y cambiar de turno no puede enviar las capturas del anterior.
/// - [payload] guarda la petición **ya construida**, en JSON. Lo que sale del
///   sótano es exactamente lo que se capturó: ni el catálogo que cambió
///   mientras tanto ni una migración de la interfaz pueden reescribirlo.
@DataClassName('QueuedCaptureRow')
class QueuedCaptures extends Table {
  TextColumn get captureId => text()();
  TextColumn get userId => text()();

  /// Cuerpo de `POST /v1/intakes` serializado.
  TextColumn get payload => text()();

  /// Resumen legible para la pantalla de pendientes, calculado al encolar: no
  /// hace falta volver a interpretar el payload para decir qué hay dentro.
  TextColumn get summary => text()();
  IntColumn get boxCount => integer()();

  TextColumn get status => textEnum<QueuedCaptureStatus>()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Código y mensaje del último rechazo, para que la pantalla muestre el
  /// motivo del servidor tal cual.
  TextColumn get lastFailureCode => text().nullable()();
  TextColumn get lastFailureMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {captureId};
}
