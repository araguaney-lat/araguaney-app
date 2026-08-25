import 'package:flutter/material.dart';

import '../../features/shipments/data/shipments_repository.dart';
import '../api/generated/models/qr_event_out.dart';
import '../i18n/l10n_extension.dart';
import 'record_field.dart';

/// El recorrido de un objeto, dibujado igual en los tres sitios que lo tienen.
///
/// Envíos, cajas y tarimas responden el mismo `QrEventOut` y responden la misma
/// pregunta —«¿qué le pasó a esto?»—, así que compartir el dibujo es lo
/// correcto. Lo que **no** se comparte es el vocabulario: cada objeto tiene su
/// tabla de estados y se pasa desde fuera, porque una tarima «CERRADA» y un
/// envío «CERRADO» son cosas distintas y ninguna de las dos es «CLOSED».
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.statusLabel,
    this.empty,
  });

  final List<QrEventOut> events;

  /// La tabla del objeto al que pertenecen estos eventos.
  final String Function(String) statusLabel;

  /// Qué decir cuando no hay nada. Nulo usa el texto general.
  final String? empty;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          empty ?? context.l10n.timelineEmpty,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      children: [
        for (final event in events)
          _EventRow(event: event, statusLabel: statusLabel),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.statusLabel});

  final QrEventOut event;
  final String Function(String) statusLabel;

  @override
  Widget build(BuildContext context) {
    final described = describeEvent(
      context.l10n,
      event,
      statusLabel: statusLabel,
    );

    return ListTile(
      dense: true,
      leading: Icon(
        event.milestone != null ? Icons.flag_outlined : Icons.arrow_forward,
      ),
      title: Text(described.title),
      subtitle: Text(
        [formatShortDate(described.at), ?described.note].join(' · '),
      ),
    );
  }
}
