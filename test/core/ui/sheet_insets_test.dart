import 'package:araguaney_app/core/ui/sheet_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> measure(
    WidgetTester tester, {
    required double systemBar,
    required double keyboard,
  }) async {
    late double result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          // `padding` es lo que queda del inset del sistema después del
          // teclado: es cero mientras el teclado está abierto, porque el
          // teclado ya cubre la barra.
          padding: EdgeInsets.only(bottom: keyboard > 0 ? 0 : systemBar),
          viewPadding: EdgeInsets.only(bottom: systemBar),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Builder(
          builder: (context) {
            result = sheetBottomInset(context, base: 16);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('with three-button navigation it clears the system bar', (
    tester,
  ) async {
    // Es el caso que un emulador con gestos no enseña: allí la barra mide
    // casi nada y el botón parece bien colocado.
    expect(await measure(tester, systemBar: 48, keyboard: 0), 64);
  });

  testWidgets('with gesture navigation it barely adds anything', (
    tester,
  ) async {
    expect(await measure(tester, systemBar: 16, keyboard: 0), 32);
  });

  testWidgets('with the keyboard open it clears the keyboard, once', (
    tester,
  ) async {
    // No se suman los dos: el teclado se dibuja encima de la barra, así que
    // contar ambos dejaría un hueco del tamaño de la barra bajo el teclado.
    expect(await measure(tester, systemBar: 48, keyboard: 300), 316);
  });
}
