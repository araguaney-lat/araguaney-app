import '../i18n/generated/app_localizations.dart';
import 'refusal_copy.dart';

/// Fallo de una llamada a la API, ya interpretado.
///
/// El backend responde los errores con un sobre estable
/// (`{"error": {"code", "message", "field", "meta"}}`). Esta capa lo traduce a
/// tipos que el resto de la aplicación puede distinguir sin volver a mirar
/// códigos HTTP sueltos.
///
/// Dos distinciones sostienen decisiones reales y por eso son parte del tipo,
/// no del sitio donde se atrapa el error:
///
/// - [isRetryable] separa lo transitorio (sin red, servidor caído) de lo que
///   va a responder igual por siempre (una regla de negocio). La cola de
///   captura sin conexión la necesita para no reintentar para siempre algo que
///   ya fue rechazado.
/// - [operatorMessage] decide qué se le enseña a quien opera. El mensaje del
///   servidor se muestra cuando describe una regla de negocio que esa persona
///   puede entender y corregir; un fallo técnico se muestra genérico y su
///   detalle queda para diagnóstico. Antes que ambos manda la copia propia de
///   los rechazos que el backend nombra con un código: ver [refusalCopyFor].
sealed class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.field,
    this.meta,
  });

  /// Código estable del backend (`VALIDATION_ERROR`, `CODE_ALREADY_USED`, …).
  final String code;

  /// Mensaje del servidor. No siempre es apto para mostrarse: ver
  /// [operatorMessage].
  final String message;

  /// Campo del formulario al que apunta el error, cuando el backend lo indica.
  final String? field;

  /// Datos adicionales del sobre de error.
  final Map<String, dynamic>? meta;

  /// Si reintentar la misma petición puede dar un resultado distinto.
  bool get isRetryable;

  /// Texto que se le muestra a quien opera, en su idioma.
  ///
  /// Recibe [AppLocalizations] en vez de leerlo de un global porque un global
  /// tiene un idioma y esta aplicación va a tener varios.
  String operatorMessage(AppLocalizations l10n);

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// No se pudo hablar con el servidor: sin red, DNS, timeout o conexión cortada.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure({super.code = 'NETWORK_ERROR', required super.message});

  @override
  bool get isRetryable => true;

  @override
  String operatorMessage(AppLocalizations l10n) => l10n.failureNetwork;
}

/// La sesión no es válida o expiró (401).
///
/// El mismo estado cubre dos momentos muy distintos: una sesión que caducó, y
/// unas credenciales que no coinciden en la pantalla donde todavía no hay
/// sesión ninguna. Por eso consulta primero la copia por código: decirle «tu
/// sesión expiró» a quien acaba de escribir mal su contraseña describe algo
/// que no ocurrió.
final class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String operatorMessage(AppLocalizations l10n) =>
      refusalCopyFor(l10n, code) ?? l10n.failureSessionExpired;
}

/// La sesión es válida pero no alcanza para esta operación (403).
///
/// Un 403 puede ser dos cosas distintas y solo el código las separa. Con
/// `FORBIDDEN` —el genérico del backend— significa «esto no te toca», y no hay
/// nada que la persona pueda hacer salvo pedírselo a quien sí puede; el mensaje
/// del servidor ahí describe la comprobación, no el remedio, y a veces está en
/// inglés. Con un código propio —`SELF_REVIEW`, `NOT_CAMPAIGN_MEMBER`— el
/// servidor nombró una regla concreta, y callarla convierte una explicación en
/// un muro.
///
/// Por eso habla cuando hay copia propia para el código y calla cuando no:
/// un código nombrado que esta versión no conozca se muestra genérico, porque
/// el contrato es aditivo y un binario viejo no puede adivinar si lo que
/// llegó es apto para leerse.
final class ForbiddenFailure extends ApiFailure {
  const ForbiddenFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String operatorMessage(AppLocalizations l10n) =>
      refusalCopyFor(l10n, code) ?? l10n.failureForbidden;
}

/// El recurso no existe o no es visible para este centro (404).
final class NotFoundFailure extends ApiFailure {
  const NotFoundFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String operatorMessage(AppLocalizations l10n) => l10n.failureNotFound;
}

/// El servidor rechazó la petición por una regla de negocio o de validación.
///
/// El mensaje del servidor se muestra tal cual: describe algo que quien captura
/// puede entender y corregir, como una caducidad corta o un campo que falta.
/// Traducirlo aquí sería mantener dos versiones de la misma regla, y la del
/// servidor es la que manda.
///
/// La única excepción son los códigos con copia propia, que el backend contesta
/// en inglés: ahí no se traduce una regla, se escribe en el idioma en que se
/// opera. Ver [refusalCopyFor].
final class BusinessRuleFailure extends ApiFailure {
  const BusinessRuleFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String operatorMessage(AppLocalizations l10n) =>
      refusalCopyFor(l10n, code) ?? message;
}

/// Se superó el límite de peticiones (429).
///
/// El bloqueo de una cuenta por intentos fallidos llega con este mismo estado
/// y un código propio, así que consulta la copia por código antes de hablar de
/// peticiones seguidas: son dos cosas distintas y solo el código las separa.
final class RateLimitFailure extends ApiFailure {
  const RateLimitFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => true;

  @override
  String operatorMessage(AppLocalizations l10n) =>
      refusalCopyFor(l10n, code) ?? l10n.failureRateLimited;
}

/// El servidor falló (5xx).
final class ServerFailure extends ApiFailure {
  const ServerFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => true;

  @override
  String operatorMessage(AppLocalizations l10n) => l10n.failureServer;
}

/// Cualquier otra cosa. Existe para que el mapeo sea total y nunca lance algo
/// que nadie haya previsto.
final class UnknownFailure extends ApiFailure {
  const UnknownFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String operatorMessage(AppLocalizations l10n) => l10n.failureUnexpected;
}
