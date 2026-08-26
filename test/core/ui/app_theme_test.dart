import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:araguaney_app/core/ui/theme/app_theme.dart';
import 'package:araguaney_app/core/ui/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the palette is written, not derived', () {
    test('the design values survive into the theme', () {
      // `ColorScheme.fromSeed` invented every tone from a seed, and none of
      // these appeared in the application.
      expect(AppTheme.light.colorScheme.primary, AppColors.blue);
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.cream);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkApp);
    });

    test('blue navigates and gold confirms, in both themes', () {
      // The design's rule, and the one that gets broken without noticing: a
      // confirm button in blue teaches the opposite on every other screen.
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final palette = theme.extension<AppPalette>()!;
        // The theme no longer pins the button's background: doing so reached
        // the tonal variant too. What holds the rule up is blue being the
        // scheme's primary, which is where Material takes it from. That a
        // button really paints it is checked by «a tonal button is not a
        // primary one», which reads the drawn colour and not the declared one.
        expect(theme.colorScheme.primary, isNot(theme.colorScheme.secondary));
        expect(
          theme.floatingActionButtonTheme.backgroundColor,
          palette.centerFill,
        );
      }
    });
  });

  group('the two typefaces', () {
    test('titles are serif and everything else is not', () {
      final text = AppTheme.light.textTheme;

      expect(text.headlineSmall!.fontFamily, AppTypography.serif);
      expect(text.titleLarge!.fontFamily, AppTypography.serif);
      expect(text.bodyMedium!.fontFamily, AppTypography.sans);
      expect(
        AppTheme.light.textTheme.labelLarge!.fontFamily,
        AppTypography.sans,
      );
    });

    test('weight travels as an axis, because both faces are variable', () {
      // A single file per family: asking for bold cannot mean loading another
      // typeface that is not packaged.
      final title = AppTheme.light.textTheme.titleLarge!;

      expect(title.fontVariations, isNotEmpty);
      expect(title.fontVariations!.first.axis, 'wght');
    });
  });

  group('dark is a theme, not an accident', () {
    test('both brightnesses exist and differ', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(
        AppTheme.dark.colorScheme.surface,
        isNot(AppTheme.light.colorScheme.surface),
      );
    });

    test('the bar palette comes from the theme in both', () {
      // It used to be embedded in the bar because there was nowhere to put it;
      // now it changes with the theme like everything else.
      expect(AppTheme.light.extension<AppPalette>()!.bar, AppColors.goldSoft);
      expect(
        AppTheme.dark.extension<AppPalette>()!.bar,
        AppColors.darkSurfaceAlt,
      );
    });
  });

  group('cards are separated by a line, not by a shadow', () {
    test('no elevation, a border instead', () {
      final card = AppTheme.light.cardTheme;

      expect(card.elevation, 0);
      expect(
        (card.shape! as RoundedRectangleBorder).side.color,
        AppColors.line,
      );
    });
  });

  group('what is pressed has corners, not a pill', () {
    test('the three button kinds share one radius, in both themes', () {
      // A pill does not line up with the field or with the card next to it. The
      // radius is the same as the fields' on purpose: one value for everything
      // interactive.
      const expected = BorderRadius.all(Radius.circular(12));

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final shapes = <OutlinedBorder?>[
          theme.filledButtonTheme.style?.shape?.resolve({}),
          theme.outlinedButtonTheme.style?.shape?.resolve({}),
          theme.textButtonTheme.style?.shape?.resolve({}),
        ];

        for (final shape in shapes) {
          expect(shape, isA<RoundedRectangleBorder>());
          expect((shape! as RoundedRectangleBorder).borderRadius, expected);
        }
      }
    });

    test('cards stay a little more open than what is pressed', () {
      // It is what separates a surface from an action: if they shared a radius,
      // a card would look tappable.
      final card = AppTheme.light.cardTheme.shape! as RoundedRectangleBorder;
      final button =
          AppTheme.light.filledButtonTheme.style!.shape!.resolve({})!
              as RoundedRectangleBorder;

      expect(
        (card.borderRadius as BorderRadius).topLeft.x,
        greaterThan((button.borderRadius as BorderRadius).topLeft.x),
      );
    });
  });

  group('a tonal button is not a primary one', () {
    testWidgets('the two variants differ, in both themes', (tester) async {
      // Pinning `backgroundColor` in `FilledButtonThemeData` reached both
      // variants, so a button that asked to be tonal was painted identically to
      // a primary one and the hierarchy between them disappeared.
      for (final (name, theme) in [
        ('claro', AppTheme.light),
        ('oscuro', AppTheme.dark),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,

            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text('primario')),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('tonal'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Color? backgroundOf(String label) => tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color;

        expect(
          backgroundOf('primario'),
          theme.colorScheme.primary,
          reason: 'el primario cambio en el tema $name',
        );
        expect(
          backgroundOf('tonal'),
          theme.colorScheme.secondaryContainer,
          reason: 'el tonal no recupero su color en el tema $name',
        );
        expect(backgroundOf('primario'), isNot(backgroundOf('tonal')));
      }
    });
  });
}
