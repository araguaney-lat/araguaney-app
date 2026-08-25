import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/generated/models/barcode_prefill.dart';
import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../scanning/domain/scan_throttle.dart';
import '../../scanning/domain/scanned_code.dart';
import '../../scanning/ui/scanner_camera.dart';
import '../../scanning/ui/scanner_viewfinder.dart';
import '../data/barcode_lookup.dart';
import '../data/catalog_providers.dart';
import '../domain/gtin.dart';
import 'missing_product_sheet.dart';

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
      // No está y alguien lo tiene en la mano: es el único momento en que se
      // sabe qué falta. Antes esto era un aviso y el camino terminaba aquí.
      case BarcodeOnlyDescribed(:final prefill):
        await _offerToAdd(prefill.gtin, prefill: prefill);
      case BarcodeUnresolved(:final failure)
          when failure.code == BarcodeLookup.notFoundCode:
        await _offerToAdd(
          gtinFromScan(
                barcode.rawValue!,
                compressed: barcode.format == BarcodeFormat.upcE,
              ) ??
              barcode.rawValue!,
        );
      case BarcodeUnresolved(:final failure):
        _say(failure.operatorMessage(context.l10n));
    }
  }

  Future<void> _offerToAdd(String gtin, {BarcodePrefill? prefill}) async {
    await MissingProductSheet.show(context, gtin: gtin, prefill: prefill);
    if (!mounted) return;
    // La cámara sigue viva detrás de la hoja: al cerrarla se vuelve a apuntar,
    // y el mismo código tiene que poder leerse otra vez.
    _throttle.reset();
    _resolving = false;
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
