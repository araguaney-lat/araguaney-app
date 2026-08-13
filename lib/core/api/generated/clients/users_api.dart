// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/message_out.dart';
import '../models/user_invite.dart';
import '../models/user_out.dart';

part 'users_api.g.dart';

@RestApi()
abstract class UsersApi {
  factory UsersApi(Dio dio, {String? baseUrl}) = _UsersApi;

  /// List Center Users
  @GET('/v1/centers/{center_id}/users')
  Future<List<UserOut>> listCenterUsersV1CentersCenterIdUsersGet({
    @Path('center_id') required String centerId,
  });

  /// Invite User
  @POST('/v1/centers/{center_id}/users')
  Future<UserOut> inviteUserV1CentersCenterIdUsersPost({
    @Path('center_id') required String centerId,
    @Body() required UserInvite body,
  });

  /// Reinvite Center User
  @POST('/v1/centers/{center_id}/users/{user_id}/reinvite')
  Future<MessageOut>
  reinviteCenterUserV1CentersCenterIdUsersUserIdReinvitePost({
    @Path('center_id') required String centerId,
    @Path('user_id') required String userId,
  });
}
