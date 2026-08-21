import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/queued_captures_table.dart';

part 'capture_queue_dao.g.dart';

/// Acceso a la cola de capturas.
///
/// **Toda consulta lleva `userId`.** No es una precaución de más: en un
/// dispositivo de centro que se comparte entre turnos, una consulta sin filtrar
/// enviaría las capturas de otra persona con la sesión de quien está delante.
@DriftAccessor(tables: [QueuedCaptures])
class CaptureQueueDao extends DatabaseAccessor<AppDatabase>
    with _$CaptureQueueDaoMixin {
  CaptureQueueDao(super.db);

  Stream<List<QueuedCaptureRow>> watchAll(String userId) =>
      (select(queuedCaptures)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  /// Cuántas capturas de esta persona siguen esperando señal.
  Stream<int> watchPendingCount(String userId) {
    final total = queuedCaptures.captureId.count();
    final query = selectOnly(queuedCaptures)
      ..addColumns([total])
      ..where(
        queuedCaptures.userId.equals(userId) &
            queuedCaptures.status.equalsValue(QueuedCaptureStatus.pending),
      );

    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  /// Las que toca intentar, en el orden en que se capturaron.
  Future<List<QueuedCaptureRow>> pending(String userId) =>
      (select(queuedCaptures)
            ..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(QueuedCaptureStatus.pending),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<QueuedCaptureRow?> findById(String captureId) => (select(
    queuedCaptures,
  )..where((t) => t.captureId.equals(captureId))).getSingleOrNull();

  /// Encola. Si esa llave ya estaba, no se duplica: la clave primaria lo
  /// impide y esta escritura no la pisa.
  Future<void> enqueue(QueuedCaptureRow row) =>
      into(queuedCaptures).insert(row, mode: InsertMode.insertOrIgnore);

  /// Cuenta un intento. El incremento lo hace SQLite sobre el valor de la fila
  /// y no un número leído antes: dos vaciados solapados no pueden perder la
  /// cuenta del otro.
  Future<void> markAttempt(String captureId, DateTime at) => customUpdate(
    'UPDATE queued_captures SET attempts = attempts + 1, '
    'last_attempt_at = ? WHERE capture_id = ?',
    variables: [Variable<DateTime>(at), Variable<String>(captureId)],
    updates: {queuedCaptures},
  );

  /// Aparca una captura rechazada con el motivo del servidor a la vista.
  Future<void> markRejected(
    String captureId, {
    required String code,
    required String message,
    required DateTime at,
  }) => (update(queuedCaptures)..where((t) => t.captureId.equals(captureId)))
      .write(
        QueuedCapturesCompanion(
          status: const Value(QueuedCaptureStatus.rejected),
          lastFailureCode: Value(code),
          lastFailureMessage: Value(message),
          lastAttemptAt: Value(at),
        ),
      );

  /// Registra por qué falló un intento que sí se va a repetir.
  Future<void> markRetryable(
    String captureId, {
    required String code,
    required String message,
    required DateTime at,
  }) => (update(queuedCaptures)..where((t) => t.captureId.equals(captureId)))
      .write(
        QueuedCapturesCompanion(
          lastFailureCode: Value(code),
          lastFailureMessage: Value(message),
          lastAttemptAt: Value(at),
        ),
      );

  /// Devuelve a la cola una captura aparcada.
  ///
  /// Aparcar es dejar de reintentar **solo**, no cerrar el caso: el rechazo
  /// suele describir algo que alguien puede resolver fuera —una aprobación que
  /// falta, un producto que se dio de alta—, y entonces reintentar es la
  /// respuesta correcta. Hasta ahora la única salida ofrecida era descartar, y
  /// tirar inventario para resolver un trámite es la peor de las dos.
  ///
  /// El motivo anterior se borra porque ya no describe el estado de la fila;
  /// [attempts] no se toca, porque los intentos ocurrieron. Y la llave de
  /// idempotencia sigue siendo la misma, así que reintentar no puede duplicar.
  Future<void> requeue(String captureId) =>
      (update(
        queuedCaptures,
      )..where((t) => t.captureId.equals(captureId))).write(
        const QueuedCapturesCompanion(
          status: Value(QueuedCaptureStatus.pending),
          lastFailureCode: Value(null),
          lastFailureMessage: Value(null),
        ),
      );

  /// Saca una captura de la cola. La llaman dos sitios: el envío exitoso y el
  /// descarte explícito de una persona. Nada más borra de aquí.
  Future<void> remove(String captureId) => (delete(
    queuedCaptures,
  )..where((t) => t.captureId.equals(captureId))).go();
}
