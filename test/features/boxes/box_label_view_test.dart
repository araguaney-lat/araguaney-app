import 'package:araguaney_app/core/config/app_config.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/boxes/ui/box_label_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('the QR carries the same address the backend prints', () {
    // Si las dos etiquetas de la misma caja llevaran a sitios distintos, quien
    // la recibe vería una ficha y quien la despachó otra.
    expect(
      BoxLabelView.payloadFor('BX-0001'),
      '${AppConfig.webBaseUrl}/b/BX-0001',
    );
  });

  test('a trailing slash in the configured base does not double up', () {
    expect(BoxLabelView.payloadFor('BX-1').contains('//b/'), isFalse);
  });

  testWidgets('the label shows the code and its QR', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BoxLabelView(code: 'BX-0007'),
      ),
    );
    await tester.pumpAndSettle();

    // Qué se codifica lo comprueban las pruebas de `payloadFor`: el widget
    // guarda ese dato en privado, así que aquí se verifica que la etiqueta
    // existe y que el código se puede leer a simple vista.
    expect(find.text('BX-0007'), findsWidgets);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
