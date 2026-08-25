import '../../../core/api/api_failure.dart';
import '../../../core/i18n/generated/app_localizations.dart';

/// Qué se le dice a quien no pudo entrar.
///
/// Vivía en `SessionController`, que redactaba la frase y la guardaba en el
/// estado. Con más de un idioma eso deja de funcionar: el controlador no tiene
/// contexto, así que elegiría uno para siempre. Ahora el estado lleva el fallo
/// y esto lo redacta donde sí se sabe en qué idioma se está mirando.
///
/// **El límite de peticiones no se cuenta por persona.** En el arranque de un
/// turno lo puede agotar el centro entero, y quien reciba el rechazo tiene la
/// contraseña correcta; decirle «credenciales inválidas» lo mandaría a teclear
/// de nuevo, a gastar el siguiente intento y a dudar de algo que no era el
/// problema.
///
/// `ACCOUNT_LOCKED` llega con ese mismo tipo y es lo contrario: ahí el bloqueo
/// lo causaron los intentos fallidos de esa cuenta, así que decir «no es tu
/// contraseña» sería falso. Se deja pasar a su copia propia.
String loginFailureMessage(AppLocalizations l10n, ApiFailure failure) {
  if (failure is RateLimitFailure && failure.code != 'ACCOUNT_LOCKED') {
    return l10n.loginRateLimited;
  }
  return failure.operatorMessage(l10n);
}
