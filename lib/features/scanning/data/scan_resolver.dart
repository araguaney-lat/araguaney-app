import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/api/generated/clients/donations_api.dart';
import '../../../core/api/generated/clients/pallets_api.dart';
import '../../../core/db/app_database.dart';
import '../domain/scanned_code.dart';
import 'scan_resolution.dart';

/// Traduce un código escaneado en la ficha que le corresponde.
///
/// El contrato manda dónde se pregunta, y no en todos los casos hay ruta
/// autenticada: ni cajas ni tarimas tienen un endpoint que traduzca código a
/// identificador. Las fichas públicas cubren ese hueco.
class ScanResolver {
  ScanResolver({
    required BoxesApi boxes,
    required PalletsApi pallets,
    required DonationsApi donations,
    required AppDatabase database,
  }) : _boxesApi = boxes,
       _palletsApi = pallets,
       _donationsApi = donations,
       _db = database;

  final BoxesApi _boxesApi;
  final PalletsApi _palletsApi;
  final DonationsApi _donationsApi;
  final AppDatabase _db;

  Future<ScanResolution> resolve(ScannedCode scanned) async {
    return switch (scanned) {
      BoxCode(:final code) => _resolveBox(code),
      PalletCode(:final code) => _guard(
        () async => PublicPalletFound(
          await _palletsApi.palletPublicFichaPCodeGet(code: code),
        ),
      ),
      DonationCode(:final code) => _guard(
        () async => DonationFound(
          await _donationsApi.getDonationV1DonationsCodeGet(code: code),
        ),
      ),
      UnrecognizedCode(:final raw) => Future.value(ScanNotRecognized(raw)),
    };
  }

  /// El cache primero: una caja de este centro se resuelve sin red y con el
  /// detalle completo. La ficha pública es el respaldo para una etiqueta que
  /// quedó fuera de la ventana sincronizada.
  Future<ScanResolution> _resolveBox(String code) async {
    final cached = await _db.boxesDao.findByCode(code);
    if (cached != null) return CachedBoxFound(cached);

    return _guard(
      () async =>
          PublicBoxFound(await _boxesApi.boxPublicFichaBCodeGet(code: code)),
    );
  }

  /// Ningún fallo escapa de aquí como excepción: la cámara sigue abierta y lo
  /// que corresponde es enseñar el motivo, no tumbar la pantalla.
  Future<ScanResolution> _guard(
    Future<ScanResolution> Function() attempt,
  ) async {
    try {
      return await attempt();
    } on Object catch (error) {
      return ScanResolutionFailed(ApiErrorMapper.fromAny(error));
    }
  }
}
