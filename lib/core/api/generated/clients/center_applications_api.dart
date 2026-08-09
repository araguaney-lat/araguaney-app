// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/center_application_confirm.dart';
import '../models/center_application_create.dart';
import '../models/center_application_out.dart';
import '../models/center_application_reject.dart';
import '../models/center_application_submit_out.dart';

part 'center_applications_api.g.dart';

@RestApi()
abstract class CenterApplicationsApi {
  factory CenterApplicationsApi(Dio dio, {String? baseUrl}) =
      _CenterApplicationsApi;

  /// List Queue
  @GET('/v1/center-applications')
  Future<List<CenterApplicationOut>> listQueueV1CenterApplicationsGet();

  /// Approve Application
  @POST('/v1/center-applications/{app_id}/approve')
  Future<CenterApplicationOut>
  approveApplicationV1CenterApplicationsAppIdApprovePost({
    @Path('app_id') required String appId,
  });

  /// Reject Application
  @POST('/v1/center-applications/{app_id}/reject')
  Future<CenterApplicationOut>
  rejectApplicationV1CenterApplicationsAppIdRejectPost({
    @Path('app_id') required String appId,
    @Body() required CenterApplicationReject body,
  });

  /// Submit Application
  @POST('/v1/public/center-applications')
  Future<CenterApplicationSubmitOut>
  submitApplicationV1PublicCenterApplicationsPost({
    @Body() required CenterApplicationCreate body,
  });

  /// Confirm Application Email
  @POST('/v1/public/center-applications/confirm')
  Future<CenterApplicationSubmitOut>
  confirmApplicationEmailV1PublicCenterApplicationsConfirmPost({
    @Body() required CenterApplicationConfirm body,
  });
}
