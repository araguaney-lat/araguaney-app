import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/campaigns_api.dart';
import '../../../core/api/generated/models/campaign_create.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/campaign_update.dart';

sealed class CampaignOutcome<T> {
  const CampaignOutcome();
}

final class CampaignRead<T> extends CampaignOutcome<T> {
  const CampaignRead(this.value);

  final T value;
}

final class CampaignRefused<T> extends CampaignOutcome<T> {
  const CampaignRefused(this.failure);

  final ApiFailure failure;

  bool get isForbidden => failure is ForbiddenFailure;
}

/// Las campañas: leerlas, y crearlas para quien puede.
///
/// **El módulo lleva dos permisos distintos y conviene que se note.** Listar y
/// leer exigen coordinación; crear y editar, administración nacional. El panel
/// lo parte en dos sitios de su navegación por la misma razón, y aquí se
/// resuelve no ofreciendo lo que va a responder 403.
///
/// `GET /v1/campaigns/mine` no está aquí: lo llama la captura desde la fase 05
/// y solo exige rol de centro, así que quien es voluntariado sigue eligiendo
/// campaña aunque no pueda abrir su ficha.
class CampaignsRepository {
  CampaignsRepository(this._campaigns);

  final CampaignsApi _campaigns;

  Future<CampaignOutcome<List<CampaignOut>>> list({bool activeOnly = true}) =>
      _guard(
        () => _campaigns.listCampaignsV1CampaignsGet(activeOnly: activeOnly),
      );

  Future<CampaignOutcome<CampaignOut>> byId(String campaignId) => _guard(
    () =>
        _campaigns.getCampaignV1CampaignsCampaignIdGet(campaignId: campaignId),
  );

  Future<CampaignOutcome<CampaignOut>> create(CampaignCreate data) =>
      _guard(() => _campaigns.createCampaignV1CampaignsPost(body: data));

  Future<CampaignOutcome<CampaignOut>> update(
    String campaignId,
    CampaignUpdate data,
  ) => _guard(
    () => _campaigns.updateCampaignV1CampaignsCampaignIdPatch(
      campaignId: campaignId,
      body: data,
    ),
  );

  Future<CampaignOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return CampaignRead(await call());
    } on Object catch (error) {
      return CampaignRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
