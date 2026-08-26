import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// En qué idioma se ve la aplicación.
///
/// **El del teléfono es el caso por defecto y no una opción más.** Quien
/// captura no eligió este idioma: lo eligió al configurar su teléfono, y la
/// aplicación no tiene por qué preguntárselo otra vez.
///
/// Elegirlo a mano existe para el caso que sí ocurre: un dispositivo compartido
/// de centro, configurado por alguien, que usa gente que lee otra cosa.
abstract interface class LanguagePreference {
  /// El idioma elegido, o nulo para «el del teléfono».
  Future<String?> read();

  /// Nulo vuelve a seguir al teléfono.
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

/// El idioma con el que se dibuja la aplicación.
///
/// Nulo significa «el que diga el sistema», que es lo que `MaterialApp` hace
/// cuando `locale` es nulo. No hay un valor intermedio: o se eligió uno, o
/// manda el teléfono.
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
