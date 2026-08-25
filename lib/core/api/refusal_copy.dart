import '../i18n/generated/app_localizations.dart';

/// Copia propia para rechazos que el backend nombra con un código.
///
/// Existe por dos motivos distintos que dan el mismo resultado:
///
/// 1. **Un rechazo con nombre describe una regla que la persona puede
///    resolver.** El backend usa `FORBIDDEN` como código genérico para «no te
///    toca», y códigos propios —`SELF_REVIEW`, `NOT_CAMPAIGN_MEMBER`— cuando el
///    motivo es una regla concreta. El código es la señal: si el servidor se
///    tomó el trabajo de nombrarla, hay algo que hacer con esa información.
/// 2. **Varios de esos mensajes están en inglés** y quien opera lee en español.
///
/// Es copia de presentación para códigos nombrados, no una segunda copia de la
/// regla: aquí no se decide nada, solo se dice. Un código que no esté en esta
/// tabla no se inventa —ver `ApiFailure.operatorMessage` para qué se muestra
/// entonces— y la tabla no debería crecer mucho: si lo hace, lo correcto es que
/// los mensajes vengan del backend en español, que es la petición 6 de
/// `docs/backend-requests.md`.
String? refusalCopyFor(AppLocalizations l10n, String code) => switch (code) {
  'SELF_REVIEW' => l10n.refusalSelfReview,
  'NOT_CAMPAIGN_MEMBER' => l10n.refusalNotCampaignMember,
  'ACCOUNT_DISABLED' => l10n.refusalAccountDisabled,
  'EMAIL_NOT_VERIFIED' => l10n.refusalEmailNotVerified,
  'INVALID_CREDENTIALS' => l10n.refusalInvalidCredentials,
  'ACCOUNT_LOCKED' => l10n.refusalAccountLocked,
  'EMAIL_TAKEN' => l10n.refusalEmailTaken,
  'USERNAME_TAKEN' => l10n.refusalUsernameTaken,
  'INVALID_ROLE' => l10n.refusalInvalidRole,
  'PROTECTED_CAMPAIGN' => l10n.refusalProtectedCampaign,
  _ => null,
};
