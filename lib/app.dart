import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/generated/app_localizations.dart';
import 'core/i18n/language_preference.dart';
import 'core/routing/session_gate.dart';
import 'core/ui/theme/app_theme.dart';

/// The application's root: theme, localisation and the gate that decides what
/// is seen depending on whether there is a session.
class AraguaneyApp extends ConsumerWidget {
  const AraguaneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      // The design brings both versions, so both are offered and the system
      // decides. A collection centre works at night as often as by day.
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Null while none has been chosen, which is the normal case: the phone
      // decides. Choosing by hand exists for the shared centre device, where
      // whoever set it up and whoever uses it are not the same person.
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
