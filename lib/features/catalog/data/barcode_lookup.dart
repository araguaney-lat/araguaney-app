import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/catalog_api.dart';
import '../../../core/api/generated/models/barcode_prefill.dart';
import '../../../core/api/generated/models/barcode_result.dart';
import '../../../core/api/generated/models/barcode_result_source.dart';
import '../../../core/db/app_database.dart';
import '../domain/gtin.dart';
import 'product_type_mapper.dart';

/// En qué termina escanear el código de barras de un envase.
sealed class BarcodeOutcome {
  const BarcodeOutcome();
}

/// El producto está en el catálogo y se puede elegir.
final class BarcodeProductFound extends BarcodeOutcome {
  const BarcodeProductFound(this.product, {required this.fromCache});

  final ProductTypeRow product;

  /// Si salió del catálogo descargado. Sin señal es el único camino posible, y
  /// saberlo permite decir por qué no se encontró en vez de solo que no.
  final bool fromCache;
}

/// La plataforma no tiene este producto; Open Food Facts sí sabe algo de él.
///
/// **No se puede elegir.** Dar de alta un tipo de producto es una decisión del
/// servidor, y un cliente que la tome mete inventario bajo un nombre que la
/// plataforma nunca aceptó. Se enseña lo que se supo y se elige a mano.
final class BarcodeOnlyDescribed extends BarcodeOutcome {
  const BarcodeOnlyDescribed(this.prefill);

  final BarcodePrefill prefill;
}

/// Nadie lo conoce, o no se pudo preguntar.
final class BarcodeUnresolved extends BarcodeOutcome {
  const BarcodeUnresolved(this.failure);

  final ApiFailure failure;
}

/// Busca un producto por el código de barras de su envase.
///
/// El catálogo descargado va primero, y no por rapidez: es lo único que
/// funciona en un sótano, que es donde se captura. La consulta al servidor es
/// para lo que el dispositivo no tiene.
class BarcodeLookup {
  const BarcodeLookup({required CatalogApi api, required AppDatabase database})
    : _catalog = api,
      _db = database;

  final CatalogApi _catalog;
  final AppDatabase _db;

  /// [compressed] lo dice quien leyó: es un UPC-E y hay que expandirlo. Nadie
  /// más puede saberlo, porque un UPC-E y un EAN-8 tienen los mismos ocho
  /// dígitos.
  ///
  /// El dígito de control no se comprueba aquí: forma parte de la simbología
  /// EAN/UPC, así que un código que el decodificador devolvió ya lo pasó, y
  /// repetirlo sería duplicar una regla que no es nuestra.
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
    // La plataforma lo conoce y este dispositivo no lo tiene descargado —
    // catálogo viejo, u otra visibilidad de campaña. El servidor responde por
    // él, así que se puede usar.
    BarcodeResult(:final productType?) => BarcodeProductFound(
      toProductTypeRow(productType),
      fromCache: false,
    ),
    BarcodeResult(source: BarcodeResultSource.openFoodFacts, :final prefill?) =>
      BarcodeOnlyDescribed(prefill),
    _ => const BarcodeUnresolved(
      BusinessRuleFailure(
        code: 'BARCODE_NOT_FOUND',
        message: 'The barcode is not in the catalogue',
      ),
    ),
  };
}
