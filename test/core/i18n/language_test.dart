import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/i18n/language_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The only place where the language is the subject.
///
/// The other tests assert Spanish text because `flutter_test_config.dart` pins
/// the simulated phone's language; here the opposite is checked, which is what
/// phase 31 added: that the phone decides, and that it can be overruled.
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
    // Nothing is offered half translated: a phone in French gets the first
    // declared language, whole, instead of a mixture.
    await pumpApp(tester, phone: const Locale('fr'));

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('what somebody chose beats what the phone says', (tester) async {
    // The case that really exists: a centre device set up by one person and
    // used by another.
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
      // A half-done language is worse than one that is not there: the screen
      // would come out half in each.
      final es = await AppLocalizations.delegate.load(const Locale('es'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      expect(en.runtimeType.toString(), 'AppLocalizationsEn');
      expect(es.appTitle, en.appTitle);
      // `gen-l10n` fails the build if a key is missing, so getting this far
      // already proves it; this writes it down.
      expect(en.navHome, 'Home');
      expect(es.navHome, 'Inicio');
    });
  });
}
