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
  // Solo QR: restringir los formatos le ahorra trabajo al decodificador y
  // evita que un código de barras de producto se cuele como si fuera una
  // etiqueta de la plataforma.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) =>
                _ScannerError(error: error, onRetry: _controller.start),
          ),
          const _ScanHint(),
        ],
      ),
    );
  }
}

class _ScanHint extends StatelessWidget {
  const _ScanHint();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: double.infinity,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: const Text(
        'Apunta al código QR de una caja, una tarima o una donación.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}

/// Sin cámara no hay pantalla que valga: en vez de un rectángulo negro, se
/// dice qué falta y se ofrece reintentar.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onRetry(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );

  String get _message => switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      'Araguaney necesita la cámara para leer los códigos QR de las cajas. '
          'Concede el permiso desde los ajustes del sistema y vuelve a '
          'intentarlo.',
    MobileScannerErrorCode.unsupported =>
      'Este dispositivo no puede escanear códigos.',
    _ => 'No se pudo abrir la cámara. Inténtalo de nuevo.',
  };
}
