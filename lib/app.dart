import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/generated/app_localizations.dart';
import 'core/i18n/language_preference.dart';
import 'core/routing/session_gate.dart';
import 'core/ui/theme/app_theme.dart';

/// Raíz de la aplicación: tema, localización (español por defecto) y la puerta
/// que decide qué se ve según haya sesión o no.
class AraguaneyApp extends ConsumerWidget {
  const AraguaneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      // El diseño trae las dos versiones, así que se ofrecen las dos y decide
      // el sistema. Un centro de acopio trabaja de noche tan a menudo como de
      // día.
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Nulo mientras no se haya elegido uno, que es lo normal: manda el
      // teléfono. Elegirlo a mano existe para el dispositivo compartido de
      // centro, donde quien lo configuró y quien lo usa no son la misma
      // persona.
      locale: ref.watch(languageProvider).valueOrNull,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SessionGate(),
    );
  }
}
