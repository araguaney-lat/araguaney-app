import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// The colours Material has no name for.
///
/// `ColorScheme` covers primary, surface and error, but not «the gold that
/// confirms» or «the bottom bar». That used to live embedded in the bar, which
/// was the only place with tokens; an extension puts them where any screen can
/// read them and change theme without touching them.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bar,
    required this.barBorder,
    required this.activePill,
    required this.activeInk,
    required this.inactiveInk,
    required this.centerFill,
    required this.centerInk,
    required this.danger,
    required this.noticeFill,
    required this.noticeBorder,
    required this.noticeInk,
    required this.alertFill,
    required this.alertInk,
  });

  static const light = AppPalette(
    bar: AppColors.goldSoft,
    barBorder: AppColors.goldBorder,
    activePill: Color(0xFFF5DA8A),
    activeInk: Color(0xFF3B2A00),
    inactiveInk: Color(0xFF8A6A16),
    centerFill: AppColors.gold,
    centerInk: Color(0xFF3B2A00),
    danger: AppColors.danger,
    noticeFill: AppColors.goldSoft,
    noticeBorder: AppColors.goldBorder,
    noticeInk: Color(0xFF8A5A08),
    alertFill: Color(0xFFFBE0E0),
    alertInk: Color(0xFF8A2020),
  );

  static const dark = AppPalette(
    bar: AppColors.darkSurfaceAlt,
    barBorder: AppColors.darkLine,
    activePill: Color(0x24F3C033),
    activeInk: AppColors.goldDark,
    inactiveInk: AppColors.darkMuted,
    centerFill: AppColors.goldDark,
    centerInk: Color(0xFF3B2A00),
    danger: AppColors.danger,
    noticeFill: Color(0xFF3A2E0A),
    noticeBorder: Color(0xFF4A3B10),
    noticeInk: AppColors.goldDark,
    alertFill: Color(0xFF3A1B1B),
    alertInk: Color(0xFFF0A9A9),
  );

  final Color bar;
  final Color barBorder;
  final Color activePill;
  final Color activeInk;
  final Color inactiveInk;
  final Color centerFill;
  final Color centerInk;
  final Color danger;

  /// The notice surface: something is waiting, nothing is wrong. It is the
  /// bar's soft gold, with readable ink over it.
  final Color noticeFill;
  final Color noticeBorder;
  final Color noticeInk;

  /// The refusal surface: something stopped and is waiting for a decision.
  /// Deliberately different from the notice — «pending» and «refused» cannot
  /// share a colour.
  final Color alertFill;
  final Color alertInk;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? bar,
    Color? barBorder,
    Color? activePill,
    Color? activeInk,
    Color? inactiveInk,
    Color? centerFill,
    Color? centerInk,
    Color? danger,
    Color? noticeFill,
    Color? noticeBorder,
    Color? noticeInk,
    Color? alertFill,
    Color? alertInk,
  }) => AppPalette(
    bar: bar ?? this.bar,
    barBorder: barBorder ?? this.barBorder,
    activePill: activePill ?? this.activePill,
    activeInk: activeInk ?? this.activeInk,
    inactiveInk: inactiveInk ?? this.inactiveInk,
    centerFill: centerFill ?? this.centerFill,
    centerInk: centerInk ?? this.centerInk,
    danger: danger ?? this.danger,
    noticeFill: noticeFill ?? this.noticeFill,
    noticeBorder: noticeBorder ?? this.noticeBorder,
    noticeInk: noticeInk ?? this.noticeInk,
    alertFill: alertFill ?? this.alertFill,
    alertInk: alertInk ?? this.alertInk,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      bar: Color.lerp(bar, other.bar, t)!,
      barBorder: Color.lerp(barBorder, other.barBorder, t)!,
      activePill: Color.lerp(activePill, other.activePill, t)!,
      activeInk: Color.lerp(activeInk, other.activeInk, t)!,
      inactiveInk: Color.lerp(inactiveInk, other.inactiveInk, t)!,
      centerFill: Color.lerp(centerFill, other.centerFill, t)!,
      centerInk: Color.lerp(centerInk, other.centerInk, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      noticeFill: Color.lerp(noticeFill, other.noticeFill, t)!,
      noticeBorder: Color.lerp(noticeBorder, other.noticeBorder, t)!,
      noticeInk: Color.lerp(noticeInk, other.noticeInk, t)!,
      alertFill: Color.lerp(alertFill, other.alertFill, t)!,
      alertInk: Color.lerp(alertInk, other.alertInk, t)!,
    );
  }
}

/// The shape of everything that is touched.
///
/// The design draws buttons with corners rather than as pills: a rectangle with
/// soft corners lines up with the fields and cards beside it, and a pill lines
/// up with nothing. The radius is deliberately the same as the fields' — one
/// value for everything interactive — and cards sit two points more open, which
/// is what separates them visually from what is pressed.
const _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

/// The application's theme, in both of its versions.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blueSoft,
      onPrimaryContainer: AppColors.blue,
      secondary: AppColors.gold,
      onSecondary: Color(0xFF3B2A00),
      secondaryContainer: AppColors.goldSoft,
      onSecondaryContainer: Color(0xFF3B2A00),
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainer: AppColors.surfaceAlt,
      surfaceContainerHighest: AppColors.cream,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      error: AppColors.danger,
    ),
    background: AppColors.cream,
    ink: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    palette: AppPalette.light,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: Color(0xFF7FB2D9),
      onPrimary: Color(0xFF0B2A40),
      primaryContainer: Color(0xFF17364F),
      onPrimaryContainer: Color(0xFFD6E7F5),
      secondary: AppColors.goldDark,
      onSecondary: Color(0xFF3B2A00),
      secondaryContainer: Color(0xFF3A2E0A),
      onSecondaryContainer: AppColors.goldDark,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      surfaceContainerLowest: AppColors.darkApp,
      surfaceContainer: AppColors.darkSurfaceAlt,
      surfaceContainerHighest: AppColors.darkLine,
      onSurfaceVariant: AppColors.darkMuted,
      outline: AppColors.darkLine,
      outlineVariant: AppColors.darkLine,
      error: AppColors.danger,
    ),
    background: AppColors.darkApp,
    ink: AppColors.darkInk,
    muted: AppColors.darkMuted,
    line: AppColors.darkLine,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color ink,
    required Color muted,
    required Color line,
    required AppPalette palette,
  }) {
    final text = AppTypography.textTheme(ink, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.sans,
      textTheme: text,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: ink),
      ),
      // Cards do not float: the design separates them with a thin border,
      // which on a screen full of rows reads better than eight shadows
      // competing.
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Blue navigates.
      // No `backgroundColor` and no `foregroundColor`, on purpose. Both read
      // this theme: `FilledButton` and `FilledButton.tonal`. Pinning them here
      // won over the tonal variant's own value, so a button that asked for
      // tonal was painted identically to a primary one and the hierarchy
      // between the two disappeared. Material 3's values already come from the
      // `ColorScheme` written above: primary takes `primary`, and tonal takes
      // `secondaryContainer`, which is the design's soft gold.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: _buttonShape,
        ),
      ),
      // A text button draws no background, but it does draw the flash when it
      // is pressed. Without this, that flash would still be a pill — the shape
      // we just took off the other two.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          shape: _buttonShape,
        ),
      ),
      // Gold confirms. It is the colour of the bar's central action, which is
      // why no navigation button should ever carry it.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.centerFill,
        foregroundColor: palette.centerInk,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.surfaceAlt
            : AppColors.darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        // Nobody declared these for a field with a validation error, and it
        // did not show: `InputDecorator` looks for these two, did not find
        // them, and fell back to `border`. The result was that «write your
        // password» left the box identical to a field at rest, and on the
        // screens that passed a border by hand it also lost the design's
        // corners. It only appears when somebody mistypes a password, which is
        // exactly the routine case.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: muted),
        hintStyle: text.bodyMedium?.copyWith(color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
