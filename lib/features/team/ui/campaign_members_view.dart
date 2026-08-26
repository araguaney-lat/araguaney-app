import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/campaign_member_out.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../intake/data/intake_providers.dart';
import '../data/team_providers.dart';
import '../data/team_repository.dart';
import 'pick_person_sheet.dart';

/// Who takes part in each campaign.
///
/// The list the server returns already comes trimmed to the own centre when
/// whoever asks coordinates one: this screen filters nothing, it shows what it
/// was given.
class CampaignMembersView extends ConsumerStatefulWidget {
  const CampaignMembersView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CampaignMembersView());

  @override
  ConsumerState<CampaignMembersView> createState() =>
      _CampaignMembersViewState();
}

class _CampaignMembersViewState extends ConsumerState<CampaignMembersView> {
  String? _campaignId;

  CampaignOut? _selected(List<CampaignOut> campaigns) {
    for (final campaign in campaigns) {
      if (campaign.id == _campaignId) return campaign;
    }
    return null;
  }

  Future<void> _add(String campaignId) async {
    final members =
        ref.read(campaignMembersProvider(campaignId)).valueOrNull ??
        const <CampaignMemberOut>[];
    // Asked for here and not in `build`: the directory is only needed when
    // somebody is about to add, and fetching it beforehand is a request that is
    // almost never used. If it does not arrive, that is said; opening an empty
    // sheet would make people believe the centre has nobody else.
    final List<UserOut> people;
    try {
      people = await ref.read(centerUsersProvider.future);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final already = {for (final member in members) member.id};

    final chosen = await PickPersonSheet.show(
      context,
      people: [
        for (final person in people)
          if (person.isActive && !already.contains(person.id)) person,
      ],
    );
    if (chosen == null || !mounted) return;

    final outcome = await ref
        .read(teamRepositoryProvider)
        .addMember(campaignId: campaignId, userId: chosen.id);
    if (!mounted) return;

    _report(campaignId, outcome);
  }

  Future<void> _remove(String campaignId, CampaignMemberOut member) async {
    final name = member.fullName ?? member.username;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeFromCampaignTitle),
        content: Text(context.l10n.removeFromCampaignExplanation(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.removeMemberAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final outcome = await ref
        .read(teamRepositoryProvider)
        .removeMember(campaignId: campaignId, userId: member.id);
    if (!mounted) return;

    _report(campaignId, outcome);
  }

  void _report(String campaignId, TeamOutcome outcome) {
    switch (outcome) {
      case TeamChanged():
        ref.invalidate(campaignMembersProvider(campaignId));
      case TeamRefused(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(myCampaignsProvider).valueOrNull ?? const [];
    final canManage = ref.watch(isCenterCoordinatorProvider);
    final campaign = _selected(campaigns);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.campaignsLabel)),
      floatingActionButton: canManage && campaign != null
          ? FloatingActionButton.extended(
              onPressed: () => _add(campaign.id),
              icon: const Icon(Icons.person_add_alt),
              label: Text(context.l10n.addMemberAction),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _campaignId,
              decoration: InputDecoration(
                labelText: context.l10n.campaignLabel,
              ),
              items: [
                for (final option in campaigns)
                  DropdownMenuItem(value: option.id, child: Text(option.name)),
              ],
              onChanged: (value) => setState(() => _campaignId = value),
            ),
          ),
          if (campaign == null)
            Expanded(child: _Message(context.l10n.pickCampaignToSeeMembers))
          else
            Expanded(
              child: _Members(campaign: campaign, onRemove: _remove),
            ),
        ],
      ),
    );
  }
}

class _Members extends ConsumerWidget {
  const _Members({required this.campaign, required this.onRemove});

  final CampaignOut campaign;
  final void Function(String campaignId, CampaignMemberOut member) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(campaignMembersProvider(campaign.id));
    final canManage = ref.watch(isCenterCoordinatorProvider);

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(campaignMembersProvider(campaign.id)),
      child: switch (members) {
        AsyncData(:final value) when value.isEmpty => _Message(
          context.l10n.campaignHasNoMembers,
        ),
        AsyncData(:final value) => ListView.separated(
          itemCount: value.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // The general campaign collects what belongs to no other: nobody
            // is taken out of it, and the server answers 422 if you try.
            if (index == 0) {
              return campaign.isGeneral
                  ? _Note(context.l10n.generalCampaignExplanation)
                  : const SizedBox.shrink();
            }
            final member = value[index - 1];
            return _Member(
              member: member,
              onRemove: canManage && !campaign.isGeneral
                  ? () => onRemove(campaign.id, member)
                  : null,
            );
          },
        ),
        AsyncError(:final error) => _Message(
          ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Member extends StatelessWidget {
  const _Member({required this.member, this.onRemove});

  final CampaignMemberOut member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.person_outline),
    title: Text(member.fullName ?? member.username),
    subtitle: Text(
      '${centerRoleLabel(context.l10n, member.centerRole)} · ${member.username}',
    ),
    trailing: onRemove == null
        ? null
        : IconButton(
            tooltip: context.l10n.removeFromCampaignTitle,
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: onRemove,
          ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
