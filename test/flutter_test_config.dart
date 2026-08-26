import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// El idioma con el que corren todas las pruebas.
///
/// Hasta la fase 31 daba igual: había un solo ARB, así que el sistema resolvía
/// a español pasara lo que pasara y cada prueba podía afirmar el texto en
/// español sin decir por qué. Con el inglés declarado, el teléfono simulado
/// resuelve a inglés y doscientas afirmaciones dejaron de tener sentido a la
/// vez.
///
/// Se fija aquí y no en cada prueba porque **el idioma no es lo que ninguna de
/// ellas comprueba**: comprueban comportamiento, y el texto es cómo lo miran.
/// Que la aplicación siga al teléfono, y que se pueda elegir otro, sí se
/// comprueba — en `test/core/i18n/language_test.dart`, que es el único sitio
/// donde el idioma es el asunto.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  await testMain();
}
