import '../i18n/generated/app_localizations.dart';

/// How old a piece of data is, on the scale that matters to whoever operates.
///
/// `intl` is not used on purpose: its relative formats are one more translation
/// table to maintain, and four steps are all that is needed here. What somebody
/// in a centre needs to understand is whether what they see is from a moment
/// ago, from this shift or from another day.
String describeAge(AppLocalizations l10n, DateTime moment, DateTime now) {
  final elapsed = now.difference(moment);

  return switch (elapsed) {
    _ when elapsed.inSeconds < 60 => l10n.relativeJustNow,
    _ when elapsed.inMinutes < 60 => l10n.relativeMinutesAgo(elapsed.inMinutes),
    _ when elapsed.inHours < 24 => l10n.relativeHoursAgo(elapsed.inHours),
    _ => l10n.relativeDaysAgo(elapsed.inDays),
  };
}
