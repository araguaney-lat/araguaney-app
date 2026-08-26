import '../i18n/generated/app_localizations.dart';

/// Copy of our own for refusals the backend names with a code.
///
/// It exists for two different reasons that lead to the same place:
///
/// 1. **A named refusal describes a rule the person can act on.** The backend
///    uses `FORBIDDEN` as the generic code for «no te toca», and codes of its
///    own — `SELF_REVIEW`, `NOT_CAMPAIGN_MEMBER` — when the reason is a
///    specific rule. The code is the signal: if the server took the trouble to
///    name it, there is something to do with that information.
/// 2. **Several of those messages are in English** and whoever operates reads
///    Spanish.
///
/// It is presentation copy for named codes, not a second copy of the rule:
/// nothing is decided here, it is only said. A code that is not in this table
/// is not invented — see `ApiFailure.operatorMessage` for what is shown then —
/// and the table should not grow much: if it does, the right answer is for the
/// messages to arrive from the backend already translated, which is request 6
/// of `docs/backend-requests.md`.
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
  // Only a national administrator can be refused this, and only if a screen
  // forgot to name the working centre. It says what to do rather than what
  // happened: the server's own words are about a field nobody filled in.
  'CENTER_REQUIRED' => l10n.refusalCenterRequired,
  _ => null,
};
