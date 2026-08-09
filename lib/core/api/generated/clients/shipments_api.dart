// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/delivered_in.dart';
import '../models/export_job_out.dart';
import '../models/incident_create.dart';
import '../models/incident_out.dart';
import '../models/milestone_in.dart';
import '../models/qr_event_out.dart';
import '../models/reception_create.dart';
import '../models/reception_out.dart';
import '../models/shipment_create.dart';
import '../models/shipment_detail_out.dart';
import '../models/shipment_out.dart';

part 'shipments_api.g.dart';

@RestApi()
abstract class ShipmentsApi {
  factory ShipmentsApi(Dio dio, {String? baseUrl}) = _ShipmentsApi;

  /// List Shipments
  @GET('/v1/shipments')
  Future<List<ShipmentOut>> listShipmentsV1ShipmentsGet({
    @Query('limit') int? limit = 200,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
  });

  /// Create Shipment
  @POST('/v1/shipments')
  Future<ShipmentOut> createShipmentV1ShipmentsPost({
    @Body() required ShipmentCreate body,
  });

  /// Get Shipment
  @GET('/v1/shipments/{shipment_id}')
  Future<ShipmentDetailOut> getShipmentV1ShipmentsShipmentIdGet({
    @Path('shipment_id') required String shipmentId,
  });

  /// Add Pallet To Shipment
  @POST('/v1/shipments/{shipment_id}/add-pallet')
  Future<ShipmentDetailOut>
  addPalletToShipmentV1ShipmentsShipmentIdAddPalletPost({
    @Path('shipment_id') required String shipmentId,
    @Body() required dynamic body,
  });

  /// Close Shipment
  @POST('/v1/shipments/{shipment_id}/close')
  Future<ShipmentOut> closeShipmentV1ShipmentsShipmentIdClosePost({
    @Path('shipment_id') required String shipmentId,
  });

  /// Download Declaration Json.
  ///
  /// El mismo documento en JSON, para quien lo integra con otro sistema.
  @POST('/v1/shipments/{shipment_id}/declaracion.json')
  Future<ExportJobOut>
  downloadDeclarationJsonV1ShipmentsShipmentIdDeclaracionJsonPost({
    @Path('shipment_id') required String shipmentId,
  });

  /// Download Declaration Xlsx.
  ///
  /// Declaración de mercancías del envío, en hoja de cálculo.
  ///
  /// Lleva lo que sabemos —qué va, cuánto pesa, cuántos bultos, de dónde a.
  /// dónde— y los datos que el propio centro capturó sobre sí mismo. No es un.
  /// comprobante fiscal ni una declaración aduanal: es el insumo para quien.
  /// despacha. Si el envío declara un perfil de país, además trae los nombres de.
  /// campo de ese régimen.
  @POST('/v1/shipments/{shipment_id}/declaracion.xlsx')
  Future<ExportJobOut>
  downloadDeclarationXlsxV1ShipmentsShipmentIdDeclaracionXlsxPost({
    @Path('shipment_id') required String shipmentId,
  });

  /// Mark Delivered
  @POST('/v1/shipments/{shipment_id}/delivered')
  Future<ShipmentOut> markDeliveredV1ShipmentsShipmentIdDeliveredPost({
    @Path('shipment_id') required String shipmentId,
    @Body() required DeliveredIn body,
  });

  /// List Shipment Events
  @GET('/v1/shipments/{shipment_id}/events')
  Future<List<QrEventOut>> listShipmentEventsV1ShipmentsShipmentIdEventsGet({
    @Path('shipment_id') required String shipmentId,
  });

  /// List Shipment Incidents
  @GET('/v1/shipments/{shipment_id}/incidents')
  Future<List<IncidentOut>>
  listShipmentIncidentsV1ShipmentsShipmentIdIncidentsGet({
    @Path('shipment_id') required String shipmentId,
  });

  /// Create Incident.
  ///
  /// El centro emisor también levanta incidencias: es quien nota lo que falta.
  @POST('/v1/shipments/{shipment_id}/incidents')
  Future<IncidentOut> createIncidentV1ShipmentsShipmentIdIncidentsPost({
    @Path('shipment_id') required String shipmentId,
    @Body() required IncidentCreate body,
  });

  /// Download Manifest.
  ///
  /// Queue shipment manifest PDF generation (rate-limited: 2/min). Poll GET /v1/exports/{id}.
  @POST('/v1/shipments/{shipment_id}/manifest.pdf')
  Future<ExportJobOut> downloadManifestV1ShipmentsShipmentIdManifestPdfPost({
    @Path('shipment_id') required String shipmentId,
  });

  /// Download Manifest Xlsx.
  ///
  /// Queue the IFRC packing list (.xlsx) generation (rate-limited: 2/min). Poll GET /v1/exports/{id}.
  @POST('/v1/shipments/{shipment_id}/manifest.xlsx')
  Future<ExportJobOut>
  downloadManifestXlsxV1ShipmentsShipmentIdManifestXlsxPost({
    @Path('shipment_id') required String shipmentId,
  });

  /// Add Milestone
  @POST('/v1/shipments/{shipment_id}/milestones')
  Future<ShipmentOut> addMilestoneV1ShipmentsShipmentIdMilestonesPost({
    @Path('shipment_id') required String shipmentId,
    @Body() required MilestoneIn body,
  });

  /// Remove Pallet From Shipment
  @DELETE('/v1/shipments/{shipment_id}/pallets/{pallet_id}')
  Future<ShipmentDetailOut>
  removePalletFromShipmentV1ShipmentsShipmentIdPalletsPalletIdDelete({
    @Path('shipment_id') required String shipmentId,
    @Path('pallet_id') required String palletId,
  });

  /// Get Reception.
  ///
  /// Lectura para el centro emisor también: le importa qué llegó de lo suyo.
  @GET('/v1/shipments/{shipment_id}/reception')
  Future<ReceptionOut> getReceptionV1ShipmentsShipmentIdReceptionGet({
    @Path('shipment_id') required String shipmentId,
  });

  /// Reconcile Reception.
  ///
  /// Registra qué llegó, caja por caja, y deja el envío en RECONCILED.
  @POST('/v1/shipments/{shipment_id}/reception')
  Future<ReceptionOut> reconcileReceptionV1ShipmentsShipmentIdReceptionPost({
    @Path('shipment_id') required String shipmentId,
    @Body() required ReceptionCreate body,
  });

  /// Ship Shipment
  @POST('/v1/shipments/{shipment_id}/ship')
  Future<ShipmentOut> shipShipmentV1ShipmentsShipmentIdShipPost({
    @Path('shipment_id') required String shipmentId,
  });
}
