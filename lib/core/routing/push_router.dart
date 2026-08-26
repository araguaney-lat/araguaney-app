import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/risk_reviews/ui/risk_reviews_view.dart';
import '../../features/shipments/ui/shipment_record_view.dart';
import '../push/push_destination.dart';
import '../push/push_providers.dart';

/// Takes whoever tapped a notice to what the notice was about.
///
/// It wraps the authenticated part of the tree and not anything above it, and
/// that is deliberate: navigating requires a session, and a notice tapped while
/// the application sits on the sign-in screen or the forced password change
/// cannot skip either of them. When the session opens, the initial message is
/// still there and the destination opens then.
class PushRouter extends ConsumerStatefulWidget {
  const PushRouter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushRouter> createState() => _PushRouterState();
}

class _PushRouterState extends ConsumerState<PushRouter> {
  StreamSubscription<PushDestination>? _opened;

  @override
  void initState() {
    super.initState();
    _opened = ref.read(pushServiceProvider).onOpened.listen(_go);
  }

  @override
  void dispose() {
    _opened?.cancel();
    super.dispose();
  }

  void _go(PushDestination destination) {
    if (!mounted) return;

    // A notice of a kind this version does not know goes nowhere. The server
    // composed the text and it has already been shown; opening some arbitrary
    // screen would be worse than opening none.
    final route = switch (destination) {
      RiskReviewDestination(:final intakeId) => RiskReviewsView.route(
        highlightIntakeId: intakeId,
      ),
      ShipmentDeliveredDestination(:final shipmentId) =>
        ShipmentRecordView.route(shipmentId),
      UnknownDestination() => null,
    };

    if (route != null) Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
