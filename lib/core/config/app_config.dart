/// The application's build configuration.
///
/// The values arrive through `--dart-define` at build time; values from real
/// environments are never committed to the repository. A fork builds against
/// its own backend without touching code.
library;

/// The build flavours that are supported.
enum AppFlavor {
  /// Local development, or against a test environment.
  dev,

  /// Production.
  prod,

  /// A build without proprietary services (no Firebase; push turned off).
  foss,
}

/// Reads and exposes the configuration injected at build time.
abstract final class AppConfig {
  static const String _flavorRaw = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
  );

  /// The API's base URL (`/v1` is added per route, not here).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// The public website's base URL.
  ///
  /// The QR drawn on the device needs it: its content has to be exactly what
  /// the backend generates (`{base}/b/{code}`), or a label printed from the
  /// phone would lead somewhere different from one printed from the panel. It
  /// is not the same URL as the API's: the QR is scanned by whoever receives
  /// the box, with a browser.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Where error reports go.
  ///
  /// Empty by default and empty in any local build: with no DSN, Sentry is not
  /// initialised and the application works the same. That way a fork does not
  /// send its errors to somebody else's infrastructure, and whoever is
  /// programming does not fill the project's dashboard with traces from their
  /// laptop.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Whether there is anywhere to report to.
  static bool get crashReportingEnabled => sentryDsn.isNotEmpty;

  /// The build's active flavour.
  static AppFlavor get flavor => switch (_flavorRaw) {
    'prod' => AppFlavor.prod,
    'foss' => AppFlavor.foss,
    _ => AppFlavor.dev,
  };

  /// Push capabilities only exist outside the `foss` flavour.
  static bool get pushEnabled => flavor != AppFlavor.foss;
}
