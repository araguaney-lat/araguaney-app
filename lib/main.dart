import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The installed version is read from the system, not from a constant
  // somebody would have to remember to bump. It travels in the user agent and
  // the minimum-supported-version check uses it.
  final packageInfo = await PackageInfo.fromPlatform();

  Widget buildApp() => ProviderScope(
    overrides: [
      appVersionProvider.overrideWithValue(packageInfo.version),
      appBuildNumberProvider.overrideWithValue(packageInfo.buildNumber),
      appPackageNameProvider.overrideWithValue(packageInfo.packageName),
    ],
    child: const AraguaneyApp(),
  );

  // With no DSN configured the application starts all the same, reporting
  // nowhere. That is the case for any local build and for any fork.
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
    // The release has to match the name carried by the symbols uploaded from
    // the release build: a trace from an obfuscated binary without its symbols
    // is a list of letters.
    ..release =
        '${packageInfo.packageName}@${packageInfo.version}'
        '+${packageInfo.buildNumber}'
    // The operator's messages are already generic by design; what is sent here
    // is the technical detail. No request bodies: they carry donors' data.
    ..sendDefaultPii = false
    ..maxRequestBodySize = MaxRequestBodySize.never;
}
