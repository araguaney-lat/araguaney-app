// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/request_create.dart';
import '../models/request_message_create.dart';
import '../models/request_message_out.dart';
import '../models/request_out.dart';
import '../models/request_status_patch.dart';

part 'requests_api.g.dart';

@RestApi()
abstract class RequestsApi {
  factory RequestsApi(Dio dio, {String? baseUrl}) = _RequestsApi;

  /// List Requests
  @GET('/v1/requests')
  Future<List<RequestOut>> listRequestsV1RequestsGet({
    @Query('limit') int? limit = 50,
    @Query('offset') int? offset = 0,
    @Query('status') String? status,
  });

  /// Create Request
  @POST('/v1/requests')
  Future<RequestOut> createRequestV1RequestsPost({
    @Body() required RequestCreate body,
  });

  /// Get Request
  @GET('/v1/requests/{request_id}')
  Future<RequestOut> getRequestV1RequestsRequestIdGet({
    @Path('request_id') required String requestId,
  });

  /// Match Request With Stock.
  ///
  /// Qué categorías pide esta solicitud y qué stock hay de cada una.
  ///
  /// El stock sale de la base y viene acotado por centro: un coordinador no.
  /// descubre por aquí el inventario de otro. Lista vacía si la IA no está.
  @GET('/v1/requests/{request_id}/matches')
  Future<dynamic> matchRequestWithStockV1RequestsRequestIdMatchesGet({
    @Path('request_id') required String requestId,
  });

  /// Add Message
  @POST('/v1/requests/{request_id}/messages')
  Future<RequestMessageOut> addMessageV1RequestsRequestIdMessagesPost({
    @Path('request_id') required String requestId,
    @Body() required RequestMessageCreate body,
  });

  /// Update Status
  @PATCH('/v1/requests/{request_id}/status')
  Future<RequestOut> updateStatusV1RequestsRequestIdStatusPatch({
    @Path('request_id') required String requestId,
    @Body() required RequestStatusPatch body,
  });
}
