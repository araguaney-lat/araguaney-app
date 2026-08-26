import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/incidents_api.dart';
import '../../../core/api/generated/clients/shipments_api.dart';
import '../../../core/api/generated/models/incident_create.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/incident_resolve.dart';
import '../../../core/api/generated/models/reception_out.dart';
import '../../../core/i18n/generated/app_localizations.dart';

/// The incident types the backend recognises.
///
/// They are named here so they can be offered in a dropdown; the server is
/// still the one that validates. It opens the first three by itself when
/// reconciling a reception, so on mobile it is mostly the last two that get
/// raised.
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

/// A type's name in Spanish. Interface translation, not interpretation.
String incidentTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  IncidentType.weightDifference => l10n.incidentTypeWeightDiff,
  IncidentType.missingBox => l10n.incidentTypeMissingBox,
  IncidentType.damage => l10n.incidentTypeDamage,
  IncidentType.customsRetention => l10n.incidentTypeCustoms,
  IncidentType.other => l10n.incidentTypeOther,
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

/// A shipment's incidents, and what arrived from it.
///
/// The two live together because they tell the same story from both sides: the
/// reception says what arrived well, and the incidents what did not. The centre
/// that sent it can read both — what happened to its own matters to it — and
/// can raise incidents, which is what somebody who notices something missing
/// does.
class IncidentsRepository {
  IncidentsRepository(this._shipments);

  final ShipmentsApi _shipments;

  Future<List<IncidentOut>> forShipment(String shipmentId) =>
      _shipments.listShipmentIncidentsV1ShipmentsShipmentIdIncidentsGet(
        shipmentId: shipmentId,
      );

  /// The recorded reception, or null if the shipment has not been reconciled
  /// yet.
  ///
  /// A 404 here is not a failure to show: it is the answer to «has it arrived
  /// yet?», and the answer is not yet.
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

/// The centre's incidents, and closing them.
///
/// It goes apart from the shipments repository because it answers a different
/// question. That one answers «what happened to this shipment»; this one
/// answers «what is open», which is what nobody could ask: the application knew
/// how to **raise** an incident and did not know how to show it, so whoever
/// reported a problem had no way of knowing whether anybody had looked.
///
/// The server narrows by centre only: a national administration sees them all.
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

  /// Closing an incident. The note is required by the contract, and rightly so:
  /// it is all that is left to whoever reported it to know how it ended.
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
