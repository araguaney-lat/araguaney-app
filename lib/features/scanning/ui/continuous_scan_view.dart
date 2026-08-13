import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../domain/scan_throttle.dart';
import 'scanner_camera.dart';

/// Qué pasó con una lectura.
class ScanFeedback {
  const ScanFeedback.accepted(this.message) : accepted = true;
  const ScanFeedback.rejected(this.message) : accepted = false;

  final bool accepted;
  final String message;
}

/// Escanear una etiqueta detrás de otra sin salir de la cámara.
///
/// Es la forma de trabajar de quien arma una tarima: las cajas están apiladas,
/// las manos ocupadas, y volver a una lista entre caja y caja convierte dos
/// minutos en diez. Cada lectura deja una línea en el registro con lo que dijo
/// el servidor, aceptada o rechazada, para que nadie tenga que recordar por
/// dónde iba.
class ContinuousScanView extends StatefulWidget {
  const ContinuousScanView({
    super.key,
    required this.title,
    required this.hint,
    required this.onScanned,
  });

  final String title;
  final String hint;

  /// Qué hacer con cada lectura. Se llama de una en una: mientras una está en
  /// curso, las siguientes se ignoran.
  final Future<ScanFeedback> Function(String payload) onScanned;

  static Route<void> route({
    required String title,
    required String hint,
    required Future<ScanFeedback> Function(String payload) onScanned,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        ContinuousScanView(title: title, hint: hint, onScanned: onScanned),
  );

  @override
  State<ContinuousScanView> createState() => _ContinuousScanViewState();
}

class _ContinuousScanViewState extends State<ContinuousScanView> {
  final _controller = ScannerCamera.buildController();
  final _throttle = ScanThrottle();
  final _log = <ScanFeedback>[];

  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;

    final payload = capture.barcodes
        .map((Barcode barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (payload == null || !_throttle.accepts(payload)) return;

    _busy = true;
    // La vibración va antes de saber el resultado: confirma que la lectura
    // ocurrió, que es lo que quien apunta necesita saber en ese instante.
    await HapticFeedback.selectionClick();

    final feedback = await widget.onScanned(payload);
    if (!mounted) return;

    setState(() => _log.insert(0, feedback));
    _busy = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Linterna',
          icon: const Icon(Icons.flashlight_on_outlined),
          onPressed: _controller.toggleTorch,
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          flex: 3,
          child: ScannerCamera(
            controller: _controller,
            onDetect: _onDetect,
            overlay: ScannerHint(widget.hint),
          ),
        ),
        Expanded(
          flex: 2,
          child: _log.isEmpty
              ? const _EmptyLog()
              : ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (context, index) => _LogLine(entry: _log[index]),
                ),
        ),
      ],
    ),
  );
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final ScanFeedback entry;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(
      entry.accepted ? Icons.check_circle_outline : Icons.error_outline,
      color: entry.accepted ? null : Theme.of(context).colorScheme.error,
    ),
    title: Text(entry.message),
  );
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Cada caja que leas aparece aquí, con lo que respondió el servidor.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
