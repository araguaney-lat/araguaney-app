import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:araguaney_app/core/ui/theme/app_theme.dart';
import 'package:araguaney_app/core/ui/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the palette is written, not derived', () {
    test('the design values survive into the theme', () {
      // `ColorScheme.fromSeed` inventaba cada tono a partir de una semilla, y
      // ninguno de estos aparecía en la aplicación.
      expect(AppTheme.light.colorScheme.primary, AppColors.blue);
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.cream);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkApp);
    });

    test('blue navigates and gold confirms, in both themes', () {
      // La regla del diseño, y la que se rompe sin darse cuenta: un botón de
      // confirmar en azul enseña lo contrario en todas las demás pantallas.
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final palette = theme.extension<AppPalette>()!;
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          theme.colorScheme.primary,
        );
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
      // Un solo archivo por familia: pedir negrita no puede significar cargar
      // otro tipo de letra que no está empaquetado.
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
      // Vivía incrustada en la barra porque no había dónde ponerla; ahora
      // cambia con el tema como todo lo demás.
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
      // Una pastilla no se alinea con el campo ni con la tarjeta que tiene al
      // lado. El radio es el mismo que el de los campos a proposito: un solo
      // valor para todo lo interactivo.
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
      // Es lo que separa una superficie de una accion: si compartieran radio,
      // una tarjeta parecería pulsable.
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
}
