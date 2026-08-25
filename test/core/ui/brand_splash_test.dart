import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/brand_splash.dart';
import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the first frame carries no text, so it cannot differ from the '
      'system splash', (tester) async {
    // Desde Android 12 hay dos dueños de esa pantalla y la del sistema no
    // admite texto. Cualquier cosa añadida aquí se ve como un cambio a mitad
    // del arranque, que es exactamente lo que se quiso evitar.
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BrandSplash(),
      ),
    );

    expect(find.byType(Text), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('its gold is written down, not taken from the theme', (
    tester,
  ) async {
    // El tema tiene versión clara y oscura; el splash del sistema es el mismo
    // en las dos. Seguir al tema haría que en oscuro cambiara de color solo.
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const BrandSplash(),
        ),
      );
      // Acotado al widget: `MaterialApp` monta los suyos, transparentes.
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(BrandSplash),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, AppColors.gold);
    }
  });
}
