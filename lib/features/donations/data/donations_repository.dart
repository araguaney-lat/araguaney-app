import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/donations_api.dart';
import '../../../core/api/generated/models/donation_item_input.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/api/generated/models/receive_in.dart';

/// Estados en los que el servidor deja una línea de la donación al recibirla.
///
/// Son los tres de `_RECEPTION_STATES`. **Solo se mandan las excepciones**: lo
/// que no viaja marcado el servidor lo da por recibido, y ese reparto es suyo,
/// no una comodidad de esta pantalla.
abstract final class ReceptionResult {
  static const received = 'RECEIVED';
  static const missing = 'MISSING';
  static const rejected = 'REJECTED';
}

/// Estados de una donación, tal como los publica el backend.
abstract final class DonationStatus {
  static const pendingEmail = 'PENDING_EMAIL';
  static const registered = 'REGISTERED';
  static const received = 'RECEIVED';
  static const expired = 'EXPIRED';
  static const cancelled = 'CANCELLED';
}

sealed class DonationsOutcome<T> {
  const DonationsOutcome();
}

final class DonationsRead<T> extends DonationsOutcome<T> {
  const DonationsRead(this.value);

  final T value;
}

final class DonationsRefused<T> extends DonationsOutcome<T> {
  const DonationsRefused(this.failure);

  final ApiFailure failure;
}

/// Donaciones pre-registradas: las que alguien anunció desde la web y trae al
/// centro.
///
/// Leer se cachea en la pantalla que lo pide; **recibir exige señal**. Es una
/// escritura sobre estado compartido, igual que sellar o despachar: dos
/// personas recibiendo la misma donación desde dos teléfonos producirían dos
/// verdades sobre las mismas cajas.
class DonationsRepository {
  DonationsRepository(this._donations);

  final DonationsApi _donations;

  /// [incoming] separa las dos preguntas que alguien se hace en un centro: qué
  /// viene en camino, y qué ya se recibió.
  Future<DonationsOutcome<List<DonationOut>>> list({required bool incoming}) =>
      _guard(() => _donations.listDonationsV1DonationsGet(incoming: incoming));

  /// La ficha por su código impreso, que es lo que llega escaneando.
  Future<DonationsOutcome<DonationOut>> byCode(String code) =>
      _guard(() => _donations.getDonationV1DonationsCodeGet(code: code));

  /// Registra la recepción.
  ///
  /// [results] lleva **solo** las líneas que no llegaron completas; [extras],
  /// lo que vino sin anunciar. [centerId] solo lo pone una administración
  /// nacional, que no tiene centro propio: para todos los demás el servidor
  /// toma el del token e ignora lo que se mande.
  Future<DonationsOutcome<DonationOut>> receive({
    required String code,
    Map<String, String> results = const {},
    List<DonationItemInput> extras = const [],
    String? centerId,
  }) => _guard(
    () => _donations.receiveDonationV1DonationsCodeReceivePost(
      code: code,
      body: ReceiveIn(results: results, extras: extras, centerId: centerId),
    ),
  );

  /// Hasta tres productos del catálogo para un renglón que el donante escribió
  /// a mano.
  ///
  /// El servidor devuelve lista vacía si la capacidad está apagada o no
  /// responde. Eso **no es un fallo**: recibir a mano nunca depende de que esto
  /// conteste, y la pantalla se comporta igual que si no hubiera coincidencias.
  Future<DonationsOutcome<List<ProductTypeOut>>> suggestions({
    required String code,
    required String text,
  }) => _guard(
    () => _donations.suggestCatalogMatchesV1DonationsCodeSuggestionsGet(
      code: code,
      text: text,
    ),
  );

  /// El enlace firmado de una foto. Caduca, así que se pide al mirarla y no se
  /// guarda.
  Future<DonationsOutcome<String>> photoUrl({
    required String code,
    required String photoId,
  }) => _guard(() async {
    final signed = await _donations
        .centerPhotoUrlV1DonationsCodePhotosPhotoIdUrlGet(
          code: code,
          photoId: photoId,
        );
    return signed.url;
  });

  /// Le pide al servidor que lea la etiqueta de una foto.
  ///
  /// Lo que devuelve son **sugerencias**, y el contrato lo dice envolviéndolas
  /// en `suggested`. Un diccionario vacío es la respuesta normal cuando la
  /// capacidad está apagada: se teclea como siempre.
  Future<DonationsOutcome<Map<String, String>>> readLabel({
    required String code,
    required String photoId,
  }) => _guard(() async {
    final response = await _donations
        .readLabelV1DonationsCodePhotosPhotoIdReadLabelPost(
          code: code,
          photoId: photoId,
        );
    final suggested = (response as Map?)?['suggested'];
    if (suggested is! Map) return const <String, String>{};
    return {
      for (final entry in suggested.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  });

  Future<DonationsOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return DonationsRead(await call());
    } on Object catch (error) {
      return DonationsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
