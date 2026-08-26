import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../boxes/ui/box_detail_view.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../donations/ui/donation_record_view.dart';
import '../data/scan_resolution.dart';
import '../data/scanning_providers.dart';
import '../domain/scan_throttle.dart';
import '../domain/scanned_code.dart';
import 'scan_result_sheet.dart';
import 'scanner_camera.dart';
import 'scanner_viewfinder.dart';

/// The camera, full screen.
///
/// What was read appears in a sheet **over** the camera and not on another
/// screen: checking a pallet means scanning one box after another, and every
/// answer cost entering and leaving. Closing the sheet leaves you pointing
/// again.
class ScannerView extends ConsumerStatefulWidget {
  const ScannerView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ScannerView());

  @override
  ConsumerState<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends ConsumerState<ScannerView> {
  final _controller = ScannerCamera.buildController();
  final _throttle = ScanThrottle();

  /// While one read is being resolved, the rest are ignored: the camera goes on
  /// delivering frames and without this two sheets would open on top of each
  /// other.
  bool _resolving = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving) return;

    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (payload == null || !_throttle.accepts(payload)) return;

    _resolving = true;
    await HapticFeedback.mediumImpact();

    final resolution = await ref
        .read(scanResolverProvider)
        .resolve(parseScannedCode(payload));
    if (!mounted) return;

    await ScanResultSheet.show(
      context,
      resolution: resolution,
      productName: _productNameFor(resolution),
      onOpen: _openFor(resolution),
    );
    if (!mounted) return;

    // On closing the sheet, pointing at the same label again has to work:
    // whoever closes it usually wants exactly that.
    _throttle.reset();
    _resolving = false;
  }

  /// A box's row stores the product type's identifier and not its name. It is
  /// resolved against the local catalogue; if it is no longer there, nothing is
  /// shown rather than an identifier.
  String? _productNameFor(ScanResolution resolution) {
    if (resolution case CachedBoxFound(:final box)) {
      final catalog = ref.read(productTypesProvider(null)).valueOrNull ?? [];
      for (final product in catalog) {
        if (product.id == box.productTypeId) return product.displayName;
      }
    }
    return null;
  }

  /// The sheet's main action, when there is a record behind it that does
  /// something the sheet cannot.
  VoidCallback? _openFor(ScanResolution resolution) => switch (resolution) {
    CachedBoxFound(:final box) => () {
      Navigator.of(context)
        ..pop()
        ..push(BoxDetailView.route(boxId: box.id, code: box.code));
    },
    // It used to end at the capture, skipping the reception: identifying a
    // donation and starting to capture leaves it unrecorded that it arrived.
    DonationFound(:final donation) => () {
      Navigator.of(context)
        ..pop()
        ..push(DonationRecordView.route(donation.code));
    },
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Transparent and over the image: the camera fills the whole screen and
        // a solid bar stole a strip from it giving nothing back.
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.scanTitle),
        actions: [
          IconButton(
            tooltip: _torchOn
                ? context.l10n.scanTorchOff
                : context.l10n.scanTorch,
            icon: Icon(
              _torchOn ? Icons.flashlight_on : Icons.flashlight_on_outlined,
            ),
            onPressed: () async {
              await _controller.toggleTorch();
              if (mounted) setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: ScannerCamera(
        controller: _controller,
        onDetect: _onDetect,
        overlay: ScannerViewfinder(hint: context.l10n.scannerHint),
      ),
    );
  }
}
