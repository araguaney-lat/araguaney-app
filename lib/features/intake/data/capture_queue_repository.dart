import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables/queued_captures_table.dart';
import '../domain/intake_draft.dart';

/// La cola de capturas hechas sin señal.
///
/// Cuatro invariantes la sostienen, y todas viven en el esquema o aquí:
///
/// 1. La llave de idempotencia se genera antes del primer intento y no cambia.
/// 2. El catálogo local conserva la visibilidad por campaña del servidor, así
///    que lo que se puede elegir sin señal es lo que el servidor aceptará.
/// 3. La cola es por persona: cada fila lleva su `user_id` y ninguna consulta
///    de esta clase se hace sin él.
/// 4. Nada se descarta solo. Solo dos caminos borran una fila: el envío
///    aceptado y el descarte explícito de una persona.
class CaptureQueueRepository {
  CaptureQueueRepository({
    required AppDatabase database,
    DateTime Function()? now,
  }) : _db = database,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<QueuedCaptureRow>> watchAll(String userId) =>
      _db.captureQueueDao.watchAll(userId);

  Stream<int> watchPendingCount(String userId) =>
      _db.captureQueueDao.watchPendingCount(userId);

  /// Guarda la captura tal como se enviaría.
  ///
  /// El payload se serializa aquí y no se vuelve a construir al enviarlo: lo
  /// que sale del sótano es exactamente lo que se capturó, aunque el catálogo
  /// haya cambiado mientras tanto.
  Future<void> enqueue({required IntakeDraft draft, required String userId}) =>
      _db.captureQueueDao.enqueue(
        QueuedCaptureRow(
          captureId: draft.captureId,
          userId: userId,
          payload: jsonEncode(draft.toRequest().toJson()),
          summary: describeDraft(draft),
          boxCount: draft.boxes.length,
          status: QueuedCaptureStatus.pending,
          attempts: 0,
          createdAt: _now(),
        ),
      );

  /// La otra decisión que puede tomar una persona ante un rechazo: volver a
  /// intentarlo, normalmente porque el motivo se resolvió fuera de la
  /// aplicación. La invariante 4 pide una decisión explícita; no dice que la
  /// única disponible tenga que ser tirar la captura.
  Future<void> retry(String captureId) =>
      _db.captureQueueDao.requeue(captureId);

  /// Descarte explícito. Es el único borrado que no viene de un envío
  /// aceptado, y por eso lo pide una persona mirando el motivo del rechazo.
  Future<void> discard(String captureId) =>
      _db.captureQueueDao.remove(captureId);
}

/// Cómo se nombra una captura encolada en la pantalla de pendientes.
///
/// **It carries no count and no sentence.** A queued capture is read days
/// later, possibly with the application in another language, and a rendered
/// «3 cajas» written into the row would freeze today's language in there. The
/// number is already a column of its own; the screen puts the two together.
String describeDraft(IntakeDraft draft) => [
  if (draft.boxes.isNotEmpty) draft.boxes.first.productType.displayName,
  ?_donorLabel(draft),
].join(' · ');

String? _donorLabel(IntakeDraft draft) {
  if (draft.donor case final donor?) {
    return donor.legalName ?? '${donor.firstName} ${donor.lastName}';
  }
  return draft.donanteLibre;
}
