import 'package:araguaney_app/core/push/push_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a risk review notice routes with the intake it is about', () {
    final destination = parsePushDestination({
      'kind': 'risk_review',
      'intake_id': 'intake-9',
    });

    expect((destination as RiskReviewDestination).intakeId, 'intake-9');
  });

  test('a delivered shipment routes with its shipment', () {
    final destination = parsePushDestination({
      'kind': 'shipment_delivered',
      'shipment_id': 'shipment-4',
    });

    expect(
      (destination as ShipmentDeliveredDestination).shipmentId,
      'shipment-4',
    );
  });

  test('a private message routes with the thread it came from', () {
    // Only private threads notify: a campaign thread is a broadcast, and
    // buzzing every member on each reply teaches people to silence the ones
    // that do ask something of them.
    final destination = parsePushDestination({
      'kind': 'private_message',
      'thread_id': 'thread-7',
    });

    expect((destination as PrivateMessageDestination).threadId, 'thread-7');
  });

  test('a kind this version does not know is shown but goes nowhere', () {
    // The contract is additive only: a months-old binary has to survive a kind
    // of notice it did not know about.
    final destination = parsePushDestination({'kind': 'message_received'});

    expect((destination as UnknownDestination).kind, 'message_received');
  });

  test('a known kind missing its identifier does not route half way', () {
    // It is not a notice of another kind: it is this one arriving incomplete,
    // and routing it halfway would be worse than not routing it.
    expect(
      parsePushDestination({'kind': 'risk_review'}),
      isA<UnknownDestination>(),
    );
    expect(
      parsePushDestination({'kind': 'risk_review', 'intake_id': ''}),
      isA<UnknownDestination>(),
    );
    expect(
      parsePushDestination({'kind': 'shipment_delivered'}),
      isA<UnknownDestination>(),
    );
    expect(
      parsePushDestination({'kind': 'private_message'}),
      isA<UnknownDestination>(),
    );
  });

  test('an empty payload is unknown rather than a crash', () {
    expect(parsePushDestination(const {}), isA<UnknownDestination>());
  });
}
