import 'package:flutter/material.dart';

/// Cuánto hay que dejar libre bajo el contenido de una hoja inferior.
///
/// Son **dos** obstáculos y hay que sumarlos, no elegir uno:
///
/// - El teclado, cuando está abierto (`viewInsets`).
/// - La barra de navegación del sistema (`padding`), que en un teléfono con
///   tres botones ocupa una franja alta y con navegación por gestos apenas
///   nada. Un emulador configurado con gestos no enseña este problema: el botón
///   se ve perfectamente ahí y queda medio tapado en el teléfono de al lado.
///
/// Sumar `padding` y no `viewPadding` es lo que evita contarlo dos veces:
/// cuando el teclado está abierto, `padding.bottom` vale cero porque el teclado
/// ya cubre la barra, y lo que queda es la altura del teclado.
///
/// Existe como función y no como una línea copiada en cada hoja porque estaba
/// copiada en seis, todas sumando solo el teclado.
///
/// `showModalBottomSheet(useSafeArea: true)` **no** resuelve esto: protege el
/// borde superior y deja el inferior a cargo de la hoja.
///
/// En una pantalla completa no hace falta: ahí `SafeArea` sí aparta la barra
/// del sistema, y lo único que hay que añadirle es el teclado. Esta función es
/// para las hojas, que es donde `SafeArea` no llega.
double sheetBottomInset(BuildContext context, {double base = 16}) =>
    base +
    MediaQuery.paddingOf(context).bottom +
    MediaQuery.viewInsetsOf(context).bottom;
