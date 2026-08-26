import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../campaigns/data/campaigns_providers.dart';
import '../../campaigns/ui/campaign_record_view.dart';

/// Choosing which campaign the capture is charged to.
///
/// The campaign stopped being a field of the form and moved to the header: it
/// is not a piece of the donation written each time, it is the context the
/// whole shift is worked in. It is chosen once and seen always.
class CampaignSheet extends ConsumerWidget {
  const CampaignSheet({
    super.key,
    required this.campaigns,
    required this.selected,
  });

  final List<CampaignOut> campaigns;
  final String? selected;

  /// Returns `(id,)` with the choice, or null if it was closed without
  /// choosing. The record wraps the identifier because «sin campaña» is a valid
  /// choice and is also null.
  static Future<({String? id})?> show(
    BuildContext context, {
    required List<CampaignOut> campaigns,
    required String? selected,
  }) => showModalBottomSheet<({String? id})>(
    context: context,
    useSafeArea: true,
    builder: (_) => CampaignSheet(campaigns: campaigns, selected: selected),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            context.l10n.campaignLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(context.l10n.campaignDefaultsToGeneral),
        ),
        const Divider(),
        _Option(
          label: context.l10n.generalCampaign,
          value: null,
          selected: selected,
        ),
        for (final campaign in campaigns)
          _Option(
            label: campaign.name,
            value: campaign.id,
            selected: selected,
            // Only for whoever can open it: the record requires coordination,
            // and an icon that leads to a 403 is worse than not offering it.
            onOpen: ref.watch(canBrowseCampaignsProvider)
                ? () => Navigator.of(
                    context,
                  ).push(CampaignRecordView.route(campaign.id))
                : null,
          ),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.value,
    required this.selected,
    this.onOpen,
  });

  final String label;
  final String? value;
  final String? selected;

  /// Opens the campaign's record without choosing it. Null when this session
  /// cannot read it.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value == selected) const Icon(Icons.check),
        if (onOpen case final open?)
          IconButton(
            tooltip: context.l10n.campaignRecordTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: open,
          ),
      ],
    ),
    onTap: () => Navigator.of(context).pop((id: value)),
  );
}
