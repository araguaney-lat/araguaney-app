import 'package:shared_preferences/shared_preferences.dart';

/// Cuántas veces se aplazó el aviso de una versión, y hasta cuándo callar.
///
/// **El «Más tarde» tiene que significar más tarde.** Si el aviso volviera cada
/// pocas horas se tocaría por reflejo, y el día que llegue el muro de verdad
/// llegaría como una sorpresa después de semanas descartando lo mismo. Por eso
/// el silencio empieza largo.
///
/// Y tiene que ir apretando, porque una versión de hace tres días y una de hace
/// tres meses no merecen la misma insistencia. No hay fechas de publicación en
/// el contrato, así que la edad se aproxima por cuántas veces se ha aplazado
/// **esta misma** versión: quien la ignora acumula aplazamientos, y el silencio
/// se acorta con ellos.
///
/// El contador se guarda contra la versión concreta, así que una publicación
/// nueva empieza de cero: es otra cosa la que se está pidiendo.
///
/// No es información sensible ni de la sesión: es del dispositivo, igual que
/// [PushPromptMemory], y por eso vive en las preferencias.
abstract interface class UpdatePromptMemory {
  /// Si el aviso de [version] está aplazado en [now].
  Future<bool> isSnoozed(String version, DateTime now);

  /// Aplaza el aviso de [version], contando desde [now].
  Future<void> snooze(String version, DateTime now);
}

/// Cuánto calla cada aplazamiento sucesivo de la misma versión.
///
/// Cinco días la primera vez, dos la segunda, uno de la tercera en adelante.
/// Son valores de esta aplicación y no de ningún control del servidor: aquí no
/// hay nada que ocultar, solo una decisión de producto escrita donde se puede
/// discutir.
const updateSnoozeDays = [5, 2, 1];

int snoozeDaysFor(int previousSnoozes) =>
    updateSnoozeDays[previousSnoozes.clamp(0, updateSnoozeDays.length - 1)];

class PrefsUpdatePromptMemory implements UpdatePromptMemory {
  const PrefsUpdatePromptMemory();

  static const _versionKey = 'update_prompt_version';
  static const _countKey = 'update_prompt_snoozes';
  static const _untilKey = 'update_prompt_until';

  @override
  Future<bool> isSnoozed(String version, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_versionKey) != version) return false;

    final until = DateTime.tryParse(prefs.getString(_untilKey) ?? '');
    return until != null && now.isBefore(until);
  }

  @override
  Future<void> snooze(String version, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    // Otra versión: el contador vuelve a empezar, porque lo que se pide es
    // otra cosa y no una repetición de lo mismo.
    final sameVersion = prefs.getString(_versionKey) == version;
    final previous = sameVersion ? (prefs.getInt(_countKey) ?? 0) : 0;

    await prefs.setString(_versionKey, version);
    await prefs.setInt(_countKey, previous + 1);
    await prefs.setString(
      _untilKey,
      now.add(Duration(days: snoozeDaysFor(previous))).toIso8601String(),
    );
  }
}
