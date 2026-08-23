import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:araguaney_app/core/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El estado de error de un campo, que durante seis fases no lo declaró nadie.
///
/// `InputDecorator` elige `enabledBorder` cuando el campo está en reposo y
/// `focusedBorder` cuando tiene el foco, y los dos salían del tema. Pero con un
/// error de validación busca `errorBorder` —y `focusedErrorBorder` si además
/// tiene el foco—, que el tema no declaraba; entonces cae al respaldo, que es
/// el `border` que cada pantalla le haya pasado a mano. Cinco pantallas de
/// sesión le pasaban el cuadrado de Material.
///
/// El resultado no se veía en ninguna captura porque solo aparece cuando
/// alguien escribe mal la contraseña, que es precisamente lo rutinario.
void main() {
  /// Devuelve el borde que **se está pintando**, no el que se declaró.
  ///
  /// La diferencia es justo lo que este archivo prueba: `decoration.border` es
  /// solo el respaldo, y leerlo daría por bueno un tema que nunca se dibuja.
  /// El que se pinta vive en el pintor de `_BorderContainer`, que es privado;
  /// se llega por `dynamic` igual que en las pruebas del propio Flutter,
  /// porque los nombres de sus campos no lo son.
  InputBorder paintedBorder(WidgetTester tester) {
    final painter = tester
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.byWidgetPredicate(
                  (w) => '${w.runtimeType}' == '_BorderContainer',
                ),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .foregroundPainter;
    final dynamic borderPainter = painter;
    // ignore: avoid_dynamic_calls
    return borderPainter.border.evaluate(borderPainter.borderAnimation)
        as InputBorder;
  }

  Future<void> pumpField(
    WidgetTester tester, {
    required ThemeData theme,
    required bool withError,
    InputBorder? screenBorder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: TextFormField(
            autovalidateMode: AutovalidateMode.always,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: screenBorder,
            ),
            validator: (_) => withError ? 'Escribe tu contraseña' : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    group(name, () {
      testWidgets('a field in error keeps the design\'s corners', (
        tester,
      ) async {
        await pumpField(tester, theme: theme, withError: true);

        final border = paintedBorder(tester);
        expect(border, isA<OutlineInputBorder>());
        expect(
          (border as OutlineInputBorder).borderRadius,
          BorderRadius.circular(12),
        );
      });

      testWidgets('a field in error is drawn in the danger colour', (
        tester,
      ) async {
        await pumpField(tester, theme: theme, withError: true);

        expect(paintedBorder(tester).borderSide.color, AppColors.danger);
      });

      testWidgets('a border a screen passes cannot undo the error state', (
        tester,
      ) async {
        // Esto es lo que fallaba: cinco pantallas pasaban el cuadrado de
        // Material y, al no haber `errorBorder`, el respaldo era ese.
        await pumpField(
          tester,
          theme: theme,
          withError: true,
          screenBorder: const OutlineInputBorder(),
        );

        final border = paintedBorder(tester) as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(12));
        expect(border.borderSide.color, AppColors.danger);
      });
    });
  }
}
