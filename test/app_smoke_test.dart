import 'package:araguaney_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and renders the home screen in Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AraguaneyApp()));
    await tester.pumpAndSettle();

    // El título y el mensaje llegan de AppLocalizations (es por defecto).
    expect(find.text('Araguaney'), findsOneWidget);
    expect(
      find.text('Cliente móvil de Araguaney en desarrollo.'),
      findsOneWidget,
    );
  });
}
