import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/transfers_api.dart';
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
/// Crear una transferencia no está aquí. Elegir centro de destino y marcar
/// cajas selladas es trabajo de escritorio, y además nombrar centros exige un
/// permiso que esta aplicación no tiene — ver el hueco anotado en la fase 10.
class TransfersRepository {
  TransfersRepository(this._transfers);

  final TransfersApi _transfers;

  Future<List<TransferOut>> list() => _transfers.listTransfersV1TransfersGet();

  Future<TransferDetailOut> detail(String transferId) =>
      _transfers.getTransferV1TransfersTransferIdGet(transferId: transferId);

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
          await _transfers.approveTransferV1TransfersTransferIdApprovePost(
            transferId: transferId,
          ),
        TransferAction.reject =>
          await _transfers.rejectTransferV1TransfersTransferIdRejectPost(
            transferId: transferId,
            body: TransferReject(reason: reason),
          ),
        TransferAction.dispatch =>
          await _transfers.dispatchTransferV1TransfersTransferIdDispatchPost(
            transferId: transferId,
          ),
        TransferAction.receive =>
          await _transfers.receiveTransferV1TransfersTransferIdReceivePost(
            transferId: transferId,
          ),
      };
      return TransferAdvanced(transfer);
    } on Object catch (error) {
      return TransferRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
