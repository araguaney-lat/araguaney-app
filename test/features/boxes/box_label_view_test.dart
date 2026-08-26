import 'package:araguaney_app/core/config/app_config.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/boxes/ui/box_label_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('the QR carries the same address the backend prints', () {
    // If the two labels of the same box led to different places, whoever
    // receives it would see one record and whoever dispatched it another.
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

    // What gets encoded is checked by the `payloadFor` tests: the widget keeps
    // that value private, so what is verified here is that the label exists and
    // that the code can be read at a glance.
    expect(find.text('BX-0007'), findsWidgets);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
