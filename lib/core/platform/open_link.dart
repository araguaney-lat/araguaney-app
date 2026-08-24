import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dónde se abre un enlace, que es una decisión de producto y no de estilo.
enum LinkTarget {
  /// Fuera de la aplicación, en la aplicación que el sistema elija.
  ///
  /// Es lo correcto cuando lo que hay al otro lado **no es una página**: un
  /// PDF firmado se abre en el visor del sistema, que es donde se puede
  /// guardar, imprimir o mandar por donde haga falta. Traérselo dentro sería
  /// quitarle a la persona todo eso.
  systemApp,

  /// Dentro de la aplicación, en el navegador del sistema.
  ///
  /// Custom Tabs en Android y `SFSafariViewController` en iOS. **Sigue siendo
  /// el navegador de verdad** —su motor, su proceso, las cookies de quien lo
  /// usa, su gestor de contraseñas y su protección antifraude—, solo que se
  /// dibuja dentro de esta aplicación y el botón atrás devuelve a la pantalla
  /// de la que salió, en vez de dejar la aplicación en segundo plano.
  ///
  /// No confundir con un `WebView`, que es un motor que hospedamos nosotros,
  /// con su propio bote de cookies y sin gestor de contraseñas, y en el que se
  /// puede inyectar y leer JavaScript de la página. Eso nos convertiría en
  /// parte de la frontera de seguridad de esa página, que es justo lo que no
  /// queremos delante de una verificación antiabuso. **Nada que pida una
  /// contraseña puede ir en un `WebView`.**
  inAppBrowser,
}

/// Abrir un enlace.
///
/// Se expone como función para que una prueba pueda comprobar que algo se abre
/// sin lanzar un navegador de verdad. Devuelve si se pudo.
///
/// Vive en `core` y no dentro de una feature porque ya lo usan dos —el
/// manifiesto de un envío y el registro de un centro— y este repositorio
/// lleva seis veces pagando la misma lección: lo que está escondido dentro de
/// una pantalla se acaba duplicando en la siguiente.
///
/// **El destino por defecto es fuera.** Quien quiera el navegador interno
/// tiene que pedirlo, para que traerse una página dentro sea una decisión
/// escrita en la pantalla que la toma y no algo que se hereda sin querer.
typedef OpenLink = Future<bool> Function(String url, {LinkTarget target});

final openLinkProvider = Provider<OpenLink>(
  (ref) => (url, {target = LinkTarget.systemApp}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(
      uri,
      mode: switch (target) {
        LinkTarget.systemApp => LaunchMode.externalApplication,
        LinkTarget.inAppBrowser => LaunchMode.inAppBrowserView,
      },
    );
  },
);
