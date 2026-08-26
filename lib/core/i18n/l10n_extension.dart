import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// The texts, from anywhere that has a context.
///
/// `AppLocalizations.of(context)!` at every call site is correct and reads
/// badly, especially inside arrow functions, where declaring a variable forces
/// the body to be converted. With this, a label is asked for the same way
/// wherever it is: `context.l10n.boxStatusSealed`.
///
/// The `!` is safe because the delegate is declared in `MaterialApp` and no
/// widget of this application lives outside it. If one ever did, it is better
/// that it blows up where it was written than that it shows an empty string.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
