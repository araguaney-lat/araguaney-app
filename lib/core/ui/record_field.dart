import 'package:flutter/material.dart';

/// Una línea de una ficha: etiqueta arriba, valor abajo.
///
/// Vive en `core` porque la usan varias fichas de solo lectura y conviene que
/// una caja se vea igual venga del cache o de un escaneo.
class RecordField extends StatelessWidget {
  const RecordField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}

/// Fecha corta en el orden que se lee en la región.
///
/// `intl` formatearía lo mismo a cambio de arrastrar la localización a
/// pantallas de solo lectura que no la necesitan para nada más.
String formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
