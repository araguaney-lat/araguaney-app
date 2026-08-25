import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// Los textos, desde cualquier sitio que tenga un contexto.
///
/// `AppLocalizations.of(context)!` en cada llamada es correcto y se lee mal,
/// sobre todo dentro de funciones flecha, donde declarar una variable obliga a
/// convertir el cuerpo. Con esto una etiqueta se pide igual esté donde esté:
/// `context.l10n.boxStatusSealed`.
///
/// El `!` es seguro porque el delegado está declarado en `MaterialApp` y no hay
/// ningún widget de esta aplicación fuera de él. Si algún día lo hubiera, es
/// mejor que reviente donde se escribió que enseñar una cadena vacía.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
