import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../data/donations_providers.dart';
import '../data/donations_repository.dart';
import 'donation_record_view.dart';

/// Lo que viene en camino al centro, y lo que ya llegó.
///
/// Son las dos preguntas que se hacen en un centro y en ese orden: primero qué
/// falta por llegar —porque decide si alguien espera en la puerta— y después
/// qué se recibió, que es historia.
class DonationsListView extends ConsumerStatefulWidget {
  const DonationsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const DonationsListView());

  @override
  ConsumerState<DonationsListView> createState() => _DonationsListViewState();
}

class _DonationsListViewState extends ConsumerState<DonationsListView> {
  bool _incoming = true;

  @override
  Widget build(BuildContext context) {
    final donations = ref.watch(
      _incoming ? incomingDonationsProvider : receivedDonationsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.donationsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.donationsIncomingTab),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.donationsReceivedTab),
                ),
              ],
              selected: {_incoming},
              onSelectionChanged: (selection) =>
                  setState(() => _incoming = selection.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref
                ..invalidate(incomingDonationsProvider)
                ..invalidate(receivedDonationsProvider),
              child: switch (donations) {
                AsyncData(value: DonationsRead(:final value))
                    when value.isEmpty =>
                  _Message(
                    _incoming
                        ? context.l10n.donationsIncomingEmpty
                        : context.l10n.donationsReceivedEmpty,
                  ),
                AsyncData(value: DonationsRead(:final value)) => ListView(
                  children: [
                    for (final donation in value) _DonationTile(donation),
                  ],
                ),
                AsyncData(value: DonationsRefused(:final failure)) => _Message(
                  failure.operatorMessage(context.l10n),
                ),
                AsyncError(:final error) => _Message('$error'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationTile extends StatelessWidget {
  const _DonationTile(this.donation);

  final DonationOut donation;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(donation.code),
    subtitle: Text(
      [
        context.l10n.donationLineCount(donation.items.length),
        formatShortDate(donation.createdAt),
      ].join(' · '),
    ),
    trailing: Chip(
      label: Text(donationStatusLabel(context.l10n, donation.status)),
    ),
    onTap: () =>
        Navigator.of(context).push(DonationRecordView.route(donation.code)),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
