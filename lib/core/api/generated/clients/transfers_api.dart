// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/export_job_out.dart';
import '../models/transfer_create.dart';
import '../models/transfer_detail_out.dart';
import '../models/transfer_out.dart';
import '../models/transfer_reject.dart';

part 'transfers_api.g.dart';

@RestApi()
abstract class TransfersApi {
  factory TransfersApi(Dio dio, {String? baseUrl}) = _TransfersApi;

  /// List Transfers
  @GET('/v1/transfers')
  Future<List<TransferOut>> listTransfersV1TransfersGet({
    @Query('limit') int? limit = 200,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
    @Query('from_center_id') String? fromCenterId,
    @Query('to_center_id') String? toCenterId,
  });

  /// Create Transfer
  @POST('/v1/transfers')
  Future<TransferOut> createTransferV1TransfersPost({
    @Body() required TransferCreate body,
  });

  /// List Transfers Studio.
  ///
  /// All transfers across all centers — superadmin only.
  @GET('/v1/transfers/studio')
  Future<List<TransferOut>> listTransfersStudioV1TransfersStudioGet({
    @Query('status') String? status,
  });

  /// Get Transfer
  @GET('/v1/transfers/{transfer_id}')
  Future<TransferDetailOut> getTransferV1TransfersTransferIdGet({
    @Path('transfer_id') required String transferId,
  });

  /// Approve Transfer
  @POST('/v1/transfers/{transfer_id}/approve')
  Future<TransferOut> approveTransferV1TransfersTransferIdApprovePost({
    @Path('transfer_id') required String transferId,
  });

  /// Dispatch Transfer
  @POST('/v1/transfers/{transfer_id}/dispatch')
  Future<TransferOut> dispatchTransferV1TransfersTransferIdDispatchPost({
    @Path('transfer_id') required String transferId,
  });

  /// Download Transfer Manifest.
  ///
  /// Queue the transfer manifest PDF generation (rate-limited: 2/min). Poll GET /v1/exports/{id}.
  @POST('/v1/transfers/{transfer_id}/manifest.pdf')
  Future<ExportJobOut>
  downloadTransferManifestV1TransfersTransferIdManifestPdfPost({
    @Path('transfer_id') required String transferId,
  });

  /// Receive Transfer
  @POST('/v1/transfers/{transfer_id}/receive')
  Future<TransferOut> receiveTransferV1TransfersTransferIdReceivePost({
    @Path('transfer_id') required String transferId,
  });

  /// Reject Transfer
  @POST('/v1/transfers/{transfer_id}/reject')
  Future<TransferOut> rejectTransferV1TransfersTransferIdRejectPost({
    @Path('transfer_id') required String transferId,
    @Body() required TransferReject body,
  });
}
