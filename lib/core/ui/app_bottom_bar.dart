import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// One destination on the bar.
class BottomBarItem {
  const BottomBarItem({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;

  /// How many things are waiting behind this destination. Zero draws
  /// nothing.
  final int badge;
}

/// The bottom bar with its raised central action.
///
/// Four destinations and a button: the central one is not a tab, it is the
/// action of the shift, and that is why it is raised and carries no label — the
/// icon holds all the meaning. Which action it is depends on the role and is
/// decided by whoever uses this bar, not by the bar.
///
/// It is written by hand instead of using `NavigationBar` because the design
/// asks for a circle that overflows the bar with a ring in the bar's own colour
/// behind it, and the Material component allows neither that overlap nor the
/// 44×26 pill around the active icon.
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

  /// Four destinations: two to the left of the button and two to the right.
  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  final IconData centerIcon;
  final String centerTooltip;
  final VoidCallback onCenterPressed;

  /// The content's height, not counting the safe area below.
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
      // The circle overflows at the top: without this it gets clipped.
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
                          // The ring takes the bar's colour: that is what
                          // makes the circle read as sitting above it rather
                          // than stuck to it.
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
              // A three-digit number does not fit and adds nothing either:
              // what matters is that there are many, not exactly how many.
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
