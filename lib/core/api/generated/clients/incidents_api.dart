// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/incident_out.dart';
import '../models/incident_resolve.dart';

part 'incidents_api.g.dart';

@RestApi()
abstract class IncidentsApi {
  factory IncidentsApi(Dio dio, {String? baseUrl}) = _IncidentsApi;

  /// List Incidents.
  ///
  /// Bandeja de incidencias. El coordinador ve las de su centro; el nacional, todas.
  @GET('/v1/incidents')
  Future<List<IncidentOut>> listIncidentsV1IncidentsGet({
    @Query('limit') int? limit = 100,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
  });

  /// Resolve Incident
  @POST('/v1/incidents/{incident_id}/resolve')
  Future<IncidentOut> resolveIncidentV1IncidentsIncidentIdResolvePost({
    @Path('incident_id') required String incidentId,
    @Body() required IncidentResolve body,
  });
}
