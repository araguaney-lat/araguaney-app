import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../boxes/ui/box_detail_view.dart';
import '../data/scan_resolution.dart';
import '../data/scanning_providers.dart';
import '../domain/scan_throttle.dart';
import '../domain/scanned_code.dart';
import 'scan_result_view.dart';
import 'scanner_camera.dart';

/// Cámara en modo continuo: la etiqueta que se lee abre su ficha, y al volver
/// la cámara sigue abierta para la siguiente caja.
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
  /// entregando cuadros y sin esto se abrirían dos fichas encimadas.
  bool _resolving = false;

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

    await _open(resolution);
    if (!mounted) return;

    // Al volver, reapuntar a la misma etiqueta tiene que funcionar: quien
    // vuelve atrás suele querer justamente eso.
    _throttle.reset();
    _resolving = false;
  }

  /// Una caja cacheada abre la ficha del operador, que trae más que cualquier
  /// cosa que esta pantalla pudiera dibujar.
  Future<void> _open(ScanResolution resolution) => switch (resolution) {
    CachedBoxFound(:final box) => Navigator.of(
      context,
    ).push(BoxDetailView.route(boxId: box.id, code: box.code)),
    _ => Navigator.of(context).push(ScanResultView.route(resolution)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código'),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: ScannerCamera(
        controller: _controller,
        onDetect: _onDetect,
        overlay: const ScannerHint(
          'Apunta al código QR de una caja, una tarima o una donación.',
        ),
      ),
    );
  }
}
