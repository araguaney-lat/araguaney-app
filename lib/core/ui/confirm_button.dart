import 'package:flutter/material.dart';

/// El botón que confirma, en dorado.
///
/// «Azul navega, dorado confirma» es una regla del diseño, y una regla solo
/// enseña algo si se cumple en todas las pantallas. Existe este widget para que
/// ninguna vuelva a escribir el color a mano: el dorado sale del tema
/// (`ColorScheme.secondary`), así que cambiarlo es cambiarlo en un sitio.
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;

  /// Nulo deshabilita el botón, que es lo que corresponde mientras falte algo
  /// por capturar.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      child: Text(label),
    );
  }
}
