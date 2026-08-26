import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// The language every test runs in.
///
/// Until phase 31 it made no difference: there was a single ARB, so the system
/// resolved to Spanish whatever happened and every test could assert Spanish
/// text without saying why. With English declared, the simulated phone resolves
/// to English and two hundred assertions stopped making sense at once.
///
/// It is pinned here and not in each test because **the language is not what
/// any of them checks**: they check behaviour, and the text is how they look at
/// it. That the application follows the phone, and that another can be chosen,
/// is checked — in `test/core/i18n/language_test.dart`, which is the only place
/// where the language is the subject.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('es')
    ..localesTestValue = const [Locale('es')];
  await testMain();
}
