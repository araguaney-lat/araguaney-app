import '../../../core/api/generated/clients/dashboard_api.dart';
import '../../../core/api/generated/models/national_dashboard_out.dart';

/// The aggregates of the centre of whoever is looking.
///
/// The endpoint's name says «national» and misleads: the server narrows it with
/// `tenant_scope`, so coordination and volunteers receive **their** centre and
/// only national administration receives them all. The client sends no centre
/// and cannot ask for somebody else's.
///
/// This one really is stock: it counts boxes in the `SEALED` state. That is the
/// difference from the per-campaign report, which counts what was captured in a
/// window without looking at the state — and that is why that reading was
/// withdrawn in favour of this one.
class CenterDashboardRepository {
  CenterDashboardRepository(this._dashboardApi);

  final DashboardApi _dashboardApi;

  Future<NationalDashboardOut> aggregates() =>
      _dashboardApi.nationalDashboardV1DashboardNationalGet();
}
