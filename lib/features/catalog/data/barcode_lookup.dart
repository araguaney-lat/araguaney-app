import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/catalog_api.dart';
import '../../../core/api/generated/models/barcode_prefill.dart';
import '../../../core/api/generated/models/barcode_result.dart';
import '../../../core/api/generated/models/barcode_result_source.dart';
import '../../../core/db/app_database.dart';
import '../domain/gtin.dart';
import 'product_type_mapper.dart';

/// What scanning a package's barcode ends in.
sealed class BarcodeOutcome {
  const BarcodeOutcome();
}

/// The product is in the catalogue and can be chosen.
final class BarcodeProductFound extends BarcodeOutcome {
  const BarcodeProductFound(this.product, {required this.fromCache});

  final ProductTypeRow product;

  /// Whether it came from the downloaded catalogue. Without signal it is the
  /// only possible route, and knowing that allows saying why it was not found
  /// rather than only that it was not.
  final bool fromCache;
}

/// The platform does not have this product; Open Food Facts does know
/// something about it.
///
/// **It cannot be chosen.** Adding a product type is the server's decision, and
/// a client that takes it puts inventory under a name the platform never
/// accepted. What was learnt is shown and the choice is made by hand.
final class BarcodeOnlyDescribed extends BarcodeOutcome {
  const BarcodeOnlyDescribed(this.prefill);

  final BarcodePrefill prefill;
}

/// Nobody knows it, or it could not be asked about.
final class BarcodeUnresolved extends BarcodeOutcome {
  const BarcodeUnresolved(this.failure);

  final ApiFailure failure;
}

/// Looks a product up by its package's barcode.
///
/// The downloaded catalogue comes first, and not for speed: it is the only
/// thing that works in a basement, which is where capturing happens. The query
/// to the server is for what the device does not have.
class BarcodeLookup {
  /// The code that says «nobody knows it».
  ///
  /// This layer names it because it does not come from the server: it is the
  /// conclusion of having asked both places. The screen looks at it to offer
  /// adding the product, so comparing it against a loose string over there
  /// would leave the same decision written in two places.
  static const notFoundCode = 'BARCODE_NOT_FOUND';

  const BarcodeLookup({required CatalogApi api, required AppDatabase database})
    : _catalog = api,
      _db = database;

  final CatalogApi _catalog;
  final AppDatabase _db;

  /// [compressed] is told by whoever read it: it is a UPC-E and has to be
  /// expanded. Nobody else can know, because a UPC-E and an EAN-8 have the same
  /// eight digits.
  ///
  /// The check digit is not verified here: it is part of the EAN/UPC symbology,
  /// so a code the decoder returned has already passed it, and repeating it
  /// would duplicate a rule that is not ours.
  Future<BarcodeOutcome> byGtin(String raw, {bool compressed = false}) async {
    final gtin = gtinFromScan(raw, compressed: compressed);
    if (gtin == null) {
      return const BarcodeUnresolved(
        BusinessRuleFailure(
          code: 'INVALID_GTIN',
          message: 'The scanned code carries no digits',
        ),
      );
    }

    if (await _db.catalogDao.findByGtin(gtin) case final local?) {
      return BarcodeProductFound(local, fromCache: true);
    }

    try {
      final result = await _catalog.barcodeLookupV1CatalogBarcodeGtinGet(
        gtin: gtin,
      );
      return _fromServer(result);
    } on Object catch (error) {
      return BarcodeUnresolved(ApiErrorMapper.fromAny(error));
    }
  }

  BarcodeOutcome _fromServer(BarcodeResult result) => switch (result) {
    // The platform knows it and this device does not have it downloaded — an
    // old catalogue, or another campaign's visibility. The server answers for
    // it, so it can be used.
    BarcodeResult(:final productType?) => BarcodeProductFound(
      toProductTypeRow(productType),
      fromCache: false,
    ),
    BarcodeResult(source: BarcodeResultSource.openFoodFacts, :final prefill?) =>
      BarcodeOnlyDescribed(prefill),
    _ => const BarcodeUnresolved(
      BusinessRuleFailure(
        code: notFoundCode,
        message: 'The barcode is not in the catalogue',
      ),
    ),
  };
}
