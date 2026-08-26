import '../../../core/i18n/generated/app_localizations.dart';

/// Which way a transfer goes with respect to the centre of whoever is looking.
enum TransferDirection {
  /// It leaves this centre.
  outgoing,

  /// Viene hacia este centro.
  incoming,

  /// It neither leaves nor arrives here. A national administration sees it.
  other,
}

/// What can be done with a transfer.
enum TransferAction { approve, reject, dispatch, receive }

/// The states the backend publishes.
abstract final class TransferStatus {
  static const requested = 'REQUESTED';
  static const approved = 'APPROVED';
  static const inTransit = 'IN_TRANSIT';
  static const received = 'RECEIVED';
  static const rejected = 'REJECTED';
}

TransferDirection transferDirection({
  required String fromCenterId,
  required String toCenterId,
  required String? myCenterId,
}) {
  if (myCenterId == null) return TransferDirection.other;
  if (myCenterId == fromCenterId) return TransferDirection.outgoing;
  if (myCenterId == toCenterId) return TransferDirection.incoming;
  return TransferDirection.other;
}

/// Which actions make sense right now.
///
/// **This is a mirror of the server's state machine**, and the server is still
/// the one that decides: if it refuses anyway, its reason is shown. It exists
/// so as not to offer three buttons of which two are certain to fail.
///
/// The rule it copies, checked in `transfer_service.py`:
///
/// - approve and reject: the origin centre only, and only if it is requested;
/// - dispatch: the origin only, and only if it is approved;
/// - receive: the destination centre only, and only if it is in transit.
///
/// A national administration can do the origin's from anywhere; receiving still
/// belongs to the destination.
Set<TransferAction> availableTransferActions({
  required String status,
  required TransferDirection direction,
  required bool isNationalAdmin,
}) {
  final asOrigin = direction == TransferDirection.outgoing || isNationalAdmin;
  final asDestination = direction == TransferDirection.incoming;

  return switch (status) {
    TransferStatus.requested when asOrigin => {
      TransferAction.approve,
      TransferAction.reject,
    },
    TransferStatus.approved when asOrigin => {TransferAction.dispatch},
    TransferStatus.inTransit when asDestination => {TransferAction.receive},
    _ => const {},
  };
}

String transferActionLabel(AppLocalizations l10n, TransferAction action) =>
    switch (action) {
      TransferAction.approve => l10n.transferActionApprove,
      TransferAction.reject => l10n.transferActionReject,
      TransferAction.dispatch => l10n.transferActionDispatch,
      TransferAction.receive => l10n.transferActionReceive,
    };
