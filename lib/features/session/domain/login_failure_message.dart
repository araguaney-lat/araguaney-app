import '../../../core/api/api_failure.dart';
import '../../../core/i18n/generated/app_localizations.dart';

/// What is said to somebody who could not get in.
///
/// It used to live in `SessionController`, which wrote the sentence and stored
/// it in the state. With more than one language that stops working: the
/// controller has no context, so it would pick one forever. Now the state
/// carries the failure and this writes it where the language being read is
/// known.
///
/// **The request limit is not counted per person.** At the start of a shift the
/// whole centre can exhaust it, and whoever gets the refusal has the right
/// password; telling them «invalid credentials» would send them off to type it
/// again, spend the next attempt and doubt something that was not the problem.
///
/// `ACCOUNT_LOCKED` arrives with that same type and is the opposite: there the
/// block was caused by that account's failed attempts, so saying «it is not
/// your password» would be false. It is let through to its own copy.
String loginFailureMessage(AppLocalizations l10n, ApiFailure failure) {
  if (failure is RateLimitFailure && failure.code != 'ACCOUNT_LOCKED') {
    return l10n.loginRateLimited;
  }
  return failure.operatorMessage(l10n);
}
