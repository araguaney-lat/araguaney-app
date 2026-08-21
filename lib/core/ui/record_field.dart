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

/// La misma fecha con la hora, para lo que ocurrió en una jornada concreta.
///
/// Una captura encolada esta mañana y otra de anteayer se distinguen por el
/// día; dos de la misma mañana, solo por la hora.
String formatShortDateTime(DateTime at) =>
    '${formatShortDate(at)} ${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';
