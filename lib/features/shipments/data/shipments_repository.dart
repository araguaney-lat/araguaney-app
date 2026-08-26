import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/export_job.dart';
import '../../../core/api/generated/clients/exports_api.dart';
import '../../../core/api/generated/clients/shipments_api.dart';
import '../../../core/api/generated/models/delivered_in.dart';
import '../../../core/api/generated/models/milestone_in.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/api/generated/models/reception_create.dart';
import '../../../core/api/generated/models/reception_exception_in.dart';
import '../../../core/api/generated/models/reception_out.dart';
import '../../../core/api/generated/models/reception_pallet_weight_in.dart';
import '../../../core/api/generated/models/shipment_create.dart';
import '../../../core/api/generated/models/shipment_detail_out.dart';
import '../../../core/api/generated/models/shipment_out.dart';
import '../../../core/i18n/generated/app_localizations.dart';

/// The documents the server produces for a shipment.
///
/// They are named here and not in the screen because they are four different
/// routes for what from above is a single gesture: asking for a piece of paper.
enum ShipmentDocument {
  manifestPdf,
  manifestXlsx,
  declarationJson,
  declarationXlsx,
}

/// The seven milestones of `SHIPMENT_MILESTONES`, in the order of the journey.
///
/// The list lives here because it is the server's vocabulary: writing one that
/// is not on it produces `INVALID_MILESTONE`, so they are chosen and not typed.
const shipmentMilestones = [
  'DEPARTED_WAREHOUSE',
  'ARRIVED_AIRPORT',
  'LOADED_AIRCRAFT',
  'DEPARTED_FLIGHT',
  'ARRIVED_DESTINATION',
  'CUSTOMS_CLEARED',
  'DELIVERED_CONSIGNEE',
];

/// How a box can end up when it is received.
///
/// Four states from `RECEPTION_OUTCOMES`, and **only three travel**: what is
/// not marked, the server takes as received. Three of the four open an incident
/// on the server's side, which is where that decision lives.
abstract final class ReceptionOutcome {
  static const received = 'RECEIVED';
  static const missing = 'MISSING';
  static const damaged = 'DAMAGED';
  static const retainedCustoms = 'RETAINED_CUSTOMS';

  /// What can be marked: received is the absence of a mark.
  static const exceptions = [missing, damaged, retainedCustoms];
}

/// Logistical milestones the backend recognises.
///
/// A milestone is an event with the same state on both sides: it records that
/// something happened without inventing intermediate states, so the machine
/// does not grow with every airport. **Recording them requires national
/// administration**, so from here they are only read.
String milestoneLabel(AppLocalizations l10n, String milestone) =>
    switch (milestone) {
      'DEPARTED_WAREHOUSE' => l10n.milestoneLeftWarehouse,
      'ARRIVED_AIRPORT' => l10n.milestoneReachedAirport,
      'LOADED_AIRCRAFT' => l10n.milestoneLoadedOnPlane,
      'DEPARTED_FLIGHT' => l10n.milestoneDeparted,
      'ARRIVED_DESTINATION' => l10n.milestoneArrived,
      'CUSTOMS_CLEARED' => l10n.milestoneCustomsCleared,
      'DELIVERED_CONSIGNEE' => l10n.milestoneDeliveredToConsignee,
      _ => milestone,
    };

/// How an operation on a shipment ended.
sealed class ShipmentOutcome<T> {
  const ShipmentOutcome();
}

final class ShipmentDone<T> extends ShipmentOutcome<T> {
  const ShipmentDone(this.value);

  final T value;
}

final class ShipmentRefused<T> extends ShipmentOutcome<T> {
  const ShipmentRefused(this.failure);

  final ApiFailure failure;
}

class ShipmentsRepository {
  ShipmentsRepository({
    required ShipmentsApi shipments,
    required ExportsApi exports,
  }) : _shipmentsApi = shipments,
       _exportsApi = exports;

  /// How many times the job is asked about before giving up.
  ///
  /// Polling has to end: leaving somebody watching a spinner forever is worse
  /// than telling them to try again. If the allowance runs out, the job is
  /// still alive on the server and asking for it again picks it up.

  final ShipmentsApi _shipmentsApi;
  final ExportsApi _exportsApi;

  /// The centre's shipments. The server narrows them to the asker's own.
  Future<List<ShipmentOut>> list({String? status}) =>
      _shipmentsApi.listShipmentsV1ShipmentsGet(status: status);

  Future<ShipmentDetailOut> detail(String shipmentId) =>
      _shipmentsApi.getShipmentV1ShipmentsShipmentIdGet(shipmentId: shipmentId);

  /// [centerId] names the centre the shipment leaves from, and only a session
  /// without one of its own sets it. It is stamped here rather than in the
  /// sheet that collects the fields, so no screen can forget it.
  Future<ShipmentOutcome<ShipmentOut>> create(
    ShipmentCreate data, {
    String? centerId,
  }) => _guard(
    () => _shipmentsApi.createShipmentV1ShipmentsPost(
      body: centerId == null ? data : _withCenter(data, centerId),
    ),
  );

  static ShipmentCreate _withCenter(ShipmentCreate data, String centerId) =>
      ShipmentCreate(
        destination: data.destination,
        campaignId: data.campaignId,
        carrier: data.carrier,
        centerId: centerId,
        heightProfile: data.heightProfile,
        notes: data.notes,
        reference: data.reference,
      );

  /// The contract declares this body untyped, so the map is written here and in
  /// one place only. It is request 4 of `backend-requests.md`.
  Future<ShipmentOutcome<ShipmentDetailOut>> addPallet({
    required String shipmentId,
    required String palletId,
  }) => _guard(
    () => _shipmentsApi.addPalletToShipmentV1ShipmentsShipmentIdAddPalletPost(
      shipmentId: shipmentId,
      body: {'pallet_id': palletId},
    ),
  );

  Future<ShipmentOutcome<ShipmentDetailOut>> removePallet({
    required String shipmentId,
    required String palletId,
  }) => _guard(
    () => _shipmentsApi
        .removePalletFromShipmentV1ShipmentsShipmentIdPalletsPalletIdDelete(
          shipmentId: shipmentId,
          palletId: palletId,
        ),
  );

  /// Closing stops accepting pallets; dispatching says it left. Both go one
  /// way only and the server does not undo them, so the interface asks first.
  Future<ShipmentOutcome<ShipmentOut>> close(String shipmentId) => _guard(
    () => _shipmentsApi.closeShipmentV1ShipmentsShipmentIdClosePost(
      shipmentId: shipmentId,
    ),
  );

  Future<ShipmentOutcome<ShipmentOut>> ship(String shipmentId) => _guard(
    () => _shipmentsApi.shipShipmentV1ShipmentsShipmentIdShipPost(
      shipmentId: shipmentId,
    ),
  );

  /// Records a logistical milestone without moving the state.
  ///
  /// It is the one that makes most sense on a phone and it is not close:
  /// somebody is next to a lorry, at a checkpoint, with no desk. [occurredAt]
  /// is optional because the consignee's report usually arrives late and
  /// describes something from yesterday.
  Future<ShipmentOutcome<ShipmentOut>> addMilestone({
    required String shipmentId,
    required String milestone,
    String? note,
    DateTime? occurredAt,
  }) => _guard(
    () => _shipmentsApi.addMilestoneV1ShipmentsShipmentIdMilestonesPost(
      shipmentId: shipmentId,
      body: MilestoneIn(
        milestone: milestone,
        note: note,
        occurredAt: occurredAt,
      ),
    ),
  );

  /// `SHIPPED` → `DELIVERED`. It arrived; **what** arrived is what the
  /// reception says.
  Future<ShipmentOutcome<ShipmentOut>> markDelivered({
    required String shipmentId,
    String? note,
    DateTime? deliveredAt,
  }) => _guard(
    () => _shipmentsApi.markDeliveredV1ShipmentsShipmentIdDeliveredPost(
      shipmentId: shipmentId,
      body: DeliveredIn(note: note, deliveredAt: deliveredAt),
    ),
  );

  /// Records what arrived, box by box, and leaves the shipment `RECONCILED`.
  ///
  /// [exceptions] carries **only** what did not arrive well: the server takes
  /// everything that is not marked as received. [palletWeights] is what each
  /// pallet weighed on arrival; the server compares it with what it weighed
  /// when it was closed and opens an incident if they differ by too much — how
  /// much «de más» is, is its own criterion and does not travel this far.
  ///
  /// It is done once: correcting a reception is an incident with its note, not
  /// rewriting what has already travelled into a report.
  Future<ShipmentOutcome<ReceptionOut>> registerReception({
    required String shipmentId,
    List<ReceptionExceptionIn> exceptions = const [],
    List<ReceptionPalletWeightIn> palletWeights = const [],
    String? consigneeName,
    String? notes,
  }) => _guard(
    () => _shipmentsApi.reconcileReceptionV1ShipmentsShipmentIdReceptionPost(
      shipmentId: shipmentId,
      body: ReceptionCreate(
        exceptions: exceptions,
        palletWeights: palletWeights,
        consigneeName: consigneeName,
        notes: notes,
      ),
    ),
  );

  /// The three documents the server assembles, besides the manifest in PDF.
  ///
  /// None of them is drawn here: the file is handed to the system's viewer.
  Future<DocumentOutcome> document(
    String shipmentId,
    ShipmentDocument document, {
    Future<void> Function(Duration) wait = Future.delayed,
  }) => awaitDocument(
    start: () => switch (document) {
      ShipmentDocument.manifestPdf =>
        _shipmentsApi.downloadManifestV1ShipmentsShipmentIdManifestPdfPost(
          shipmentId: shipmentId,
        ),
      ShipmentDocument.manifestXlsx =>
        _shipmentsApi.downloadManifestXlsxV1ShipmentsShipmentIdManifestXlsxPost(
          shipmentId: shipmentId,
        ),
      ShipmentDocument.declarationJson =>
        _shipmentsApi
            .downloadDeclarationJsonV1ShipmentsShipmentIdDeclaracionJsonPost(
              shipmentId: shipmentId,
            ),
      ShipmentDocument.declarationXlsx =>
        _shipmentsApi
            .downloadDeclarationXlsxV1ShipmentsShipmentIdDeclaracionXlsxPost(
              shipmentId: shipmentId,
            ),
    },
    exports: _exportsApi,
    wait: wait,
  );

  Future<ShipmentOutcome<T>> _guard<T>(Future<T> Function() attempt) async {
    try {
      return ShipmentDone(await attempt());
    } on Object catch (error) {
      return ShipmentRefused(ApiErrorMapper.fromAny(error));
    }
  }

  Future<List<QrEventOut>> events(String shipmentId) => _shipmentsApi
      .listShipmentEventsV1ShipmentsShipmentIdEventsGet(shipmentId: shipmentId);

  /// Asks for the manifest and waits for the server to generate it.
  Future<DocumentOutcome> manifest(
    String shipmentId, {
    Future<void> Function(Duration) wait = Future.delayed,
  }) => awaitDocument(
    start: () =>
        _shipmentsApi.downloadManifestV1ShipmentsShipmentIdManifestPdfPost(
          shipmentId: shipmentId,
        ),
    exports: _exportsApi,
    wait: wait,
  );
}

/// An event of the shipment, already read for display.
///
/// A milestone and a state change arrive through the same place and are told
/// apart in that the milestone does not move the state. Showing them alike
/// would make the timeline unreadable exactly where it is consulted most: when
/// something was delayed.
///
/// **The state is translated with whichever table belongs to the object.** One
/// same `QrEventOut` describes the journey of a shipment, of a box or of a
/// pallet, and the three have different vocabularies. Before it was asked for
/// as a parameter this function painted the raw key — «OPEN → CLOSED» — on the
/// only screen that used it, which is the eighth time this repository has paid
/// for the same thing.
({String title, String? note, DateTime at}) describeEvent(
  AppLocalizations l10n,
  QrEventOut event, {
  required String Function(String) statusLabel,
}) {
  final milestone = event.milestone;
  final from = event.fromStatus;
  final title = milestone != null
      ? milestoneLabel(l10n, milestone)
      : '${from == null ? '—' : statusLabel(from)} → '
            '${statusLabel(event.toStatus)}';

  return (title: title, note: event.note, at: event.ts);
}
