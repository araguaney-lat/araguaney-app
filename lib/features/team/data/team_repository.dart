import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/campaigns_api.dart';
import '../../../core/api/generated/clients/users_api.dart';
import '../../../core/api/generated/models/campaign_member_add.dart';
import '../../../core/api/generated/models/campaign_member_out.dart';
import '../../../core/api/generated/models/user_invite.dart';
import '../../../core/api/generated/models/user_out.dart';

/// Cómo se lee un rol de centro.
String centerRoleLabel(String? role) => switch (role) {
  'volunteer' => 'Voluntariado',
  'coordinator' => 'Coordinación',
  'national_admin' => 'Administración nacional',
  null => 'Sin rol',
  _ => role,
};

/// Cómo terminó una operación sobre el equipo.
sealed class TeamOutcome {
  const TeamOutcome();
}

final class TeamChanged extends TeamOutcome {
  const TeamChanged({this.notice});

  /// Lo que hay que contarle a quien lo pidió, cuando hay algo que contar:
  /// invitar y reinvitar mandan un correo, y eso no se ve desde aquí.
  final String? notice;
}

final class TeamRefused extends TeamOutcome {
  const TeamRefused(this.failure);

  final ApiFailure failure;

  String get message => failure.operatorMessage;
}

/// El equipo del centro y quién participa en cada campaña.
///
/// Todo esto es en línea y lo decide el servidor: quien coordina solo ve y
/// toca gente de su propio centro, y el backend lo comprueba en cada llamada.
/// Aquí no se replica esa regla, solo se evita ofrecer lo que va a fallar.
class TeamRepository {
  TeamRepository({required CampaignsApi campaigns, required UsersApi users})
    : _campaignsApi = campaigns,
      _usersApi = users;

  final CampaignsApi _campaignsApi;
  final UsersApi _usersApi;

  Future<List<UserOut>> centerUsers(String centerId) =>
      _usersApi.listCenterUsersV1CentersCenterIdUsersGet(centerId: centerId);

  Future<List<CampaignMemberOut>> members(String campaignId) => _campaignsApi
      .listMembersV1CampaignsCampaignIdMembersGet(campaignId: campaignId);

  Future<TeamOutcome> addMember({
    required String campaignId,
    required String userId,
  }) => _attempt(
    () => _campaignsApi.addMemberV1CampaignsCampaignIdMembersPost(
      campaignId: campaignId,
      body: CampaignMemberAdd(userId: userId),
    ),
  );

  Future<TeamOutcome> removeMember({
    required String campaignId,
    required String userId,
  }) => _attempt(
    () => _campaignsApi.removeMemberV1CampaignsCampaignIdMembersUserIdDelete(
      campaignId: campaignId,
      userId: userId,
    ),
  );

  /// Da de alta a alguien en el centro.
  ///
  /// La contraseña la genera el servidor y viaja por correo: desde aquí no se
  /// ve ni se elige, y por eso el aviso dice que hay que esperar ese correo.
  Future<TeamOutcome> invite({
    required String centerId,
    required String email,
    required String username,
    String? fullName,
    required String centerRole,
  }) => _attempt(
    () => _usersApi.inviteUserV1CentersCenterIdUsersPost(
      centerId: centerId,
      body: UserInvite(
        email: email,
        username: username,
        fullName: fullName,
        centerRole: centerRole,
      ),
    ),
    notice: 'Invitación enviada por correo.',
  );

  /// Vuelve a mandar el acceso. La contraseña anterior deja de servir.
  Future<TeamOutcome> reinvite({
    required String centerId,
    required String userId,
  }) => _attempt(
    () => _usersApi.reinviteCenterUserV1CentersCenterIdUsersUserIdReinvitePost(
      centerId: centerId,
      userId: userId,
    ),
    notice: 'Se envió un acceso nuevo por correo.',
  );

  Future<TeamOutcome> _attempt(
    Future<void> Function() call, {
    String? notice,
  }) async {
    try {
      await call();
      return TeamChanged(notice: notice);
    } on Object catch (error) {
      return TeamRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
