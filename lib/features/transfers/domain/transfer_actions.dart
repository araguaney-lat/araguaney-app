import '../../../core/i18n/generated/app_localizations.dart';

/// Hacia dónde va una transferencia respecto del centro de quien mira.
enum TransferDirection {
  /// Sale de este centro.
  outgoing,

  /// Viene hacia este centro.
  incoming,

  /// Ni sale ni llega aquí. Lo ve una administración nacional.
  other,
}

/// Lo que se puede hacer con una transferencia.
enum TransferAction { approve, reject, dispatch, receive }

/// Estados que publica el backend.
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

/// Qué acciones tienen sentido ahora mismo.
///
/// **Esto es un espejo de la máquina de estados del servidor**, y el servidor
/// sigue siendo quien decide: si rechaza igual, su motivo se muestra. Existe
/// para no ofrecer tres botones de los cuales dos van a fallar seguro.
///
/// La regla que copia, verificada en `transfer_service.py`:
///
/// - aprobar y rechazar: solo el centro de origen, y solo si está solicitada;
/// - despachar: solo el origen, y solo si está aprobada;
/// - recibir: solo el centro de destino, y solo si está en tránsito.
///
/// Una administración nacional puede hacer las de origen desde cualquier lado;
/// recibir sigue siendo del destino.
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
