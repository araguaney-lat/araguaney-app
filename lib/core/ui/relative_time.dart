import '../i18n/generated/app_localizations.dart';

/// Antigüedad de un dato, en español y en la escala que le importa a quien
/// opera.
///
/// No se usa `intl` a propósito: sus formatos relativos son otra tabla de
/// traducciones que mantener, y aquí hacen falta cuatro escalones. Lo que
/// necesita entender alguien en un centro es si lo que ve es de hace un
/// momento, de esta jornada o de otro día.
String describeAge(AppLocalizations l10n, DateTime moment, DateTime now) {
  final elapsed = now.difference(moment);

  return switch (elapsed) {
    _ when elapsed.inSeconds < 60 => l10n.relativeJustNow,
    _ when elapsed.inMinutes < 60 =>
      'hace ${_plural(elapsed.inMinutes, 'minuto')}',
    _ when elapsed.inHours < 24 => 'hace ${_plural(elapsed.inHours, 'hora')}',
    _ => 'hace ${_plural(elapsed.inDays, 'día')}',
  };
}

String _plural(int amount, String singular) =>
    amount == 1 ? '1 $singular' : '$amount ${singular}s';
