// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/donor_out.dart';
import '../models/intake_create.dart';
import '../models/intake_out.dart';

part 'intakes_api.g.dart';

@RestApi()
abstract class IntakesApi {
  factory IntakesApi(Dio dio, {String? baseUrl}) = _IntakesApi;

  /// List Intakes
  @GET('/v1/intakes')
  Future<List<IntakeOut>> listIntakesV1IntakesGet({
    @Query('limit') int? limit = 200,
    @Query('offset') int? offset = 0,
  });

  /// Create Intake
  @POST('/v1/intakes')
  Future<IntakeOut> createIntakeV1IntakesPost({
    @Body() required IntakeCreate body,
  });

  /// Search Donors.
  ///
  /// Autocompletado de donantes del propio centro.
  ///
  /// Scoped siempre: la cartera de donantes no cruza entre centros. Un.
  /// national_admin (scope None) no tiene centro propio, así que debe indicar.
  /// cuál consulta.
  @GET('/v1/intakes/donors/search')
  Future<List<DonorOut>> searchDonorsV1IntakesDonorsSearchGet({
    @Query('q') required String q,
  });
}
