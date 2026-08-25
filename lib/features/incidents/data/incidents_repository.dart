import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/incidents_api.dart';
import '../../../core/api/generated/clients/shipments_api.dart';
import '../../../core/api/generated/models/incident_create.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/incident_resolve.dart';
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

/// Las incidencias del centro, y cerrarlas.
///
/// Va aparte del repositorio de envíos porque responde otra pregunta. Aquel
/// contesta «qué pasó con este envío»; este contesta «qué hay abierto», que es
/// lo que nadie podía preguntar: la aplicación sabía **levantar** una
/// incidencia y no sabía enseñarla, así que quien reportaba un problema no
/// tenía forma de saber si alguien lo miró.
///
/// El servidor acota por centro solo: una administración nacional las ve todas.
class CenterIncidentsRepository {
  CenterIncidentsRepository(this._incidents);

  final IncidentsApi _incidents;

  Future<IncidentsOutcome<List<IncidentOut>>> list({String? status}) async {
    try {
      return IncidentsRead(
        await _incidents.listIncidentsV1IncidentsGet(status: status),
      );
    } on Object catch (error) {
      return IncidentsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Cerrar una incidencia. La nota es obligatoria en el contrato, y con razón:
  /// es lo único que le queda a quien la reportó para saber en qué terminó.
  Future<IncidentsOutcome<IncidentOut>> resolve(String id, String note) async {
    try {
      return IncidentsRead(
        await _incidents.resolveIncidentV1IncidentsIncidentIdResolvePost(
          incidentId: id,
          body: IncidentResolve(note: note),
        ),
      );
    } on Object catch (error) {
      return IncidentsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}

sealed class IncidentsOutcome<T> {
  const IncidentsOutcome();
}

final class IncidentsRead<T> extends IncidentsOutcome<T> {
  const IncidentsRead(this.value);

  final T value;
}

final class IncidentsRefused<T> extends IncidentsOutcome<T> {
  const IncidentsRefused(this.failure);

  final ApiFailure failure;

  bool get isForbidden => failure is ForbiddenFailure;
}
