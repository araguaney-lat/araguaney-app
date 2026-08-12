import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La versión instalada la lee el sistema, no una constante que alguien
  // tendría que acordarse de subir. Viaja en el user agent y la usa la
  // comprobación de versión mínima soportada.
  final packageInfo = await PackageInfo.fromPlatform();

  Widget buildApp() => ProviderScope(
    overrides: [appVersionProvider.overrideWithValue(packageInfo.version)],
    child: const AraguaneyApp(),
  );

  // Sin DSN configurado la aplicación arranca igual, sin reportar a ningún
  // sitio. Es el caso de cualquier compilación local y de cualquier fork.
  if (!AppConfig.crashReportingEnabled) {
    runApp(buildApp());
    return;
  }

  await SentryFlutter.init(
    (options) => _configure(options, packageInfo),
    appRunner: () => runApp(buildApp()),
  );
}

void _configure(SentryFlutterOptions options, PackageInfo packageInfo) {
  options
    ..dsn = AppConfig.sentryDsn
    ..environment = AppConfig.flavor.name
    // El release tiene que coincidir con el nombre que llevan los símbolos
    // subidos desde el build de release: una traza de un binario ofuscado sin
    // sus símbolos es una lista de letras.
    ..release =
        '${packageInfo.packageName}@${packageInfo.version}'
        '+${packageInfo.buildNumber}'
    // Los mensajes al operador ya son genéricos por diseño; lo que se manda
    // aquí es el detalle técnico. Nada de cuerpos de petición: llevan datos de
    // donantes.
    ..sendDefaultPii = false
    ..maxRequestBodySize = MaxRequestBodySize.never;
}
