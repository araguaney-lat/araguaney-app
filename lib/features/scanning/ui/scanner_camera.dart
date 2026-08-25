import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/l10n_extension.dart';

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

  /// Cada pantalla declara qué espera leer, y el decodificador no intenta nada
  /// más. No es una validación posterior: un formato que no está en la lista no
  /// produce una lectura equivocada, produce ninguna.
  ///
  /// Por eso el escáner de cajas y tarimas se queda en QR. Un cartón lleva
  /// además el código de barras del fabricante, y aceptarlo haría que apuntar
  /// a nuestra etiqueta pudiera devolver la del laboratorio — un acierto falso,
  /// que es peor que un fallo claro.
  ///
  /// `noDuplicates` evita repetir la misma lectura mientras el teléfono sigue
  /// encima de la etiqueta.
  static MobileScannerController buildController({
    List<BarcodeFormat> formats = const [BarcodeFormat.qrCode],
  }) => MobileScannerController(
    formats: formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Lo que se lee en el envase de un producto.
  ///
  /// Los cuatro lineales cubren los dos sistemas del mundo: EAN-13 y EAN-8
  /// fuera de Norteamérica —México es `750`, Venezuela `759`— y UPC-A y UPC-E
  /// en Estados Unidos y Canadá, de donde viene buena parte de lo que se dona.
  ///
  /// **UPC-E se expande antes de consultarlo** (`gtinFromScan`): su dígito de
  /// control se calculó sobre el UPC-A de doce del que salió, así que enviarlo
  /// comprimido produce un escaneo que parece ir bien y que el servidor
  /// rechaza.
  ///
  /// **DataMatrix no está**: no apareció en ningún envase de la muestra y
  /// aceptarlo sin interpretar los identificadores GS1 mandaría dígitos
  /// equivocados.
  ///
  /// El QR entra en la lista pero no se consulta nunca: está para poder decir
  /// qué se leyó. En un envase el QR suele ser del laboratorio —lleva su logo
  /// dentro— y no identifica el producto; y puede ser también una etiqueta
  /// nuestra. Sin leerlo, apuntar ahí no haría nada, y no hacer nada es la peor
  /// respuesta posible cuando no se sabe si falla la cámara o la puntería.
  static const productFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.qrCode,
  ];

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
            child: Text(context.l10n.actionRetry),
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
