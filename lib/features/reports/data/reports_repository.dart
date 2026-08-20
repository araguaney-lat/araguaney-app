import '../../../core/api/generated/clients/reports_api.dart';
import '../../../core/api/generated/models/category_breakdown.dart';

/// Lo que el centro capturó, por categoría.
///
/// **El servidor decide el alcance, no esta clase.** El endpoint se acota solo
/// al centro de quien llama: coordinación y voluntariado ven el suyo, la
/// administración nacional ve todos. Aquí no se envía ningún centro, y no hay
/// forma de pedir el de otro.
///
/// Tampoco es stock, y la pantalla lo dice con esas palabras: cuenta cajas
/// creadas dentro de la ventana, sin mirar en qué estado están. Una caja que ya
/// se despachó sigue sumando aquí. Convertir esto en inventario exige un filtro
/// por estado que vive en el backend —petición 1—, y no se imita en el
/// dispositivo porque decidir qué estados cuentan *es* la regla.
class ReportsRepository {
  ReportsRepository(this._reportsApi);

  final ReportsApi _reportsApi;

  /// Sin fechas: el servidor responde por su ventana por defecto, que hoy son
  /// los últimos 30 días. La pantalla lo dice para que nadie lea el número como
  /// un acumulado histórico.
  Future<List<CategoryBreakdown>> byCategory(String campaignId) =>
      _reportsApi.getByCategoryV1ReportsCampaignCampaignIdByCategoryGet(
        campaignId: campaignId,
      );
}
