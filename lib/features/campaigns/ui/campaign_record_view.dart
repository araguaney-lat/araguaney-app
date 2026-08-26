import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../reports/ui/reports_view.dart';
import '../../team/data/team_providers.dart';
import '../../team/data/team_repository.dart';
import '../data/campaigns_providers.dart';
import '../data/campaigns_repository.dart';
import 'campaign_form_view.dart';

/// La ficha de una campaña.
///
/// Responde lo que la hoja de elección no podía: qué es, cuándo corre, quién
/// está dentro y si es la general.
class CampaignRecordView extends ConsumerWidget {
  const CampaignRecordView({super.key, required this.campaignId});

  final String campaignId;

  static Route<void> route(String campaignId) => MaterialPageRoute<void>(
    builder: (_) => CampaignRecordView(campaignId: campaignId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(campaignRecordProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.campaignRecordTitle),
        actions: [
          if (ref.watch(canManageCampaignsProvider))
            if (record.valueOrNull case CampaignRead(:final value))
              IconButton(
                tooltip: context.l10n.campaignEditTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).push(CampaignFormView.route(existing: value));
                  ref
                    ..invalidate(campaignRecordProvider(campaignId))
                    ..invalidate(campaignsProvider);
                },
              ),
        ],
      ),
      body: switch (record) {
        AsyncData(value: CampaignRead(:final value)) => _Fields(
          campaign: value,
        ),
        AsyncData(value: CampaignRefused(:final isForbidden, :final failure)) =>
          _Message(
            isForbidden
                ? context.l10n.campaignsForbidden
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Fields extends ConsumerWidget {
  const _Fields({required this.campaign});

  final CampaignOut campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      RecordField(label: context.l10n.campaignNameLabel, value: campaign.name),
      if (campaign.description case final description?)
        RecordField(
          label: context.l10n.campaignPurposeLabel,
          value: description,
        ),
      if (campaign.startDate case final start?)
        RecordField(
          label: context.l10n.campaignStartsLabel,
          value: formatShortDate(start),
        ),
      if (campaign.endDate case final end?)
        RecordField(
          label: context.l10n.campaignEndsLabel,
          value: formatShortDate(end),
        ),
      if (campaign.originCountry case final origin?)
        RecordField(label: context.l10n.campaignOriginLabel, value: origin),
      if (campaign.destinationCountry case final destination?)
        RecordField(
          label: context.l10n.campaignDestinationLabel,
          value: destination,
        ),
      if (campaign.weightGoalKg case final goal?)
        RecordField(label: context.l10n.campaignGoalLabel, value: '$goal kg'),
      if (!campaign.isActive)
        RecordField(
          label: context.l10n.statusLabel,
          value: context.l10n.campaignClosedTag,
        ),
      // La general no se explica sola: `PROTECTED_CAMPAIGN` existe porque nadie
      // se puede sacar de ella, y descubrirlo por un rechazo es peor que
      // leerlo aquí.
      if (campaign.isGeneral)
        ListTile(
          leading: const Icon(Icons.all_inclusive),
          title: Text(context.l10n.campaignGeneralTag),
          subtitle: Text(context.l10n.campaignGeneralExplanation),
        ),
      ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: Text(context.l10n.reportsTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(ReportsView.route(campaignId: campaign.id)),
      ),
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          context.l10n.campaignMembersTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      switch (ref.watch(campaignMembersProvider(campaign.id))) {
        AsyncData(:final value) when value.isEmpty => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.campaignNoMembers),
        ),
        AsyncData(:final value) => Column(
          children: [
            for (final member in value)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(member.fullName ?? member.username),
                subtitle: Text(
                  [
                    centerRoleLabel(context.l10n, member.centerRole),
                    member.username,
                  ].join(' · '),
                ),
              ),
          ],
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l10n.campaignMembersUnavailable),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    ],
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
