// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/email_failure_out.dart';

part 'email_failures_api.g.dart';

@RestApi()
abstract class EmailFailuresApi {
  factory EmailFailuresApi(Dio dio, {String? baseUrl}) = _EmailFailuresApi;

  /// List Failures
  @GET('/v1/email-failures')
  Future<List<EmailFailureOut>> listFailuresV1EmailFailuresGet({
    @Query('event_type') String? eventType,
  });

  /// Resend Failure
  @POST('/v1/email-failures/{failure_id}/resend')
  Future<EmailFailureOut> resendFailureV1EmailFailuresFailureIdResendPost({
    @Path('failure_id') required String failureId,
  });
}
