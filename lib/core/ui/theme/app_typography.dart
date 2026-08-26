import 'package:flutter/material.dart';

/// The design's two families.
///
/// Serif for the titles and grotesque for everything else. It is not
/// decoration: on a screen full of figures — boxes, units, kilos — the contrast
/// between the two is what separates «qué estoy mirando» from «cuánto hay».
abstract final class AppTypography {
  static const serif = 'SourceSerif4';
  static const sans = 'HankenGrotesk';

  /// Both are variable: weight is asked for by axis, not by loading another
  /// file.
  static List<FontVariation> _weight(int value) => [
    FontVariation('wght', value.toDouble()),
  ];

  static TextTheme textTheme(Color ink, Color muted) {
    TextStyle serifStyle(double size, int weight) => TextStyle(
      fontFamily: serif,
      fontSize: size,
      fontVariations: _weight(weight),
      fontWeight: FontWeight.w600,
      color: ink,
      height: 1.15,
      letterSpacing: -0.3,
    );

    TextStyle sansStyle(double size, int weight, {Color? color}) => TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontVariations: _weight(weight),
      color: color ?? ink,
      height: 1.4,
    );

    return TextTheme(
      displaySmall: serifStyle(34, 600),
      headlineMedium: serifStyle(28, 600),
      headlineSmall: serifStyle(24, 600),
      titleLarge: serifStyle(21, 600),
      titleMedium: sansStyle(16, 600),
      titleSmall: sansStyle(14, 600),
      bodyLarge: sansStyle(16, 400),
      bodyMedium: sansStyle(14.5, 400),
      bodySmall: sansStyle(13, 400, color: muted),
      labelLarge: sansStyle(15, 600),
      labelMedium: sansStyle(13, 600),
      labelSmall: sansStyle(11, 600, color: muted),
    );
  }
}
