import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/i18n/language_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// El único sitio donde el idioma es el asunto.
///
/// Las demás pruebas afirman texto en español porque `flutter_test_config.dart`
/// fija el idioma del teléfono simulado; aquí se comprueba lo contrario, que es
/// lo que la fase 31 añadió: que el teléfono manda, y que se le puede llevar la
/// contraria.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required Locale phone,
    LanguagePreference? preference,
  }) async {
    tester.platformDispatcher
      ..localeTestValue = phone
      ..localesTestValue = [phone];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final container = ProviderContainer(
      overrides: [
        languagePreferenceProvider.overrideWithValue(
          preference ?? InMemoryLanguagePreference(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(languageProvider).valueOrNull,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Text(AppLocalizations.of(context)!.navHome),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing chosen, the phone decides', (tester) async {
    await pumpApp(tester, phone: const Locale('en'));

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a phone in Spanish gets Spanish', (tester) async {
    await pumpApp(tester, phone: const Locale('es'));

    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('a language the application does not have falls back', (
    tester,
  ) async {
    // Nada se ofrece a medio traducir: un teléfono en francés recibe el primer
    // idioma declarado, entero, en vez de una mezcla.
    await pumpApp(tester, phone: const Locale('fr'));

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('what somebody chose beats what the phone says', (tester) async {
    // El caso que existe de verdad: un dispositivo de centro que configuró una
    // persona y usa otra.
    await pumpApp(
      tester,
      phone: const Locale('en'),
      preference: InMemoryLanguagePreference('es'),
    );

    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('choosing «the phone» again gives the phone back', (
    tester,
  ) async {
    final preference = InMemoryLanguagePreference('es');
    await pumpApp(tester, phone: const Locale('en'), preference: preference);
    expect(find.text('Inicio'), findsOneWidget);

    await preference.write(null);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, phone: const Locale('en'), preference: preference);

    expect(find.text('Home'), findsOneWidget);
  });

  group('the two files say the same things', () {
    test('every key of the template exists in English', () async {
      // Un idioma a medias es peor que uno que no está: la pantalla saldría
      // mitad en cada uno.
      final es = await AppLocalizations.delegate.load(const Locale('es'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      expect(en.runtimeType.toString(), 'AppLocalizationsEn');
      expect(es.appTitle, en.appTitle);
      // `gen-l10n` falla la compilación si falta una clave, así que llegar
      // hasta aquí ya lo demuestra; esto lo deja escrito.
      expect(en.navHome, 'Home');
      expect(es.navHome, 'Inicio');
    });
  });
}
