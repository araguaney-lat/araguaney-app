// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_schemas_box_box_out.dart';
import '../models/box_code_block_out.dart';
import '../models/box_code_reserve_in.dart';
import '../models/box_public_out.dart';
import '../models/export_job_out.dart';
import '../models/qr_event_out.dart';

part 'boxes_api.g.dart';

@RestApi()
abstract class BoxesApi {
  factory BoxesApi(Dio dio, {String? baseUrl}) = _BoxesApi;

  /// Box Public Ficha.
  ///
  /// Public box ficha — called via Next.js proxy (Turnstile-gated). No edge cache.
  @GET('/b/{code}')
  Future<BoxPublicOut> boxPublicFichaBCodeGet({
    @Path('code') required String code,
  });

  /// List Boxes
  @GET('/v1/boxes')
  Future<List<AppSchemasBoxBoxOut>> listBoxesV1BoxesGet({
    @Query('limit') int? limit = 200,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
  });

  /// Available Box Codes.
  ///
  /// Cuántos códigos sin usar quedan. El cliente lo consulta para reponer.
  @GET('/v1/boxes/codes/available')
  Future<BoxCodeBlockOut> availableBoxCodesV1BoxesCodesAvailableGet();

  /// Reserve Box Codes.
  ///
  /// Aparta un bloque de códigos para capturar sin conexión.
  ///
  /// Se pide **con** señal, para consumirlo sin ella. El límite por hora es.
  /// holgado para reponer antes de una jornada y estrecho para que un cliente en.
  /// bucle no aparte miles de números.
  @POST('/v1/boxes/codes/reserve')
  Future<BoxCodeBlockOut> reserveBoxCodesV1BoxesCodesReservePost({
    @Body() required BoxCodeReserveIn body,
  });

  /// Download Labels Pdf.
  ///
  /// Queue A4 multi-label PDF generation for boxes (10 per page, rate-limited). Poll GET /v1/exports/{id}.
  @POST('/v1/boxes/labels/pdf')
  Future<ExportJobOut> downloadLabelsPdfV1BoxesLabelsPdfPost({
    @Query('status') String? status = 'DRAFT',
  });

  /// Get Box
  @GET('/v1/boxes/{box_id}')
  Future<AppSchemasBoxBoxOut> getBoxV1BoxesBoxIdGet({
    @Path('box_id') required String boxId,
  });

  /// List Box Events
  @GET('/v1/boxes/{box_id}/events')
  Future<List<QrEventOut>> listBoxEventsV1BoxesBoxIdEventsGet({
    @Path('box_id') required String boxId,
  });

  /// Box Qr Authenticated.
  ///
  /// QR PNG accessible with auth (for label preview before seal).
  @GET('/v1/boxes/{box_id}/qr.png')
  Future<void> boxQrAuthenticatedV1BoxesBoxIdQrPngGet({
    @Path('box_id') required String boxId,
  });

  /// Seal Box
  @POST('/v1/boxes/{box_id}/seal')
  Future<AppSchemasBoxBoxOut> sealBoxV1BoxesBoxIdSealPost({
    @Path('box_id') required String boxId,
  });
}
