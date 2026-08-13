import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/shipments_api.dart';
import '../../../core/api/generated/models/incident_create.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/reception_out.dart';

/// Tipos de incidencia que reconoce el backend.
///
/// Se nombran aquí para poder ofrecerlos en un desplegable; el servidor sigue
/// siendo quien valida. Los tres primeros los abre él solo al reconciliar una
/// recepción, así que en el móvil se levantan sobre todo los dos últimos.
abstract final class IncidentType {
  static const weightDifference = 'WEIGHT_DIFF';
  static const missingBox = 'MISSING_BOX';
  static const damage = 'DAMAGE';
  static const customsRetention = 'CUSTOMS_RETENTION';
  static const other = 'OTHER';

  static const all = [
    damage,
    missingBox,
    customsRetention,
    weightDifference,
    other,
  ];
}

/// Nombre en español de un tipo. Traducción de interfaz, no interpretación.
String incidentTypeLabel(String type) => switch (type) {
  IncidentType.weightDifference => 'Diferencia de peso',
  IncidentType.missingBox => 'Caja faltante',
  IncidentType.damage => 'Daño',
  IncidentType.customsRetention => 'Retención en aduana',
  IncidentType.other => 'Otra',
  _ => type,
};

sealed class IncidentOutcome {
  const IncidentOutcome();
}

final class IncidentCreated extends IncidentOutcome {
  const IncidentCreated(this.incident);

  final IncidentOut incident;
}

final class IncidentRejected extends IncidentOutcome {
  const IncidentRejected(this.failure);

  final ApiFailure failure;
}

/// Incidencias de un envío, y lo que llegó de él.
///
/// Las dos cosas viven juntas porque cuentan la misma historia desde los dos
/// lados: la recepción dice qué llegó bien, y las incidencias qué no. El centro
/// que envió puede leer ambas —le importa qué pasó con lo suyo— y puede
/// levantar incidencias, que es lo que hace quien nota que falta algo.
class IncidentsRepository {
  IncidentsRepository(this._shipments);

  final ShipmentsApi _shipments;

  Future<List<IncidentOut>> forShipment(String shipmentId) =>
      _shipments.listShipmentIncidentsV1ShipmentsShipmentIdIncidentsGet(
        shipmentId: shipmentId,
      );

  /// La recepción registrada, o nulo si el envío todavía no se reconcilió.
  ///
  /// Un 404 aquí no es un fallo que mostrar: es la respuesta a «¿ya llegó?»,
  /// y la respuesta es que todavía no.
  Future<ReceptionOut?> reception(String shipmentId) async {
    try {
      return await _shipments.getReceptionV1ShipmentsShipmentIdReceptionGet(
        shipmentId: shipmentId,
      );
    } on Object catch (error) {
      if (ApiErrorMapper.fromAny(error) is NotFoundFailure) return null;
      rethrow;
    }
  }

  Future<IncidentOutcome> create({
    required String shipmentId,
    required String type,
    required String description,
    String? boxId,
    String? palletId,
  }) async {
    try {
      final incident = await _shipments
          .createIncidentV1ShipmentsShipmentIdIncidentsPost(
            shipmentId: shipmentId,
            body: IncidentCreate(
              type: type,
              description: description,
              boxId: boxId,
              palletId: palletId,
            ),
          );
      return IncidentCreated(incident);
    } on Object catch (error) {
      return IncidentRejected(ApiErrorMapper.fromAny(error));
    }
  }
}
