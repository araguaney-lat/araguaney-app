import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/brand_splash.dart';
import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the first frame carries no text, so it cannot differ from the '
      'system splash', (tester) async {
    // Since Android 12 that screen has two owners and the system's takes no
    // text. Anything added here reads as a change halfway through the launch,
    // which is exactly what this set out to avoid.
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
    // The theme has a light and a dark version; the system splash is the same
    // in both. Following the theme would make it change colour by itself in
    // dark.
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
      // Scoped to the widget: `MaterialApp` mounts its own, transparent.
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
