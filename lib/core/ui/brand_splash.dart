import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

/// The first thing the application draws, while secure storage is read and the
/// session is restored.
///
/// **It is a deliberate copy of the system splash.** Since Android 12 that
/// screen has two owners: the operating system draws its own when the process
/// starts, and the application draws the next one as soon as Flutter has a
/// frame. The first cannot be removed. All that is within our reach is making
/// the second indistinguishable, and then what is perceived is not two
/// presentations but one that lasts a little longer.
///
/// That is why it carries neither the name nor a progress indicator: the system
/// splash only takes an icon over a colour — any text falls outside its
/// circular mask — and everything added here reads as a change halfway through
/// the launch.
///
/// The colours are written out and do not come from the theme, for the same
/// reason: the theme has a light and a dark version and the system splash is
/// the same in both.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.gold,
    child: Center(
      child: Image(
        image: AssetImage('assets/icon/ic_splash.png'),
        width: 240,
        height: 240,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
