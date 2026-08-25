import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n_extension.dart';

/// La etiqueta de una caja, dibujada en el dispositivo.
///
/// El QR se genera aquí y no se pide al servidor por una razón operativa: una
/// caja se etiqueta en el momento en que se sella, y ese momento puede ocurrir
/// sin señal. El PDF por lotes sigue siendo del servidor, que es donde tiene
/// sentido.
///
/// El contenido replica exactamente el que genera el backend: si las dos
/// etiquetas de la misma caja llevaran a sitios distintos, quien la recibe
/// vería una ficha y quien la despachó otra.
class BoxLabelView extends StatelessWidget {
  const BoxLabelView({super.key, required this.code});

  final String code;

  static Route<void> route(String code) =>
      MaterialPageRoute<void>(builder: (_) => BoxLabelView(code: code));

  /// Lo que se codifica en el QR. Público expuesto para que una prueba pueda
  /// comprobarlo sin renderizar.
  static String payloadFor(String code) =>
      '${AppConfig.webBaseUrl.replaceAll(RegExp(r'/+$'), '')}/b/$code';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(code)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fondo blanco explícito: en tema oscuro un QR sin fondo se vuelve
            // ilegible para la cámara que lo lea.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: payloadFor(code),
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(code, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              context.l10n.boxesPegaLaEtiquetaEnLa,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
