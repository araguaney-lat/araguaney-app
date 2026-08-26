import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which language the application is seen in.
///
/// **The phone's is the default case and not one more option.** Whoever
/// captures did not choose this language here: they chose it when setting up
/// their phone, and the application has no reason to ask again.
///
/// Choosing by hand exists for the case that does happen: a centre's shared
/// device, set up by somebody, used by people who read something else.
abstract interface class LanguagePreference {
  /// The chosen language, or null for «el del teléfono».
  Future<String?> read();

  /// Null goes back to following the phone.
  Future<void> write(String? languageCode);
}

class PrefsLanguagePreference implements LanguagePreference {
  const PrefsLanguagePreference();

  static const _key = 'language_code';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, languageCode);
    }
  }
}

class InMemoryLanguagePreference implements LanguagePreference {
  InMemoryLanguagePreference([this._code]);

  String? _code;

  @override
  Future<String?> read() async => _code;

  @override
  Future<void> write(String? languageCode) async => _code = languageCode;
}

final languagePreferenceProvider = Provider<LanguagePreference>(
  (ref) => const PrefsLanguagePreference(),
);

/// The language the application is drawn in.
///
/// Null means «el que diga el sistema», which is what `MaterialApp` does when
/// `locale` is null. There is no value in between: either one was chosen, or
/// the phone decides.
class LanguageController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final code = await ref.watch(languagePreferenceProvider).read();
    return code == null ? null : Locale(code);
  }

  Future<void> choose(String? languageCode) async {
    await ref.read(languagePreferenceProvider).write(languageCode);
    state = AsyncData(languageCode == null ? null : Locale(languageCode));
  }
}

final languageProvider = AsyncNotifierProvider<LanguageController, Locale?>(
  LanguageController.new,
);
