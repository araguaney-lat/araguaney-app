import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/center_applications_api.dart';
import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/api/generated/models/center_application_reject.dart';

/// Cómo terminó una lectura o una decisión sobre postulaciones.
sealed class ApplicationsOutcome<T> {
  const ApplicationsOutcome();
}

final class ApplicationsRead<T> extends ApplicationsOutcome<T> {
  const ApplicationsRead(this.value);

  final T value;
}

final class ApplicationsRefused<T> extends ApplicationsOutcome<T> {
  const ApplicationsRefused(this.failure);

  final ApiFailure failure;

  /// Si el rechazo es «no te toca» y no un fallo.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// La cola de postulaciones de centro, y las dos decisiones.
///
/// **La cola solo trae lo que espera revisión.** El backend filtra por
/// `PENDING_REVIEW`, de la más vieja a la más nueva, y una administración
/// nacional la ve acotada a su país mientras que una superadministración las ve
/// todas. Así que esto es una cola y no un historial: decidir una la saca.
///
/// Las dos decisiones exigen conexión, y no por comodidad: aprobar crea cosas
/// en el servidor y rechazar manda un correo.
class CenterApplicationsRepository {
  CenterApplicationsRepository(this._applications);

  final CenterApplicationsApi _applications;

  Future<ApplicationsOutcome<List<CenterApplicationOut>>> queue() async {
    try {
      return ApplicationsRead(
        await _applications.listQueueV1CenterApplicationsGet(),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Aprobar, que hace **tres cosas** en el servidor: crea el centro, da de
  /// alta a quien postuló como su coordinación, y le manda por correo una
  /// contraseña temporal.
  ///
  /// Nada de eso se deshace desde aquí, y por eso la pantalla lo dice antes.
  Future<ApplicationsOutcome<CenterApplicationOut>> approve(String id) async {
    try {
      return ApplicationsRead(
        await _applications
            .approveApplicationV1CenterApplicationsAppIdApprovePost(appId: id),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Rechazar. El motivo **viaja por correo a quien postuló**, así que lo que
  /// se escriba aquí lo va a leer alguien de fuera de la plataforma.
  Future<ApplicationsOutcome<CenterApplicationOut>> reject(
    String id,
    String reason,
  ) async {
    try {
      return ApplicationsRead(
        await _applications
            .rejectApplicationV1CenterApplicationsAppIdRejectPost(
              appId: id,
              body: CenterApplicationReject(reason: reason),
            ),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
