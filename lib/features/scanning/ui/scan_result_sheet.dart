import 'package:flutter/material.dart';

import '../../../core/api/generated/models/box_public_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/pallet_public_out.dart';
import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../../core/ui/status_labels.dart';
import '../data/scan_resolution.dart';

/// What was read, over the camera.
///
/// It used to be a separate screen and is now a sheet: whoever checks a pallet
/// scans one box after another, and every answer cost entering and leaving a
/// screen. Closing the sheet leaves you pointing again.
///
/// The sheet identifies; it does not replace the record. When there is a record
/// with actions behind it — a cached box's operator record, an announced
/// donation's capture — the sheet leads to it with a button.
class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.resolution,
    this.onOpen,
    this.productName,
  });

  final ScanResolution resolution;

  /// The product name of a cached box. The box's row only stores the type's
  /// identifier, so it is resolved by whoever opens the sheet against the local
  /// catalogue; it is null when the catalogue no longer has it, and then
  /// nothing is shown instead of an identifier.
  final String? productName;

  /// What to do with the main action, when there is one. Whoever opens the
  /// sheet decides it because it is navigation, and the sheet does not know
  /// where it was called from.
  final VoidCallback? onOpen;

  static Future<void> show(
    BuildContext context, {
    required ScanResolution resolution,
    VoidCallback? onOpen,
    String? productName,
  }) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ScanResultSheet(
      resolution: resolution,
      onOpen: onOpen,
      productName: productName,
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, sheetBottomInset(context)),
    child: switch (resolution) {
      CachedBoxFound(:final box) => _CachedBox(
        box: box,
        productName: productName,
        onOpen: onOpen,
      ),
      PublicBoxFound(:final box) => _PublicBox(box: box),
      PublicPalletFound(:final pallet) => _Pallet(pallet: pallet),
      DonationFound(:final donation) => _Donation(
        donation: donation,
        onOpen: onOpen,
      ),
      ScanNotRecognized(:final raw) => _Message(
        icon: Icons.help_outline,
        title: context.l10n.scanUnknownCode,
        text: context.l10n.scanRawContent(raw),
      ),
      ScanResolutionFailed(:final failure) => _Message(
        icon: Icons.error_outline,
        title: context.l10n.scanLookupFailed,
        text: failure.operatorMessage(context.l10n),
      ),
    },
  );
}

/// The common header: the code as it is printed on the label, and its state.
class _Headline extends StatelessWidget {
  const _Headline({required this.code, this.status});

  final String code;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            code,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (status case final status?) Chip(label: Text(status)),
      ],
    );
  }
}

class _CachedBox extends StatelessWidget {
  const _CachedBox({
    required this.box,
    required this.productName,
    required this.onOpen,
  });

  final BoxRow box;
  final String? productName;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: box.code,
          status: boxStatusLabel(context.l10n, box.status),
        ),
        const SizedBox(height: 8),
        if (productName case final name?)
          Text(name, style: theme.textTheme.titleMedium),
        Text(
          [
            '${box.quantity} ${box.unit}',
            if (box.batch case final batch?) context.l10n.batchOf(batch),
            if (box.expiryDate case final expiry?)
              context.l10n.expiresOn(formatShortDate(expiry)),
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: context.l10n.scanOpenRecord,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}

/// The public record brings less than the operator's, and whoever reads it has
/// to know: the difference between «this is all there is» and «this is what
/// could be looked up» changes what somebody decides with it in front of them.
class _PublicBox extends StatelessWidget {
  const _PublicBox({required this.box});

  final BoxPublicOut box;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: box.code,
          status: boxStatusLabel(context.l10n, box.status),
        ),
        const SizedBox(height: 8),
        Text(box.displayName, style: theme.textTheme.titleMedium),
        Text(
          [
            '${box.quantity} ${box.unit}',
            categoryLabel(context.l10n, box.category),
            if (box.expiryDate case final expiry?)
              context.l10n.expiresOn(formatShortDate(expiry)),
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _Notice(context.l10n.scanBoxNotCached),
      ],
    );
  }
}

class _Pallet extends StatelessWidget {
  const _Pallet({required this.pallet});

  final PalletPublicOut pallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: pallet.code,
          status: palletStatusLabel(context.l10n, pallet.status),
        ),
        const SizedBox(height: 8),
        Text(pallet.centerName, style: theme.textTheme.titleMedium),
        Text(
          [
            context.l10n.boxCount(pallet.boxCount),
            if (pallet.closedAt case final closed?)
              context.l10n.palletClosedOn(formatShortDate(closed)),
            if (pallet.deliveredAt case final delivered?)
              context.l10n.palletDeliveredOn(formatShortDate(delivered)),
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Donation extends StatelessWidget {
  const _Donation({required this.donation, required this.onOpen});

  final DonationOut donation;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = donation.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: donation.code,
          status: donationStatusLabel(context.l10n, donation.status),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.donationRegisteredOn(
            formatShortDate(donation.createdAt),
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final item in items.take(4))
          Text(
            '· ${item.freeText ?? context.l10n.donationItemFromCatalogue} — '
            '${item.quantity} ${item.unit}',
            style: theme.textTheme.bodySmall,
          ),
        if (items.length > 4)
          Text(
            context.l10n.andMoreItems(items.length - 4),
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        _Notice(context.l10n.donationItemsAreDeclared),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: context.l10n.scanOpenDonation,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}
