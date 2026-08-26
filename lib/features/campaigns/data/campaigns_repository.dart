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

/// The campaigns: reading them, and creating them for whoever can.
///
/// **The module carries two different permissions and it is worth it showing.**
/// Listing and reading require coordination; creating and editing, national
/// administration. The panel splits it into two places in its navigation for
/// the same reason, and here it is resolved by not offering what is going to
/// answer 403.
///
/// `GET /v1/campaigns/mine` is not here: the capture calls it and has since
/// phase 05, and it only requires a centre role, so whoever volunteers goes on
/// choosing a campaign even though they cannot open its record.
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
