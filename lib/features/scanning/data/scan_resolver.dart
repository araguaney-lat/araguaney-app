import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/api/generated/clients/donations_api.dart';
import '../../../core/api/generated/clients/pallets_api.dart';
import '../../../core/db/app_database.dart';
import '../domain/scanned_code.dart';
import 'scan_resolution.dart';

/// Translates a scanned code into the record it belongs to.
///
/// The contract decides where the question is asked, and not in every case is
/// there an authenticated route: neither boxes nor pallets have an endpoint
/// that turns a code into an identifier. The public records fill that gap.
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

  /// The cache first: a box from this centre resolves with no network and with
  /// the full detail. The public record is the fallback for a label that fell
  /// outside the synced window.
  Future<ScanResolution> _resolveBox(String code) async {
    final cached = await _db.boxesDao.findByCode(code);
    if (cached != null) return CachedBoxFound(cached);

    return _guard(
      () async =>
          PublicBoxFound(await _boxesApi.boxPublicFichaBCodeGet(code: code)),
    );
  }

  /// No failure escapes from here as an exception: the camera is still open and
  /// what belongs is showing the reason, not taking the screen down.
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
