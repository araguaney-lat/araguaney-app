/// Where tapping a notice leads.
///
/// The server composes the title and body; the application only shows them.
/// What is there to navigate with travels separately, in the message's `data`,
/// and this interprets it.
///
/// A design note that comes from the backend and is worth not undoing here:
/// **a risk-review notice does not say why the review was raised**. It is read
/// on a lock screen, sometimes with somebody standing next to you; the reason
/// lives inside the review.
sealed class PushDestination {
  const PushDestination();
}

/// A risk review was opened on one of the centre's captures.
final class RiskReviewDestination extends PushDestination {
  const RiskReviewDestination(this.intakeId);

  final String intakeId;
}

/// A shipment from the sending centre reached its destination.
final class ShipmentDeliveredDestination extends PushDestination {
  const ShipmentDeliveredDestination(this.shipmentId);

  final String shipmentId;
}

/// A notice this build does not know how to route.
///
/// It exists because the contract is additive and a months-old binary has to
/// survive a kind of notice it never knew about: it is shown anyway — the
/// server composed the text — and tapping it simply navigates nowhere instead
/// of breaking.
final class UnknownDestination extends PushDestination {
  const UnknownDestination(this.kind);

  final String? kind;
}

/// The names the server uses in `data.kind`.
abstract final class PushKind {
  static const riskReview = 'risk_review';
  static const shipmentDelivered = 'shipment_delivered';
}

/// Interprets a notice's `data`.
///
/// A missing field is not a notice of some other kind: it is this notice
/// arriving incomplete, and routing it halfway would be worse than not routing
/// it at all.
PushDestination parsePushDestination(Map<String, String> data) {
  final kind = data['kind'];

  return switch (kind) {
    PushKind.riskReview => switch (data['intake_id']) {
      final String id when id.isNotEmpty => RiskReviewDestination(id),
      _ => UnknownDestination(kind),
    },
    PushKind.shipmentDelivered => switch (data['shipment_id']) {
      final String id when id.isNotEmpty => ShipmentDeliveredDestination(id),
      _ => UnknownDestination(kind),
    },
    _ => UnknownDestination(kind),
  };
}
