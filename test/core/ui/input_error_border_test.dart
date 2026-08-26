import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/theme/app_colors.dart';
import 'package:araguaney_app/core/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A field's error state, which for six phases nobody declared.
///
/// `InputDecorator` picks `enabledBorder` when the field is at rest and
/// `focusedBorder` when it has focus, and both came from the theme. But with a
/// validation error it looks for `errorBorder` — and `focusedErrorBorder` if it
/// also has focus — which the theme did not declare; then it falls back, and
/// the fallback is whatever `border` each screen passed by hand. Five session
/// screens were passing Material's square.
///
/// The result showed in no screenshot because it only appears when somebody
/// types their password wrong, which is precisely the routine case.
void main() {
  /// Returns the border that **is being painted**, not the one that was
  /// declared.
  ///
  /// That difference is exactly what this file tests: `decoration.border` is
  /// only the fallback, and reading it would pass a theme that is never drawn.
  /// The one that gets painted lives in `_BorderContainer`'s painter, which is
  /// private; it is reached through `dynamic` as in Flutter's own tests,
  /// because its field names are not.
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,

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
        // This is what was failing: five screens passed Material's square and,
        // with no `errorBorder`, that was the fallback.
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
