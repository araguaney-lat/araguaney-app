import 'package:flutter/material.dart';

/// The button that confirms, in gold.
///
/// «Azul navega, dorado confirma» is a rule of the design, and a rule only
/// teaches anything if it holds on every screen. This widget exists so that no
/// screen writes the colour by hand again: the gold comes from the theme
/// (`ColorScheme.secondary`), so changing it means changing it in one place.
class ConfirmButton extends StatelessWidget {
  const ConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;

  /// Null disables the button, which is what belongs while something is still
  /// missing from the capture.
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
