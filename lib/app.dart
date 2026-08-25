import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n/generated/app_localizations.dart';
import 'core/routing/session_gate.dart';
import 'core/ui/theme/app_theme.dart';

/// Raíz de la aplicación: tema, localización (español por defecto) y la puerta
/// que decide qué se ve según haya sesión o no.
class AraguaneyApp extends StatelessWidget {
  const AraguaneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      // El diseño trae las dos versiones, así que se ofrecen las dos y decide
      // el sistema. Un centro de acopio trabaja de noche tan a menudo como de
      // día.
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Sin `locale` fijo: `supportedLocales` sale de los ARB, hoy solo
      // español, así que el sistema resuelve a español pase lo que pase.
      // Fijarlo aquí era lo que había que quitar para que añadir un idioma sea
      // un archivo y no una migración — ver la fase 31.
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
