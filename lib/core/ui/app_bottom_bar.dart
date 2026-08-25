import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Un destino de la barra.
class BottomBarItem {
  const BottomBarItem({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;

  /// Cuántas cosas esperan detrás de este destino. Cero no dibuja nada.
  final int badge;
}

/// La barra inferior con su acción central elevada.
///
/// Cuatro destinos y un botón: el central no es una pestaña, es la acción de la
/// jornada, y por eso está elevado y no lleva etiqueta —el icono carga todo el
/// significado—. Qué acción sea depende del rol y lo decide quien usa esta
/// barra, no la barra.
///
/// Se escribe a mano en vez de usar `NavigationBar` porque el diseño pide un
/// círculo que se sale de la barra con un anillo del color de la barra detrás,
/// y el componente de Material no permite ni ese solape ni la pastilla de 44×26
/// alrededor del icono activo.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    required this.centerIcon,
    required this.centerTooltip,
    required this.onCenterPressed,
  });

  /// Cuatro destinos: dos a la izquierda del botón y dos a la derecha.
  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  final IconData centerIcon;
  final String centerTooltip;
  final VoidCallback onCenterPressed;

  /// Alto del contenido, sin contar el área segura de abajo.
  static const _rowHeight = 60.0;
  static const _centerDiameter = 62.0;

  @override
  Widget build(BuildContext context) {
    assert(
      items.length == 4,
      'The bar carries four destinations and one button',
    );
    final palette = AppPalette.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: palette.bar,
        border: Border(top: BorderSide(color: palette.barBorder)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 12),
      // El círculo se sale por arriba: sin esto queda recortado.
      clipBehavior: Clip.none,
      child: SizedBox(
        height: _rowHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                _Destination(
                  item: items[0],
                  selected: currentIndex == 0,
                  palette: palette,
                  onTap: () => onSelected(0),
                ),
                _Destination(
                  item: items[1],
                  selected: currentIndex == 1,
                  palette: palette,
                  onTap: () => onSelected(1),
                ),
                const Spacer(),
                _Destination(
                  item: items[2],
                  selected: currentIndex == 2,
                  palette: palette,
                  onTap: () => onSelected(2),
                ),
                _Destination(
                  item: items[3],
                  selected: currentIndex == 3,
                  palette: palette,
                  onTap: () => onSelected(3),
                ),
              ],
            ),
            Positioned(
              top: -23,
              left: 0,
              right: 0,
              child: Center(
                child: Tooltip(
                  message: centerTooltip,
                  child: Semantics(
                    button: true,
                    label: centerTooltip,
                    child: InkWell(
                      onTap: onCenterPressed,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: _centerDiameter,
                        height: _centerDiameter,
                        decoration: BoxDecoration(
                          color: palette.centerFill,
                          shape: BoxShape.circle,
                          // El anillo es del color de la barra: es lo que hace
                          // que el círculo se lea encima y no pegado.
                          border: Border.all(color: palette.bar, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: palette.centerFill.withValues(alpha: 0.55),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: Icon(
                          centerIcon,
                          size: 27,
                          color: palette.centerInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? palette.activeInk : palette.inactiveInk;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.activePill : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: _IconWithBadge(
                  icon: item.icon,
                  color: ink,
                  badge: item.badge,
                  ringColor: palette.bar,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.badge,
    required this.ringColor,
  });

  final IconData icon;
  final Color color;
  final int badge;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 19, color: color);
    if (badge <= 0) return glyph;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        glyph,
        Positioned(
          top: -6,
          right: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.of(context).danger,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ringColor, width: 1.5),
            ),
            child: Text(
              // Un número de tres cifras no cabe y tampoco aporta: lo que
              // importa es que hay mucho, no cuánto exactamente.
              badge > 99 ? '99+' : '$badge',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
