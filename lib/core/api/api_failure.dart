import '../i18n/generated/app_localizations.dart';
import 'refusal_copy.dart';

/// A failed API call, already interpreted.
///
/// The backend answers errors with a stable envelope
/// (`{"error": {"code", "message", "field", "meta"}}`). This layer turns it
/// into types the rest of the application can tell apart without looking at
/// loose HTTP codes again.
///
/// Two distinctions carry real decisions, which is why they belong to the type
/// rather than to wherever the error is caught:
///
/// - [isRetryable] separates the transient (no network, server down) from what
///   will answer the same forever (a business rule). The offline capture queue
///   needs it so it does not retry something that was already refused.
/// - [operatorMessage] decides what somebody operating is shown. The server's
///   message is used when it describes a business rule that person can
///   understand and correct; a technical failure is shown generically and its
///   detail is left for diagnosis. Ahead of both comes our own copy for the
///   refusals the backend names with a code: see [refusalCopyFor].
sealed class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.field,
    this.meta,
  });

  /// Stable backend code (`VALIDATION_ERROR`, `CODE_ALREADY_USED`, …).
  final String code;

  /// The server's message. Not always fit to be shown: see [operatorMessage].
  final String message;

  /// The form field the error points at, when the backend says so.
  final String? field;

  /// Extra data from the error envelope.
  final Map<String, dynamic>? meta;

  /// Whether retrying the same request could give a different answer.
  bool get isRetryable;

  /// The text somebody operating is shown, in their language.
  ///
  /// It takes [AppLocalizations] rather than reading a global, because a global
  /// has one language and this application has more than one.
  String operatorMessage(AppLocalizations l10n);

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// The server could not be reached: no network, DNS, timeout, dropped
/// connection.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure({super.code = 'NETWORK_ERROR', required super.message});

  @override
  bool get isRetryable => true;

  @override
  String operatorMessage(AppLocalizations l10n) => l10n.failureNetwork;
}

/// The session is invalid or expired (401).
///
/// One status covers two very different moments: a session that ran out, and
/// credentials that do not match on the screen where there is no session yet.
/// That is why it asks the copy table first — telling somebody who just
/// mistyped their password that «your session expired» describes something
/// that did not happen.
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

/// The session is valid but does not reach this operation (403).
///
/// A 403 can be two different things and only the code tells them apart. With
/// `FORBIDDEN` — the backend's catch-all — it means «this is not yours to do»,
/// and there is nothing the person can do but ask somebody who can; the
/// server's message there describes the check rather than the remedy, and is
/// sometimes in English. With a code of its own — `SELF_REVIEW`,
/// `NOT_CAMPAIGN_MEMBER` — the server named a specific rule, and staying quiet
/// about it turns an explanation into a wall.
///
/// So it speaks when there is copy for the code and stays quiet when there is
/// not: a named code this build does not know is shown generically, because the
/// contract is additive and an old binary cannot guess whether what arrived is
/// fit to read.
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

/// The resource does not exist, or is not visible to this centre (404).
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

/// The server refused the request over a business or validation rule.
///
/// The server's message is shown as it is: it describes something whoever is
/// capturing can understand and correct, like a short shelf life or a missing
/// field. Translating it here would mean keeping two versions of the same rule,
/// and the server's is the one that decides.
///
/// The only exception is the codes with copy of their own, which the backend
/// answers in English: there we are not translating a rule, we are writing in
/// the language somebody operates in. See [refusalCopyFor].
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

/// The request limit was exceeded (429).
///
/// An account locked out by failed attempts arrives with this same status and a
/// code of its own, so the copy table is asked before saying anything about
/// requests in a row: they are two different things and only the code tells
/// them apart.
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

/// The server failed (5xx).
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

/// Anything else. It exists so the mapping is total and never throws something
/// nobody planned for.
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
