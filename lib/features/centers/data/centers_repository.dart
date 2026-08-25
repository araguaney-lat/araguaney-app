import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/centers_api.dart';
import '../../../core/api/generated/models/center_create.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/center_update.dart';

/// Cómo terminó una lectura de centros.
///
/// Se devuelve como valor y no como excepción por la razón de siempre, y por
/// una propia de aquí: **el rechazo esperable es un 403**. Listar centros exige
/// administración nacional, así que una sesión de coordinación va a recibir uno
/// cada vez, y eso no es un error que reportar sino una respuesta que la
/// pantalla tiene que saber leer sin ruido.
sealed class CentersOutcome<T> {
  const CentersOutcome();
}

final class CentersRead<T> extends CentersOutcome<T> {
  const CentersRead(this.value);

  final T value;
}

final class CentersRefused<T> extends CentersOutcome<T> {
  const CentersRefused(this.failure);

  final ApiFailure failure;

  /// Si el rechazo es «no te toca» y no un fallo.
  ///
  /// Distinguirlo importa: ante un 403 la interfaz calla —el centro no se
  /// nombra y ya—, mientras que ante un fallo de red tiene algo que decir.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// Lectura de centros.
///
/// **Nada de esto es para administrar un centro desde el teléfono.** Los casos
/// que lo justifican son estrechos y reales: confirmar a qué centro va una
/// transferencia, encontrar un contacto cuando un envío se perdió, y ver que un
/// centro recién aprobado existe. Configurar uno es del panel.
class CentersRepository {
  CentersRepository(this._centers);

  final CentersApi _centers;

  Future<CentersOutcome<List<CenterOut>>> list({bool activeOnly = true}) async {
    try {
      return CentersRead(
        await _centers.listCentersV1CentersGet(activeOnly: activeOnly),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  Future<CentersOutcome<CenterOut>> byId(String id) async {
    try {
      return CentersRead(
        await _centers.getCenterV1CentersCenterIdGet(centerId: id),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Dar de alta un centro.
  ///
  /// El contrato solo exige el nombre, y aquí no se pide más: inventar
  /// obligatorios que el servidor no tiene sería una regla de negocio propia,
  /// que es justo lo que este cliente no lleva.
  Future<CentersOutcome<CenterOut>> create(CenterCreate body) async {
    try {
      return CentersRead(await _centers.createCenterV1CentersPost(body: body));
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Corregir un centro. Todo el cuerpo es opcional: se manda lo que cambió.
  Future<CentersOutcome<CenterOut>> update(String id, CenterUpdate body) async {
    try {
      return CentersRead(
        await _centers.updateCenterV1CentersCenterIdPatch(
          centerId: id,
          body: body,
        ),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
