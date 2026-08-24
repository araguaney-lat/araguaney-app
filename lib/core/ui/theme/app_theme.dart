import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Los colores que Material no sabe nombrar.
///
/// `ColorScheme` cubre primario, superficie y error, pero no «el dorado que
/// confirma» ni «la barra inferior». Antes eso vivía incrustado en la barra,
/// que era el único sitio donde había tokens; una extensión los pone donde
/// cualquier pantalla puede leerlos y cambiar de tema sin tocarlos.
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

  /// Superficie de aviso: algo espera, nada va mal. Es el dorado suave de la
  /// barra, con su tinta legible encima.
  final Color noticeFill;
  final Color noticeBorder;
  final Color noticeInk;

  /// Superficie de rechazo: algo se detuvo y espera una decisión. Distinta del
  /// aviso a propósito — «pendiente» y «rechazada» no pueden compartir color.
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

/// La forma de todo lo que se toca.
///
/// El diseño dibuja botones con esquinas y no con forma de pastilla: un
/// rectángulo de esquinas suaves se alinea con los campos y las tarjetas que
/// tiene al lado, y una pastilla no se alinea con nada. El radio es el mismo
/// que el de los campos a propósito —un solo valor para todo lo interactivo—
/// y las tarjetas quedan dos puntos más abiertas, que es lo que las separa
/// visualmente de lo que se pulsa.
const _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

/// El tema de la aplicación, en sus dos versiones.
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
      // Las tarjetas no flotan: el diseño las separa con un borde fino, que en
      // una pantalla llena de filas se lee mejor que ocho sombras compitiendo.
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
      // Azul navega.
      // Sin `backgroundColor` ni `foregroundColor` a propósito. Este tema lo
      // leen los dos: `FilledButton` y `FilledButton.tonal`. Fijarlos aquí
      // ganaba sobre el valor propio de la variante tonal, así que un botón
      // que pedía tonal se pintaba idéntico a uno primario y la jerarquía
      // entre los dos desaparecía. Los valores de Material 3 ya salen del
      // `ColorScheme` escrito arriba: primario toma `primary`, y tonal toma
      // `secondaryContainer`, que es el dorado suave del diseño.
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
      // Un botón de texto no dibuja fondo, pero sí dibuja el destello al
      // pulsarlo. Sin esto ese destello seguiría siendo una pastilla, que es
      // la forma que acabamos de retirar de los otros dos.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          shape: _buttonShape,
        ),
      ),
      // Dorado confirma. Es el color de la acción central de la barra, y por eso
      // ningún botón de navegación debería llevarlo.
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
        // Un campo con error de validación no los declaraba nadie, y eso no
        // se veía: `InputDecorator` busca estos dos, no los encontraba, y caía
        // al `border` de respaldo. El resultado era que «escribe tu
        // contraseña» dejaba el recuadro idéntico al de un campo en reposo, y
        // en las pantallas que pasaban un borde a mano además perdía las
        // esquinas del diseño. Solo aparece cuando alguien escribe mal la
        // contraseña, que es justo lo rutinario.
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
