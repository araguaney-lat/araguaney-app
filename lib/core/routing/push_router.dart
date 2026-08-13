import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/risk_reviews/ui/risk_reviews_view.dart';
import '../../features/shipments/ui/shipment_record_view.dart';
import '../push/push_destination.dart';
import '../push/push_providers.dart';

/// Lleva a quien tocó un aviso a donde el aviso hablaba.
///
/// Vive envolviendo la parte autenticada del árbol y no más arriba, y eso es
/// deliberado: navegar exige sesión, y un aviso tocado mientras la aplicación
/// está en la pantalla de inicio de sesión o en el cambio de contraseña
/// obligatorio no puede saltarse ninguna de las dos. Cuando la sesión se abra,
/// el mensaje inicial sigue ahí y el destino se abre entonces.
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

    // Un aviso de una clase que esta versión no conoce se queda sin navegar.
    // El texto lo compuso el servidor y ya se mostró; abrir una pantalla
    // cualquiera sería peor que no abrir ninguna.
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
