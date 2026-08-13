import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// La cámara, con su manejo de permiso y su linterna.
///
/// Existe porque hay dos pantallas que escanean y sus diferencias están en qué
/// hacen con lo leído, no en cómo leerlo. Lo que se comparte importa: el texto
/// que se le enseña a alguien cuando el permiso está denegado tiene que ser el
/// mismo en las dos, y duplicarlo garantiza que un día dejen de serlo.
class ScannerCamera extends StatelessWidget {
  const ScannerCamera({
    super.key,
    required this.controller,
    required this.onDetect,
    this.overlay,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;

  /// Lo que se pinta encima de la imagen: una pista, un registro de lecturas.
  final Widget? overlay;

  /// El controlador que las dos pantallas necesitan: solo QR, y sin repetir la
  /// misma lectura mientras el teléfono siga encima de la etiqueta.
  static MobileScannerController buildController() => MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        controller: controller,
        onDetect: onDetect,
        errorBuilder: (context, error) =>
            ScannerError(error: error, onRetry: controller.start),
      ),
      ?overlay,
    ],
  );
}

/// Sin cámara no hay pantalla que valga: en vez de un rectángulo negro, se
/// dice qué falta y se ofrece reintentar.
class ScannerError extends StatelessWidget {
  const ScannerError({super.key, required this.error, required this.onRetry});

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

/// Franja inferior con la instrucción de la pantalla.
class ScannerHint extends StatelessWidget {
  const ScannerHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: double.infinity,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
