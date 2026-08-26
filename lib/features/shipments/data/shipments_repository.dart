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

/// Los documentos que el servidor produce para un envío.
///
/// Se nombran aquí y no en la pantalla porque son cuatro rutas distintas para
/// lo que desde arriba es un solo gesto: pedir un papel.
enum ShipmentDocument {
  manifestPdf,
  manifestXlsx,
  declarationJson,
  declarationXlsx,
}

/// Los siete hitos de `SHIPMENT_MILESTONES`, en el orden del viaje.
///
/// La lista vive aquí porque es vocabulario del servidor: escribir uno que no
/// esté produce `INVALID_MILESTONE`, así que se eligen y no se teclean.
const shipmentMilestones = [
  'DEPARTED_WAREHOUSE',
  'ARRIVED_AIRPORT',
  'LOADED_AIRCRAFT',
  'DEPARTED_FLIGHT',
  'ARRIVED_DESTINATION',
  'CUSTOMS_CLEARED',
  'DELIVERED_CONSIGNEE',
];

/// Cómo puede terminar una caja al recibirse.
///
/// Cuatro estados de `RECEPTION_OUTCOMES`, y **solo tres viajan**: lo que no
/// se marca el servidor lo da por recibido. Tres de los cuatro abren una
/// incidencia del lado del servidor, que es donde esa decisión vive.
abstract final class ReceptionOutcome {
  static const received = 'RECEIVED';
  static const missing = 'MISSING';
  static const damaged = 'DAMAGED';
  static const retainedCustoms = 'RETAINED_CUSTOMS';

  /// Lo que se puede marcar: recibido es la ausencia de marca.
  static const exceptions = [missing, damaged, retainedCustoms];
}

/// Hitos logísticos que reconoce el backend.
///
/// Un hito es un evento con el mismo estado a ambos lados: registra que algo
/// pasó sin inventar estados intermedios, para que la máquina no crezca con
/// cada aeropuerto. **Anotarlos exige administración nacional**, así que desde
/// aquí solo se leen.
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

/// Cómo terminó una operación sobre un envío.
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

  /// Cuántas veces se pregunta por el trabajo antes de rendirse.
  ///
  /// Sondear tiene que terminar: dejar a alguien mirando una rueda para siempre
  /// es peor que decirle que vuelva a intentarlo. Si se acaba el margen, el
  /// trabajo sigue vivo en el servidor y pedirlo otra vez lo recoge.

  final ShipmentsApi _shipmentsApi;
  final ExportsApi _exportsApi;

  /// Los envíos del centro. El servidor los acota al de quien pregunta.
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

  /// El contrato declara este cuerpo sin tipo, así que el mapa se escribe aquí
  /// y en un solo sitio. Es la petición 4 de `backend-requests.md`.
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

  /// Cerrar deja de admitir tarimas; despachar dice que salió. Las dos son de
  /// una sola dirección y el servidor no las deshace, así que la interfaz
  /// pregunta antes.
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

  /// Anota un hito logístico sin mover el estado.
  ///
  /// Es el que más sentido tiene en un teléfono y no está cerca: alguien está
  /// junto a un camión, en un puesto de control, sin escritorio. [occurredAt]
  /// es opcional porque el reporte del consignatario suele llegar tarde y
  /// describir algo de ayer.
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

  /// `SHIPPED` → `DELIVERED`. Llegó; **qué** llegó lo dice la recepción.
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

  /// Registra qué llegó, caja por caja, y deja el envío en `RECONCILED`.
  ///
  /// [exceptions] lleva **solo** lo que no llegó bien: el servidor da por
  /// recibido todo lo que no viene marcado. [palletWeights] es lo que pesó cada
  /// tarima al llegar; el servidor lo compara con lo que pesaba al cerrarse y
  /// abre una incidencia si difieren de más — cuánto es «de más» es criterio
  /// suyo y no viaja hasta aquí.
  ///
  /// Se hace una sola vez: corregir una recepción es una incidencia con su
  /// nota, no reescribir lo que ya viajó a un informe.
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

  /// Los tres documentos que el servidor arma, además del manifiesto en PDF.
  ///
  /// Ninguno se dibuja aquí: el archivo se le entrega al visor del sistema.
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

  /// Pide el manifiesto y espera a que el servidor lo genere.
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

/// Un evento del envío, ya interpretado para leerse.
///
/// Un hito y un cambio de estado llegan por el mismo sitio y se distinguen en
/// que el hito no mueve el estado. Mostrarlos igual haría ilegible la línea de
/// tiempo justo donde más se consulta: cuando algo se retrasó.
///
/// **El estado se traduce con la tabla que corresponda al objeto.** Un mismo
/// `QrEventOut` describe el recorrido de un envío, de una caja o de una tarima,
/// y las tres tienen vocabularios distintos. Antes de pedirla como parámetro
/// esta función pintaba la clave cruda —«OPEN → CLOSED»— en la única pantalla
/// que la usaba, que es la octava vez que este repositorio paga lo mismo.
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
