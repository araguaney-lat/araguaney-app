import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'intake_repository.dart';

/// De dónde sale la llave de idempotencia. Es un provider para que una prueba
/// pueda fijarla y comprobar que no cambia entre reintentos.
final captureIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

final intakeRepositoryProvider = Provider<IntakeRepository>(
  (ref) => IntakeRepository(ref.watch(restClientProvider).intakes),
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

  Future<IntakeSubmission> submit() =>
      ref.read(intakeRepositoryProvider).submit(state);
}

final intakeDraftControllerProvider =
    AutoDisposeNotifierProvider<IntakeDraftController, IntakeDraft>(
      IntakeDraftController.new,
    );
