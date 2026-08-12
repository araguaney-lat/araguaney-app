import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'box_code_repository.dart';
import 'capture_queue_repository.dart';
import 'capture_queue_sync.dart';
import 'intake_repository.dart';

/// De dónde sale la llave de idempotencia. Es un provider para que una prueba
/// pueda fijarla y comprobar que no cambia entre reintentos.
final captureIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

final intakeRepositoryProvider = Provider<IntakeRepository>(
  (ref) => IntakeRepository(ref.watch(restClientProvider).intakes),
);

/// Quién tiene la sesión abierta. La cola y los códigos reservados son suyos y
/// de nadie más, así que todo lo que los toca pasa por aquí.
final currentUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive ? state.session.userId : null;
});

final captureQueueRepositoryProvider = Provider<CaptureQueueRepository>(
  (ref) => CaptureQueueRepository(database: ref.watch(appDatabaseProvider)),
);

final captureQueueSyncProvider = Provider<CaptureQueueSync>(
  (ref) => CaptureQueueSync(
    api: ref.watch(restClientProvider).intakes,
    database: ref.watch(appDatabaseProvider),
  ),
);

final boxCodeRepositoryProvider = Provider<BoxCodeRepository>(
  (ref) => BoxCodeRepository(
    api: ref.watch(restClientProvider).boxes,
    database: ref.watch(appDatabaseProvider),
  ),
);

/// Cuántas capturas de esta persona esperan señal. Cero cuando no hay sesión:
/// sin saber de quién es la cola, no hay cola que mostrar.
final pendingCaptureCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref.watch(captureQueueRepositoryProvider).watchPendingCount(userId);
});

final queuedCapturesProvider = StreamProvider<List<QueuedCaptureRow>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(captureQueueRepositoryProvider).watchAll(userId);
});

/// Códigos de caja sin gastar que le quedan a esta persona en el dispositivo.
final availableBoxCodesProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref.watch(boxCodeRepositoryProvider).watchAvailable(userId);
});

/// Campañas en las que participa quien capturó la sesión. Se consultan en
/// línea: elegir campaña es parte del camino de escritura, que en esta fase
/// exige señal de todos modos.
final myCampaignsProvider = FutureProvider<List<CampaignOut>>(
  (ref) => ref
      .watch(restClientProvider)
      .campaigns
      .listMyCampaignsV1CampaignsMineGet(),
);

/// Las capturas registradas del centro. Se consultan en línea: la lectura sin
/// conexión que la operación necesita es la del inventario, no la del historial.
final intakesProvider = FutureProvider<List<IntakeOut>>(
  (ref) => ref.watch(intakeRepositoryProvider).list(),
);

/// Dueño del formulario de captura.
///
/// Se descarta al cerrar la pantalla, y con él la llave de idempotencia: la
/// captura siguiente es otra captura. Mientras la pantalla vive, esa llave no
/// cambia por nada —ni al editar, ni al fallar, ni al reintentar—, que es la
/// primera invariante de la cola sin conexión.
class IntakeDraftController extends AutoDisposeNotifier<IntakeDraft> {
  @override
  IntakeDraft build() =>
      IntakeDraft(captureId: ref.read(captureIdGeneratorProvider)());

  void setCampaign(String? campaignId) =>
      state = state.copyWith(campaignId: campaignId);

  void setDonor(DonorInput donor, {required bool termsAccepted}) =>
      state = state.copyWith(donor: donor, donorTermsAccepted: termsAccepted);

  void clearDonor() => state = state.withoutDonor();

  void setDonanteLibre(String? value) =>
      state = state.copyWith(donanteLibre: value);

  void setNotes(String? value) => state = state.copyWith(notes: value);

  void setExceptionReason(String? reason) =>
      state = state.copyWith(anonymousExceptionReason: reason);

  void addBox(BoxDraftInput box) => state = state.addBox(box);

  void replaceBox(int index, BoxDraftInput box) =>
      state = state.replaceBox(index, box);

  void removeBox(int index) => state = state.removeBox(index);

  /// Rellena desde una donación pre-registrada.
  ///
  /// Solo ata la captura a la donación. Los artículos que declaró quien donó no
  /// se convierten en cajas automáticamente: son lo que dijo que traía, y lo
  /// que se registra es lo que llegó. Confundir las dos cosas sería inventar
  /// inventario.
  void prefillFromDonation(String donationId) =>
      state = state.copyWith(donationId: donationId);

  /// Asigna códigos reservados a las cajas que todavía no tienen uno.
  ///
  /// Se llama justo antes de encolar: una caja capturada sin señal necesita su
  /// código en ese momento, porque nadie va a volver a abrir una caja cerrada
  /// para etiquetarla después. Si el bloque no alcanza, las cajas sobrantes
  /// quedan sin código y lo asignará el servidor cuando la captura llegue.
  void assignCodes(List<String> codes) {
    var next = 0;
    state = state.copyWith(
      boxes: [
        for (final box in state.boxes)
          if (box.code == null && next < codes.length)
            box.copyWith(code: codes[next++])
          else
            box,
      ],
    );
  }

  Future<IntakeSubmission> submit() =>
      ref.read(intakeRepositoryProvider).submit(state);

  /// Guarda la captura para enviarla cuando haya señal.
  Future<void> enqueue(String userId) => ref
      .read(captureQueueRepositoryProvider)
      .enqueue(draft: state, userId: userId);
}

final intakeDraftControllerProvider =
    AutoDisposeNotifierProvider<IntakeDraftController, IntakeDraft>(
      IntakeDraftController.new,
    );
