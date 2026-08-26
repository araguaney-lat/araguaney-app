import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';
import 'center_form_view.dart';

/// A centre's record.
///
/// **It is not administration.** The three cases that justify it are narrow and
/// resemble one another: confirming which centre a transfer is going to,
/// finding a contact when a shipment goes missing, and seeing that a freshly
/// approved centre exists. All three start far from a desk.
///
/// Configuring a centre belongs to the panel, and that is why there is nothing
/// to write here.
class CenterRecordView extends ConsumerWidget {
  const CenterRecordView({super.key, required this.centerId});

  final String centerId;

  static Route<void> route(String centerId) => MaterialPageRoute<void>(
    builder: (_) => CenterRecordView(centerId: centerId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(centerRecordProvider(centerId));

    final editable = switch (center) {
      AsyncData(value: CentersRead(:final value)) => value,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.centerLabel),
        actions: [
          if (editable != null)
            IconButton(
              onPressed: () => Navigator.of(
                context,
              ).push(CenterFormView.route(existing: editable)),
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.centerEditAction,
            ),
        ],
      ),
      body: switch (center) {
        AsyncData(value: CentersRead(:final value)) => _Body(center: value),
        AsyncData(value: CentersRefused(:final isForbidden, :final failure)) =>
          _Message(
            isForbidden
                ? context.l10n.centerRecordForbidden
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.center});

  final CenterOut center;

  @override
  Widget build(BuildContext context) {
    // The generated model brings these fields nullable even though the
    // contract lists them as required, so what does not arrive is omitted
    // instead of painting a label over nothing. It is the same rule as the
    // other records: the client does not fill in a silence.
    final place = [
      center.stateName,
      center.countryCode,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(center.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        // The legal name only appears when it differs from the working name:
        // repeating it twice informs nobody of anything.
        if (center.legalName case final legal?
            when legal.isNotEmpty && legal != center.name)
          RecordField(label: context.l10n.centerLegalNameLabel, value: legal),
        if (place.isNotEmpty)
          RecordField(label: context.l10n.centerPlaceLabel, value: place),
        if (center.address case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.addressLabel, value: value),
        if (center.contactName case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.contactLabel, value: value),
        if (center.contactEmail case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.emailLabel, value: value),
        if (center.contactPhone case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.phoneLabel, value: value),
        if (!center.isActive)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(context.l10n.centerInactiveNotice),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    child: Text(text, textAlign: TextAlign.center),
  );
}
