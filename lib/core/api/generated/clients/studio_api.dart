// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/ai_usage_report_out.dart';
import '../models/audit_list_out.dart';
import '../models/message_out.dart';
import '../models/product_type_out.dart';
import '../models/studio_user_create.dart';
import '../models/studio_user_patch.dart';
import '../models/user_out.dart';

part 'studio_api.g.dart';

@RestApi()
abstract class StudioApi {
  factory StudioApi(Dio dio, {String? baseUrl}) = _StudioApi;

  /// Ai Usage Report.
  ///
  /// Cuánto lleva gastado la IA este mes, por capacidad y por día.
  ///
  /// Solo lee. Encender o apagar una capacidad se hace en las variables de.
  /// entorno: un panel que también pudiera cambiarlo sería una segunda fuente de.
  /// verdad sobre el mismo interruptor.
  ///
  /// Es de `superadmin` porque el gasto es de la plataforma, no de un centro.
  @GET('/v1/studio/ai-usage')
  Future<AiUsageReportOut> aiUsageReportV1StudioAiUsageGet();

  /// List Audit
  @GET('/v1/studio/audit')
  Future<AuditListOut> listAuditV1StudioAuditGet({
    @Query('limit') int? limit = 50,
    @Query('offset') int? offset = 0,
    @Query('entity_type') String? entityType,
    @Query('user_id') String? userId,
    @Query('from_date') DateTime? fromDate,
    @Query('to_date') DateTime? toDate,
  });

  /// Promote Product Type.
  ///
  /// Promote a campaign-scoped product type to global (campaign_id → NULL).
  @POST('/v1/studio/product-types/{pt_id}/promote')
  Future<ProductTypeOut> promoteProductTypeV1StudioProductTypesPtIdPromotePost({
    @Path('pt_id') required String ptId,
  });

  /// List Users
  @GET('/v1/studio/users')
  Future<List<UserOut>> listUsersV1StudioUsersGet({
    @Query('limit') int? limit = 50,
    @Query('offset') int? offset = 0,
    @Query('center_id') String? centerId,
    @Query('center_role') String? centerRole,
    @Query('is_active') bool? isActive,
  });

  /// Create User
  @POST('/v1/studio/users')
  Future<UserOut> createUserV1StudioUsersPost({
    @Body() required StudioUserCreate body,
  });

  /// Patch User
  @PATCH('/v1/studio/users/{user_id}')
  Future<UserOut> patchUserV1StudioUsersUserIdPatch({
    @Path('user_id') required String userId,
    @Body() required StudioUserPatch body,
  });

  /// Reinvite User
  @POST('/v1/studio/users/{user_id}/reinvite')
  Future<MessageOut> reinviteUserV1StudioUsersUserIdReinvitePost({
    @Path('user_id') required String userId,
  });
}
