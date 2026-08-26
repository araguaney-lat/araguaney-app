import 'dart:ui';

import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';

/// The texts, for tests that do not mount a widget.
///
/// A table of labels is no longer a pure function over a string: it takes the
/// language. Testing it means loading it, and loading it is a line not worth
/// repeating in every file.
Future<AppLocalizations> spanish() =>
    AppLocalizations.delegate.load(const Locale('es'));
