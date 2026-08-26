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

/// Finding a product by pointing at its package's barcode.
///
/// It is a separate screen from the box scanner, not a version of it with more
/// formats: the box scanner reads QR only on purpose, because a cardboard box
/// also carries the manufacturer's code, and accepting it would mean pointing
/// at our own label could return the laboratory's.
///
/// It returns the chosen product, or null if it was left without finding it.
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

    // A QR is never looked up: on a package it is usually the laboratory's and
    // does not identify the product, and it may also be a label of ours. It is
    // read so we can say what it is, which is better than answering nothing.
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
      // It is not there and somebody is holding it: it is the only moment when
      // what is missing is known. This used to be a notice and the road ended
      // here.
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
    // The camera stays alive behind the sheet: when it closes people point
    // again, and the same code has to be readable once more.
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
    // Pointing at the same code again has to work: whoever has just read a
    // notice usually wants exactly to try again.
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
