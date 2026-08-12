/// Configuración de compilación de la aplicación.
///
/// Los valores llegan por `--dart-define` en tiempo de build; nunca se
/// versionan valores de entornos reales en el repositorio. Un fork compila
/// apuntando a su propio backend sin tocar código.
library;

/// Sabores de build soportados.
enum AppFlavor {
  /// Desarrollo local o contra un entorno de pruebas.
  dev,

  /// Producción.
  prod,

  /// Compilación sin servicios propietarios (sin Firebase; push desactivado).
  foss,
}

/// Lee y expone la configuración inyectada en tiempo de compilación.
abstract final class AppConfig {
  static const String _flavorRaw = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
  );

  /// URL base de la API (`/v1` se agrega por ruta, no aquí).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// URL base del sitio web público.
  ///
  /// La necesita el QR que se dibuja en el dispositivo: su contenido tiene que
  /// ser exactamente el que genera el backend (`{base}/b/{code}`), o una
  /// etiqueta impresa desde el móvil llevaría a otro sitio que una impresa
  /// desde el panel. No es la misma URL que la de la API: el QR lo escanea
  /// quien recibe la caja, con un navegador.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Destino de los informes de error.
  ///
  /// Vacío por defecto y vacío en cualquier compilación local: sin DSN no se
  /// inicializa Sentry y la aplicación funciona igual. Así un fork no manda sus
  /// errores a la infraestructura de nadie más, y quien programa no ensucia el
  /// panel del proyecto con trazas de su portátil.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Si hay a dónde reportar.
  static bool get crashReportingEnabled => sentryDsn.isNotEmpty;

  /// Sabor activo de la compilación.
  static AppFlavor get flavor => switch (_flavorRaw) {
    'prod' => AppFlavor.prod,
    'foss' => AppFlavor.foss,
    _ => AppFlavor.dev,
  };

  /// Las capacidades de push solo existen fuera del sabor `foss`.
  static bool get pushEnabled => flavor != AppFlavor.foss;
}
