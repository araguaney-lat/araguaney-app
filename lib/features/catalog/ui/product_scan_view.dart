import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../scanning/domain/scan_throttle.dart';
import '../../scanning/domain/scanned_code.dart';
import '../../scanning/ui/scanner_camera.dart';
import '../../scanning/ui/scanner_viewfinder.dart';
import '../data/barcode_lookup.dart';
import '../data/catalog_providers.dart';

/// Encontrar un producto apuntando al código de barras de su envase.
///
/// Es una pantalla aparte del escáner de cajas, no una versión suya con más
/// formatos: el escáner de cajas lee solo QR a propósito, porque un cartón
/// también lleva el código del fabricante y aceptarlo haría que apuntar a
/// nuestra etiqueta pudiera devolver la del laboratorio.
///
/// Devuelve el producto elegido, o nulo si se salió sin encontrarlo.
class ProductScanView extends ConsumerStatefulWidget {
  const ProductScanView({super.key});

  static Future<ProductTypeRow?> push(BuildContext context) =>
      Navigator.of(context).push<ProductTypeRow>(
        MaterialPageRoute(builder: (_) => const ProductScanView()),
      );

  @override
  ConsumerState<ProductScanView> createState() => _ProductScanViewState();
}

class _ProductScanViewState extends ConsumerState<ProductScanView> {
  final _controller = ScannerCamera.buildController(
    formats: ScannerCamera.productFormats,
  );
  final _throttle = ScanThrottle();

  bool _resolving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving) return;

    final barcode = capture.barcodes
        .where((code) => code.rawValue != null)
        .firstOrNull;
    if (barcode == null || !_throttle.accepts(barcode.rawValue!)) return;

    _resolving = true;
    await HapticFeedback.mediumImpact();

    // Un QR no se consulta nunca: en un envase suele ser del laboratorio y no
    // identifica el producto, y puede ser además una etiqueta nuestra. Se lee
    // para poder decir qué es, que es mejor que no responder nada.
    if (barcode.format == BarcodeFormat.qrCode) {
      _explainQr(barcode.rawValue!);
      return;
    }

    final outcome = await ref
        .read(barcodeLookupProvider)
        .byGtin(
          barcode.rawValue!,
          compressed: barcode.format == BarcodeFormat.upcE,
        );
    if (!mounted) return;

    switch (outcome) {
      case BarcodeProductFound(:final product):
        Navigator.of(context).pop(product);
      case BarcodeOnlyDescribed(:final prefill):
        _say(context.l10n.productNotInCatalogue(prefill.displayName));
      case BarcodeUnresolved(:final failure):
        _say(failure.operatorMessage(context.l10n));
    }
  }

  void _explainQr(String raw) => _say(switch (parseScannedCode(raw)) {
    BoxCode() => context.l10n.barcodeIsBoxLabel,
    PalletCode() => context.l10n.barcodeIsPalletLabel,
    DonationCode() => context.l10n.barcodeIsDonationCode,
    UnrecognizedCode() => context.l10n.barcodeIsManufacturerUrl,
  });

  void _say(String message) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    // Volver a apuntar al mismo código tiene que funcionar: quien acaba de
    // leer un aviso suele querer justamente reintentar.
    _throttle.reset();
    _resolving = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(context.l10n.productScanTitle),
    ),
    body: ScannerCamera(
      controller: _controller,
      onDetect: _onDetect,
      overlay: ScannerViewfinder(hint: context.l10n.barcodeAimAtPackage),
    ),
  );
}
