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

/// Taking part in transfers between centres.
///
/// Every transition requires a connection and coordination, and none is queued:
/// a transfer is moved by two centres at once, and deciding without signal
/// would leave two versions of the same movement.
///
/// **Creating a transfer has been here since phase 27.** It was out while this
/// application could not read the list of centres, which was the only real
/// blocker: choosing sealed boxes by scanning them is not desk work, it is what
/// a phone does best.
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

  /// Proposes moving **these boxes** to another centre.
  ///
  /// `box_ids` and not quantities: a transfer moves specific loads, and the
  /// server checks one by one that they are sealed, off a pallet, at the origin
  /// centre and free of another transfer. None of that is repeated here; what
  /// the screen does do is not let a list be built that is already known to be
  /// refused wholesale.
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

  /// Asks for the transfer's manifest. Same road as the shipment's: the server
  /// assembles the document apart and here we wait for it to be ready.
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

  /// Runs whichever transition belongs.
  ///
  /// It is dispatched here and not in the screen so the map between action and
  /// endpoint lives in one place: they are four different routes for what from
  /// above is a single gesture.
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
