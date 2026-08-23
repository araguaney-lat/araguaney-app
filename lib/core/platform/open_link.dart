import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abrir un enlace fuera de la aplicación.
///
/// Se expone como función para que una prueba pueda comprobar que algo se abre
/// sin lanzar un navegador de verdad. Devuelve si se pudo.
///
/// Vive en `core` y no dentro de una feature porque ya lo usan dos —el
/// manifiesto de un envío y el registro de un centro— y este repositorio
/// lleva seis veces pagando la misma lección: lo que está escondido dentro de
/// una pantalla se acaba duplicando en la siguiente.
typedef OpenLink = Future<bool> Function(String url);

final openLinkProvider = Provider<OpenLink>(
  (ref) => (url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // Fuera de la aplicación a propósito: un PDF firmado se guarda o se
    // imprime desde el visor del sistema, y un formulario público con su
    // verificación antiabuso funciona mejor en el navegador de verdad que
    // dentro de una vista incrustada.
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  },
);
