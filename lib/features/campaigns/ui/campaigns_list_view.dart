import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/campaigns_providers.dart';
import '../data/campaigns_repository.dart';
import 'campaign_form_view.dart';
import 'campaign_record_view.dart';

/// The platform's campaigns.
///
/// The capture already lets one be chosen; this is where you find out **what**
/// the chosen one is. Until now the choice was offered and the context was not:
/// when it starts, what it is for, who else is inside.
class CampaignsListView extends ConsumerWidget {
  const CampaignsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CampaignsListView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.campaignsTitle)),
      floatingActionButton: ref.watch(canManageCampaignsProvider)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(CampaignFormView.route());
                ref.invalidate(campaignsProvider);
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.campaignNewTitle),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(campaignsProvider),
        child: switch (campaigns) {
          AsyncData(value: CampaignRead(:final value)) when value.isEmpty =>
            _Message(context.l10n.campaignsEmpty),
          AsyncData(value: CampaignRead(:final value)) => ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [for (final campaign in value) _Row(campaign: campaign)],
          ),
          AsyncData(
            value: CampaignRefused(:final isForbidden, :final failure),
          ) =>
            _Message(
              isForbidden
                  ? context.l10n.campaignsForbidden
                  : failure.operatorMessage(context.l10n),
            ),
          AsyncError(:final error) => _Message('$error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.campaign});

  final CampaignOut campaign;

  @override
  Widget build(BuildContext context) {
    final dates = [
      ?campaign.startDate,
      ?campaign.endDate,
    ].map(formatShortDate).join(' – ');

    return ListTile(
      title: Text(campaign.name),
      subtitle: dates.isEmpty ? null : Text(dates),
      trailing: campaign.isGeneral
          ? Chip(label: Text(context.l10n.campaignGeneralTag))
          : (campaign.isActive
                ? null
                : Chip(label: Text(context.l10n.campaignClosedTag))),
      onTap: () =>
          Navigator.of(context).push(CampaignRecordView.route(campaign.id)),
    );
  }
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
