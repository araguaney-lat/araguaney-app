/// A dónde lleva tocar un aviso.
///
/// El servidor compone el título y el cuerpo en español; la aplicación solo los
/// muestra. Lo que sirve para navegar viaja aparte, en el `data` del mensaje, y
/// esto lo interpreta.
///
/// Una nota de diseño que viene del backend y conviene no deshacer aquí: **el
/// aviso de revisión de riesgo no dice por qué se levantó**. Se lee en una
/// pantalla de bloqueo, a veces con alguien al lado; el motivo vive dentro de la
/// revisión.
sealed class PushDestination {
  const PushDestination();
}

/// Se abrió una revisión de riesgo sobre una captura del centro.
final class RiskReviewDestination extends PushDestination {
  const RiskReviewDestination(this.intakeId);

  final String intakeId;
}

/// Un envío del centro de origen llegó a su destino.
final class ShipmentDeliveredDestination extends PushDestination {
  const ShipmentDeliveredDestination(this.shipmentId);

  final String shipmentId;
}

/// Un aviso que esta versión no sabe enrutar.
///
/// Existe porque el contrato es solo-aditivo y un binario de hace meses tiene
/// que sobrevivir a una clase de aviso que no conocía: se muestra igual —el
/// texto lo compuso el servidor— y tocarlo simplemente no navega a ningún
/// sitio, en vez de romperse.
final class UnknownDestination extends PushDestination {
  const UnknownDestination(this.kind);

  final String? kind;
}

/// Nombres que el servidor usa en `data.kind`.
abstract final class PushKind {
  static const riskReview = 'risk_review';
  static const shipmentDelivered = 'shipment_delivered';
}

/// Interpreta el `data` de un aviso.
///
/// Un campo que falta no es un aviso de otra clase: es este aviso llegando
/// incompleto, y enrutarlo a medias sería peor que no enrutarlo.
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
