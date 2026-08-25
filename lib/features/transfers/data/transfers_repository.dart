import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/export_job.dart';
import '../../../core/api/generated/clients/exports_api.dart';
import '../../../core/api/generated/clients/transfers_api.dart';
import '../../../core/api/generated/models/transfer_create.dart';
import '../../../core/api/generated/models/transfer_detail_out.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import '../../../core/api/generated/models/transfer_reject.dart';
import '../domain/transfer_actions.dart';

sealed class TransferOutcome {
  const TransferOutcome();
}

final class TransferAdvanced extends TransferOutcome {
  const TransferAdvanced(this.transfer);

  final TransferOut transfer;
}

final class TransferRefused extends TransferOutcome {
  const TransferRefused(this.failure);

  final ApiFailure failure;
}

/// Participación en transferencias entre centros.
///
/// Todas las transiciones exigen conexión y coordinación, y ninguna se encola:
/// una transferencia la mueven dos centros a la vez, y decidir sin señal
/// dejaría dos versiones del mismo movimiento.
///
/// **Crear una transferencia sí está aquí desde la fase 27.** Estuvo fuera
/// mientras esta aplicación no podía leer la lista de centros, que era el único
/// bloqueo real: elegir cajas selladas escaneándolas no es trabajo de
/// escritorio, es lo que mejor hace un teléfono.
class TransfersRepository {
  TransfersRepository({
    required TransfersApi transfers,
    required ExportsApi exports,
  }) : _transfersApi = transfers,
       _exportsApi = exports;

  final TransfersApi _transfersApi;
  final ExportsApi _exportsApi;

  Future<List<TransferOut>> list() =>
      _transfersApi.listTransfersV1TransfersGet();

  /// Propone mover **estas cajas** a otro centro.
  ///
  /// `box_ids` y no cantidades: una transferencia mueve bultos concretos, y el
  /// servidor comprueba uno por uno que estén sellados, sin tarima, en el
  /// centro de origen y libres de otra transferencia. Nada de eso se repite
  /// aquí; lo que sí hace la pantalla es no dejar armar una lista que ya se
  /// sabe que va a ser rechazada entera.
  Future<TransferOutcome> create({
    required String fromCenterId,
    required String toCenterId,
    required List<String> boxIds,
    String? notes,
  }) async {
    try {
      return TransferAdvanced(
        await _transfersApi.createTransferV1TransfersPost(
          body: TransferCreate(
            fromCenterId: fromCenterId,
            toCenterId: toCenterId,
            boxIds: boxIds,
            notes: notes,
          ),
        ),
      );
    } on Object catch (error) {
      return TransferRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Pide el manifiesto de la transferencia. Mismo camino que el del envío: el
  /// servidor arma el documento aparte y aquí se espera a que esté.
  Future<DocumentOutcome> manifest(
    String transferId, {
    Future<void> Function(Duration) wait = Future.delayed,
  }) => awaitDocument(
    start: () => _transfersApi
        .downloadTransferManifestV1TransfersTransferIdManifestPdfPost(
          transferId: transferId,
        ),
    exports: _exportsApi,
    wait: wait,
  );

  Future<TransferDetailOut> detail(String transferId) =>
      _transfersApi.getTransferV1TransfersTransferIdGet(transferId: transferId);

  /// Ejecuta la transición que corresponda.
  ///
  /// Se despacha aquí y no en la pantalla para que el mapa entre acción y
  /// endpoint viva en un solo sitio: son cuatro rutas distintas para lo que
  /// desde arriba es un solo gesto.
  Future<TransferOutcome> perform({
    required TransferAction action,
    required String transferId,
    String? reason,
  }) async {
    try {
      final transfer = switch (action) {
        TransferAction.approve =>
          await _transfersApi.approveTransferV1TransfersTransferIdApprovePost(
            transferId: transferId,
          ),
        TransferAction.reject =>
          await _transfersApi.rejectTransferV1TransfersTransferIdRejectPost(
            transferId: transferId,
            body: TransferReject(reason: reason),
          ),
        TransferAction.dispatch =>
          await _transfersApi.dispatchTransferV1TransfersTransferIdDispatchPost(
            transferId: transferId,
          ),
        TransferAction.receive =>
          await _transfersApi.receiveTransferV1TransfersTransferIdReceivePost(
            transferId: transferId,
          ),
      };
      return TransferAdvanced(transfer);
    } on Object catch (error) {
      return TransferRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
