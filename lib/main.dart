import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La versión instalada la lee el sistema, no una constante que alguien
  // tendría que acordarse de subir. Viaja en el user agent y la usa la
  // comprobación de versión mínima soportada.
  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      overrides: [appVersionProvider.overrideWithValue(packageInfo.version)],
      child: const AraguaneyApp(),
    ),
  );
}
