// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/export_job_out.dart';

part 'exports_api.g.dart';

@RestApi()
abstract class ExportsApi {
  factory ExportsApi(Dio dio, {String? baseUrl}) = _ExportsApi;

  /// Get Export Job.
  ///
  /// Poll an async export job's status. Called every ~1.5s by the frontend while PENDING/RUNNING.
  @GET('/v1/exports/{job_id}')
  Future<ExportJobOut> getExportJobV1ExportsJobIdGet({
    @Path('job_id') required String jobId,
  });
}
