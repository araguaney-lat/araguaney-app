import '../../../core/api/generated/clients/dashboard_api.dart';
import '../../../core/api/generated/models/national_dashboard_out.dart';

/// Los agregados del centro de quien mira.
///
/// El nombre del endpoint dice «national» y engaña: el servidor lo acota con
/// `tenant_scope`, así que coordinación y voluntariado reciben **su** centro y
/// solo la administración nacional recibe todos. El cliente no envía centro y
/// no puede pedir el de otro.
///
/// Esto sí es stock: cuenta cajas en estado `SEALED`. Es la diferencia con el
/// informe por campaña, que cuenta lo capturado en una ventana sin mirar el
/// estado — y por eso esa lectura se retiró en favor de esta.
class CenterDashboardRepository {
  CenterDashboardRepository(this._dashboardApi);

  final DashboardApi _dashboardApi;

  Future<NationalDashboardOut> aggregates() =>
      _dashboardApi.nationalDashboardV1DashboardNationalGet();
}
