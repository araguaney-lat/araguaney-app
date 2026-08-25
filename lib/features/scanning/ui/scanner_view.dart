import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../boxes/ui/box_detail_view.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../intake/ui/intake_form_view.dart';
import '../data/scan_resolution.dart';
import '../data/scanning_providers.dart';
import '../domain/scan_throttle.dart';
import '../domain/scanned_code.dart';
import 'scan_result_sheet.dart';
import 'scanner_camera.dart';
import 'scanner_viewfinder.dart';

/// La cámara, a pantalla completa.
///
/// Lo leído aparece en una hoja **sobre** la cámara y no en otra pantalla:
/// comprobar una tarima es escanear una caja tras otra, y cada respuesta
/// costaba entrar y salir. Cerrar la hoja deja apuntando otra vez.
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

  /// Mientras una lectura se resuelve, las demás se ignoran: la cámara sigue
  /// entregando cuadros y sin esto se abrirían dos hojas encimadas.
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

    // Al cerrar la hoja, reapuntar a la misma etiqueta tiene que funcionar:
    // quien la cierra suele querer justamente eso.
    _throttle.reset();
    _resolving = false;
  }

  /// La fila de una caja guarda el identificador del tipo de producto y no su
  /// nombre. Se resuelve contra el catálogo local; si ya no está, no se enseña
  /// nada en lugar de enseñar un identificador.
  String? _productNameFor(ScanResolution resolution) {
    if (resolution case CachedBoxFound(:final box)) {
      final catalog = ref.read(productTypesProvider(null)).valueOrNull ?? [];
      for (final product in catalog) {
        if (product.id == box.productTypeId) return product.displayName;
      }
    }
    return null;
  }

  /// La acción principal de la hoja, cuando hay una ficha detrás que hace algo
  /// que la hoja no puede.
  VoidCallback? _openFor(ScanResolution resolution) => switch (resolution) {
    CachedBoxFound(:final box) => () {
      Navigator.of(context)
        ..pop()
        ..push(BoxDetailView.route(boxId: box.id, code: box.code));
    },
    DonationFound(:final donation) => () {
      Navigator.of(context)
        ..pop()
        ..push(IntakeFormView.route(donationId: donation.id));
    },
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Transparente y sobre la imagen: la cámara ocupa la pantalla entera y
        // una barra sólida le robaba una franja sin dar nada a cambio.
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.scanTitle),
        actions: [
          IconButton(
            tooltip: _torchOn ? 'Apagar linterna' : 'Linterna',
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
