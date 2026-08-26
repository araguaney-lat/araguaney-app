import 'package:flutter/material.dart';

/// The design's colours, written out rather than computed.
///
/// The theme used to come from `ColorScheme.fromSeed`: a gold seed from which
/// Material derived the whole palette by algorithm. It is convenient and gives
/// a flat, foreign result — none of these values appeared in the application,
/// and the gold that was seen was not this one.
///
/// Two rules of the design travel with the colours and are worth more than the
/// values: **blue is navigating** and **gold is confirming**. A screen that
/// puts the confirm button in blue teaches the opposite on every other one.
abstract final class AppColors {
  // Light
  static const cream = Color(0xFFF4F1EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFBF8F1);
  static const line = Color(0xFFE9E2D4);
  static const ink = Color(0xFF2B2723);
  static const muted = Color(0xFF8A8073);
  static const faint = Color(0xFFAA9F8D);

  // Dark
  static const darkApp = Color(0xFF121316);
  static const darkSurface = Color(0xFF1E1F24);
  static const darkSurfaceAlt = Color(0xFF191A1E);
  static const darkLine = Color(0xFF2A2B31);
  static const darkInk = Color(0xFFF1EEE6);
  static const darkMuted = Color(0xFF9A968C);

  /// Navigating.
  static const blue = Color(0xFF1F5E8C);
  static const blueSoft = Color(0xFFE9F1F8);

  /// Confirming.
  static const gold = Color(0xFFD69A00);
  static const goldSoft = Color(0xFFFBEFC9);
  static const goldBorder = Color(0xFFEAD9B0);
  static const goldDark = Color(0xFFF3C033);

  static const danger = Color(0xFFE05252);
}
