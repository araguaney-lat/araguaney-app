import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/donation_item_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../intake/ui/intake_form_view.dart';
import '../data/donations_providers.dart';
import '../data/donations_repository.dart';
import 'catalog_suggestions.dart';
import 'donation_photo_view.dart';

/// An announced donation's record, and the place where it is received.
///
/// Receiving is a centre's operation and it happens at a door, with a vehicle
/// waiting: it is exactly what nobody wants to do by walking to a computer.
/// That is why it is here and not only in the panel.
///
/// **It requires signal.** It is a write over shared state, like sealing a box:
/// two people receiving the same donation from two phones would leave two
/// truths about the same boxes. The screen says so before anybody tries.
class DonationRecordView extends ConsumerStatefulWidget {
  const DonationRecordView({super.key, required this.code});

  final String code;

  static Route<void> route(String code) =>
      MaterialPageRoute<void>(builder: (_) => DonationRecordView(code: code));

  @override
  ConsumerState<DonationRecordView> createState() => _DonationRecordViewState();
}

class _DonationRecordViewState extends ConsumerState<DonationRecordView> {
  /// Only the exceptions: what is not here, the server takes as received.
  final _exceptions = <String, String>{};
  bool _receiving = false;

  void _toggle(String itemId, String result) => setState(() {
    if (_exceptions[itemId] == result) {
      _exceptions.remove(itemId);
    } else {
      _exceptions[itemId] = result;
    }
  });

  Future<void> _receive(DonationOut donation) async {
    setState(() => _receiving = true);

    final outcome = await ref
        .read(donationsRepositoryProvider)
        .receive(
          code: donation.code,
          results: _exceptions,
          centerId: ref.read(writeCenterIdProvider),
        );
    if (!mounted) return;
    setState(() => _receiving = false);

    switch (outcome) {
      case DonationsRead():
        ref
          ..invalidate(donationRecordProvider(donation.code))
          ..invalidate(incomingDonationsProvider)
          ..invalidate(receivedDonationsProvider);
        // The double check ends where the usual work begins: the capture,
        // already tied to this donation.
        // `donation_id` is the primary key and not the printed code: the
        // server looks it up with `db.get(Donation, ...)`.
        await Navigator.of(
          context,
        ).push(IntakeFormView.route(donationId: donation.id));
      case DonationsRefused(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure.operatorMessage(context.l10n))),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = ref.watch(donationRecordProvider(widget.code));
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(title: Text(widget.code)),
      body: switch (record) {
        AsyncData(value: DonationsRead(:final value)) => _Record(
          donation: value,
          exceptions: _exceptions,
          offline: offline,
          receiving: _receiving,
          onToggle: _toggle,
          onReceive: () => _receive(value),
        ),
        AsyncData(value: DonationsRefused(:final failure)) => _Message(
          failure.operatorMessage(context.l10n),
        ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({
    required this.donation,
    required this.exceptions,
    required this.offline,
    required this.receiving,
    required this.onToggle,
    required this.onReceive,
  });

  final DonationOut donation;
  final Map<String, String> exceptions;
  final bool offline;
  final bool receiving;
  final void Function(String itemId, String result) onToggle;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    final received = donation.status == DonationStatus.received;
    // Receiving makes sense over what really exists already. The server
    // refuses the rest, and saying why beforehand is better than showing a
    // button that answers with an error.
    final receivable = donation.status == DonationStatus.registered;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        RecordField(
          label: context.l10n.statusLabel,
          value: donationStatusLabel(context.l10n, donation.status),
        ),
        RecordField(
          label: context.l10n.registeredOnLabel,
          value: formatShortDate(donation.createdAt),
        ),
        if (donation.notes case final notes? when notes.isNotEmpty)
          RecordField(label: context.l10n.notesLabel, value: notes),
        if (donation.atypicalVolume) const _AtypicalVolume(),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            context.l10n.donationDeclaredTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            context.l10n.donationDeclaredExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final item in donation.items)
          _Item(
            donationCode: donation.code,
            item: item,
            result: exceptions[item.id],
            editable: receivable && !offline,
            onToggle: (result) => onToggle(item.id, result),
          ),
        if (donation.photos.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              context.l10n.donationPhotosTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final photo in donation.photos)
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(formatShortDateTime(photo.createdAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                DonationPhotoView.route(code: donation.code, photoId: photo.id),
              ),
            ),
        ],
        const SizedBox(height: 16),
        if (received) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.donationAlreadyReceived,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          // Received is not captured: what arrived still has to enter the
          // inventory, and whoever scans the code usually comes for exactly
          // that.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(IntakeFormView.route(donationId: donation.id)),
              child: Text(context.l10n.donationCaptureAction),
            ),
          ),
        ] else if (receivable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: offline
                ? Text(
                    context.l10n.donationReceiveNeedsConnection,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : ConfirmButton(
                    label: context.l10n.donationReceiveAction,
                    onPressed: receiving ? null : onReceive,
                  ),
          ),
      ],
    );
  }
}

/// What the donor announced, line by line.
///
/// Marking is the exception and not the norm: what is touched is what did
/// **not** arrive. That way receiving a complete donation — the normal case —
/// is a single button, and what travels to the server is exactly what somebody
/// looked at and decided.
class _Item extends StatelessWidget {
  const _Item({
    required this.donationCode,
    required this.item,
    required this.result,
    required this.editable,
    required this.onToggle,
  });

  final String donationCode;
  final DonationItemOut item;
  final String? result;
  final bool editable;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final title = item.freeText ?? context.l10n.donationItemFromCatalogue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      [
                        '${item.quantity} ${item.unit}',
                        if (item.addedBy == 'center')
                          context.l10n.donationItemAddedByCenter,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!editable)
                if (item.receptionStatus case final status?)
                  Text(
                    receptionResultLabel(context.l10n, status),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            ],
          ),
          // Only for what the donor wrote by hand: if the line already carries
          // a catalogue product there is nothing to suggest.
          if (editable && item.productTypeId == null)
            if (item.freeText case final text? when text.isNotEmpty)
              CatalogSuggestions(code: donationCode, text: text),
          if (editable)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final option in const [
                    ReceptionResult.missing,
                    ReceptionResult.rejected,
                  ])
                    ChoiceChip(
                      label: Text(receptionResultLabel(context.l10n, option)),
                      selected: result == option,
                      selectedColor: palette.alertFill,
                      onSelected: (_) => onToggle(option),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The server marked this donation as an atypical volume.
///
/// It does not say how much or from what point: the threshold is its own, and
/// publishing it here would be telling when a control fires.
class _AtypicalVolume extends StatelessWidget {
  const _AtypicalVolume();

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    color: AppPalette.of(context).noticeFill,
    child: ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(context.l10n.donationAtypicalTitle),
      subtitle: Text(context.l10n.donationAtypicalExplanation),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
