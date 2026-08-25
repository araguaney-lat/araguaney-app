import 'dart:ui';

import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';

/// Los textos, para pruebas que no montan un widget.
///
/// Una tabla de etiquetas ya no es una función pura sobre una cadena: recibe el
/// idioma. Probarla exige cargarlo, y cargarlo es una línea que no conviene
/// repetir en cada archivo.
Future<AppLocalizations> spanish() =>
    AppLocalizations.delegate.load(const Locale('es'));
