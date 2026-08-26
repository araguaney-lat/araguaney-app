import 'package:flutter/material.dart';

import '../../features/shipments/data/shipments_repository.dart';
import '../api/generated/models/qr_event_out.dart';
import '../i18n/l10n_extension.dart';
import 'record_field.dart';

/// An object's journey, drawn the same way in the three places that have one.
///
/// Shipments, boxes and pallets answer the same `QrEventOut` and answer the
/// same question — «¿qué le pasó a esto?» — so sharing the drawing is right.
/// What is **not** shared is the vocabulary: each object has its own table of
/// states and it is passed in from outside, because a pallet «CERRADA» and a
/// shipment «CERRADO» are different things and neither of them is «CLOSED».
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.statusLabel,
    this.empty,
  });

  final List<QrEventOut> events;

  /// The table of the object these events belong to.
  final String Function(String) statusLabel;

  /// What to say when there is nothing. Null uses the general text.
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
