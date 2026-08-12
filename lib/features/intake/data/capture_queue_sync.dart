import 'dart:convert';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/intakes_api.dart';
import '../../../core/api/generated/models/intake_create.dart';
import '../../../core/db/app_database.dart';

/// Cómo terminó un vaciado de la cola.
class QueueFlushReport {
  const QueueFlushReport({
    required this.sent,
    required this.parked,
    required this.remaining,
    this.stoppedBy,
  });

  /// Capturas que el servidor aceptó y salieron de la cola.
  final int sent;

  /// Capturas que quedaron aparcadas esperando una decisión de una persona.
  final int parked;

  /// Las que siguen pendientes de reintento.
  final int remaining;

  /// Por qué se cortó el vaciado, cuando se cortó.
  final ApiFailure? stoppedBy;

  bool get didAnything => sent > 0 || parked > 0;
}

/// Envía lo que la cola tiene guardado.
///
/// Recorre las capturas de **una** persona en el orden en que se hicieron y se
/// detiene al primer fallo que no dependa de la captura: sin señal, seguir
/// intentando las siguientes solo gasta batería para obtener el mismo error.
class CaptureQueueSync {
  CaptureQueueSync({
    required IntakesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _intakes = api,
       _db = database,
       _now = now ?? DateTime.now;

  final IntakesApi _intakes;
  final AppDatabase _db;
  final DateTime Function() _now;

  Future<QueueFlushReport> flush(String userId) async {
    final pending = await _db.captureQueueDao.pending(userId);
    var sent = 0;
    var parked = 0;
    ApiFailure? stoppedBy;

    for (final row in pending) {
      await _db.captureQueueDao.markAttempt(row.captureId, _now());

      try {
        // El cuerpo se reconstruye desde el JSON guardado, no desde el
        // formulario: reintentar tiene que enviar lo mismo que se capturó.
        await _intakes.createIntakeV1IntakesPost(
          body: IntakeCreate.fromJson(
            jsonDecode(row.payload) as Map<String, Object?>,
          ),
        );
        // El servidor es idempotente por `capture_id`: si esta captura ya
        // estaba registrada, devuelve la que registró en vez de duplicarla, y
        // el resultado es el mismo que si acabara de llegar.
        await _db.captureQueueDao.remove(row.captureId);
        sent++;
      } on Object catch (error) {
        final failure = ApiErrorMapper.fromAny(error);

        if (_belongsToTheCapture(failure)) {
          // El servidor ya decidió sobre esta captura. Volver a mandarla daría
          // la misma respuesta para siempre, así que deja de reintentarse y
          // espera a que una persona la mire, con el motivo a la vista.
          await _db.captureQueueDao.markRejected(
            row.captureId,
            code: failure.code,
            message: failure.operatorMessage,
            at: _now(),
          );
          parked++;
          continue;
        }

        // Nada que ver con la captura: sin red, sesión vencida o servidor
        // caído. Se queda pendiente y el vaciado se detiene aquí.
        await _db.captureQueueDao.markRetryable(
          row.captureId,
          code: failure.code,
          message: failure.operatorMessage,
          at: _now(),
        );
        stoppedBy = failure;
        break;
      }
    }

    final remaining = (await _db.captureQueueDao.pending(userId)).length;
    return QueueFlushReport(
      sent: sent,
      parked: parked,
      remaining: remaining,
      stoppedBy: stoppedBy,
    );
  }

  /// Si el rechazo habla de **esta** captura o del camino hasta el servidor.
  ///
  /// La distinción decide si se aparca o se reintenta, y por eso se escribe
  /// como una pregunta y no como una lista de códigos. Un 401 no dice nada
  /// malo de la captura: dice que la sesión venció, y aparcarla por eso
  /// perdería inventario por un problema de credenciales.
  static bool _belongsToTheCapture(ApiFailure failure) => switch (failure) {
    BusinessRuleFailure() => true,
    ForbiddenFailure() => true,
    NotFoundFailure() => true,
    _ => false,
  };
}
