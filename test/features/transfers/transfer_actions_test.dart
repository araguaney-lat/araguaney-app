import 'package:araguaney_app/core/ui/status_labels.dart';
import 'package:araguaney_app/features/transfers/domain/transfer_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/l10n.dart';

void main() {
  Set<TransferAction> actionsFor({
    required String status,
    required TransferDirection direction,
    bool isNationalAdmin = false,
  }) => availableTransferActions(
    status: status,
    direction: direction,
    isNationalAdmin: isNationalAdmin,
  );

  group('which way a transfer goes', () {
    test('it is outgoing when this center is the origin', () {
      expect(
        transferDirection(
          fromCenterId: 'mine',
          toCenterId: 'theirs',
          myCenterId: 'mine',
        ),
        TransferDirection.outgoing,
      );
    });

    test('it is incoming when this center is the destination', () {
      expect(
        transferDirection(
          fromCenterId: 'theirs',
          toCenterId: 'mine',
          myCenterId: 'mine',
        ),
        TransferDirection.incoming,
      );
    });

    test('someone without a center sees it as neither', () {
      // Una administración nacional no tiene centro propio.
      expect(
        transferDirection(fromCenterId: 'a', toCenterId: 'b', myCenterId: null),
        TransferDirection.other,
      );
    });
  });

  group('what the origin can do', () {
    test('a requested transfer can be approved or rejected', () {
      expect(
        actionsFor(
          status: TransferStatus.requested,
          direction: TransferDirection.outgoing,
        ),
        {TransferAction.approve, TransferAction.reject},
      );
    });

    test('an approved transfer can be dispatched', () {
      expect(
        actionsFor(
          status: TransferStatus.approved,
          direction: TransferDirection.outgoing,
        ),
        {TransferAction.dispatch},
      );
    });

    test('the origin cannot receive what it sent', () {
      // Recibir es del destino. Ofrecerlo aquí sería un botón que responde 403.
      expect(
        actionsFor(
          status: TransferStatus.inTransit,
          direction: TransferDirection.outgoing,
        ),
        isEmpty,
      );
    });
  });

  group('what the destination can do', () {
    test('a transfer in transit can be received', () {
      expect(
        actionsFor(
          status: TransferStatus.inTransit,
          direction: TransferDirection.incoming,
        ),
        {TransferAction.receive},
      );
    });

    test('the destination cannot approve its own request', () {
      expect(
        actionsFor(
          status: TransferStatus.requested,
          direction: TransferDirection.incoming,
        ),
        isEmpty,
      );
    });
  });

  group('national administration', () {
    test('can act as the origin from anywhere', () {
      expect(
        actionsFor(
          status: TransferStatus.approved,
          direction: TransferDirection.other,
          isNationalAdmin: true,
        ),
        {TransferAction.dispatch},
      );
    });

    test('still cannot receive on behalf of the destination', () {
      // El servidor exige que reciba la coordinación del destino.
      expect(
        actionsFor(
          status: TransferStatus.inTransit,
          direction: TransferDirection.other,
          isNationalAdmin: true,
        ),
        isEmpty,
      );
    });
  });

  group('closed transfers', () {
    test('nothing is offered once received or rejected', () {
      for (final status in [TransferStatus.received, TransferStatus.rejected]) {
        for (final direction in TransferDirection.values) {
          expect(
            actionsFor(status: status, direction: direction),
            isEmpty,
            reason: '$status desde $direction',
          );
        }
      }
    });

    test('a status this version does not know offers nothing', () {
      expect(
        actionsFor(
          status: 'SOMETHING_NEW',
          direction: TransferDirection.outgoing,
        ),
        isEmpty,
      );
    });
  });

  test('every status has a name, and unknown ones survive', () async {
    // Un estado que esta version no conoce se enseña crudo a proposito: el
    // contrato es aditivo y un binario viejo puede recibir uno nuevo. Verlo
    // dice «esto es nuevo» en vez de inventar una traduccion.
    final l10n = await spanish();

    expect(transferStatusLabel(l10n, TransferStatus.inTransit), 'En tránsito');
    expect(transferStatusLabel(l10n, 'SOMETHING_NEW'), 'SOMETHING_NEW');
  });
}
