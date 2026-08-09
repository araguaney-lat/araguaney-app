// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/export_job_out.dart';
import '../models/pallet_close_in.dart';
import '../models/pallet_create.dart';
import '../models/pallet_detail_out.dart';
import '../models/pallet_out.dart';
import '../models/qr_event_out.dart';

part 'pallets_api.g.dart';

@RestApi()
abstract class PalletsApi {
  factory PalletsApi(Dio dio, {String? baseUrl}) = _PalletsApi;

  /// List Pallets
  @GET('/v1/pallets')
  Future<List<PalletOut>> listPalletsV1PalletsGet({
    @Query('limit') int? limit = 200,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
  });

  /// Create Pallet
  @POST('/v1/pallets')
  Future<PalletOut> createPalletV1PalletsPost({
    @Body() required PalletCreate body,
  });

  /// Get Pallet
  @GET('/v1/pallets/{pallet_id}')
  Future<PalletDetailOut> getPalletV1PalletsPalletIdGet({
    @Path('pallet_id') required String palletId,
  });

  /// Add Box To Pallet
  @POST('/v1/pallets/{pallet_id}/add-box')
  Future<PalletDetailOut> addBoxToPalletV1PalletsPalletIdAddBoxPost({
    @Path('pallet_id') required String palletId,
    @Body() required dynamic body,
  });

  /// Remove Box From Pallet
  @DELETE('/v1/pallets/{pallet_id}/boxes/{box_code}')
  Future<PalletDetailOut>
  removeBoxFromPalletV1PalletsPalletIdBoxesBoxCodeDelete({
    @Path('pallet_id') required String palletId,
    @Path('box_code') required String boxCode,
  });

  /// Close Pallet.
  ///
  /// El pesaje viaja en el cierre porque es cuando ocurre: la tarima ya está.
  /// armada y sube a la báscula una sola vez.
  @POST('/v1/pallets/{pallet_id}/close')
  Future<PalletOut> closePalletV1PalletsPalletIdClosePost({
    @Path('pallet_id') required String palletId,
    @Body() PalletCloseIn? body,
  });

  /// List Pallet Events
  @GET('/v1/pallets/{pallet_id}/events')
  Future<List<QrEventOut>> listPalletEventsV1PalletsPalletIdEventsGet({
    @Path('pallet_id') required String palletId,
  });

  /// Pallet Label Pdf.
  ///
  /// Queue the pallet label PDF generation (rate-limited). Poll GET /v1/exports/{id}.
  @POST('/v1/pallets/{pallet_id}/label.pdf')
  Future<ExportJobOut> palletLabelPdfV1PalletsPalletIdLabelPdfPost({
    @Path('pallet_id') required String palletId,
  });
}
