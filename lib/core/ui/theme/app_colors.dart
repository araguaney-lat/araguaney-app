import 'package:flutter/material.dart';

/// Los colores del diseño, escritos y no calculados.
///
/// Antes el tema salía de `ColorScheme.fromSeed`: una semilla dorada de la que
/// Material derivaba toda la paleta por algoritmo. Es cómodo y da un resultado
/// plano y ajeno — ninguno de estos valores aparecía en la aplicación, y el
/// dorado que se veía no era este.
///
/// Dos reglas del diseño viajan con los colores y valen más que los valores:
/// **azul es navegar** y **dorado es confirmar**. Una pantalla que ponga el
/// botón de confirmar en azul enseña lo contrario en todas las demás.
abstract final class AppColors {
  // Claro
  static const cream = Color(0xFFF4F1EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFBF8F1);
  static const line = Color(0xFFE9E2D4);
  static const ink = Color(0xFF2B2723);
  static const muted = Color(0xFF8A8073);
  static const faint = Color(0xFFAA9F8D);

  // Oscuro
  static const darkApp = Color(0xFF121316);
  static const darkSurface = Color(0xFF1E1F24);
  static const darkSurfaceAlt = Color(0xFF191A1E);
  static const darkLine = Color(0xFF2A2B31);
  static const darkInk = Color(0xFFF1EEE6);
  static const darkMuted = Color(0xFF9A968C);

  /// Navegar.
  static const blue = Color(0xFF1F5E8C);
  static const blueSoft = Color(0xFFE9F1F8);

  /// Confirmar.
  static const gold = Color(0xFFD69A00);
  static const goldSoft = Color(0xFFFBEFC9);
  static const goldBorder = Color(0xFFEAD9B0);
  static const goldDark = Color(0xFFF3C033);

  static const danger = Color(0xFFE05252);
}
