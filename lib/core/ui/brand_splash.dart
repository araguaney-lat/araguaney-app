import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

/// Lo primero que dibuja la aplicación, mientras se lee el almacén seguro y se
/// restaura la sesión.
///
/// **Es una copia deliberada del splash del sistema.** Desde Android 12 hay dos
/// dueños de esa pantalla: el sistema operativo dibuja la suya al arrancar el
/// proceso y la aplicación dibuja la siguiente en cuanto Flutter tiene un
/// fotograma. La primera no se puede quitar. Lo único que está en nuestra mano
/// es que la segunda sea indistinguible, y entonces no se perciben dos
/// presentaciones sino una que dura un poco más.
///
/// Por eso no lleva el nombre ni un indicador de progreso: el splash del
/// sistema solo admite un icono sobre un color —cualquier texto queda fuera de
/// su máscara circular— y todo lo que se añada aquí se ve como un cambio a
/// mitad del arranque.
///
/// Los colores están escritos y no salen del tema, por la misma razón: el tema
/// tiene versión clara y oscura y el splash del sistema es el mismo en las dos.
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
