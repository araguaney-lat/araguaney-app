import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/team_providers.dart';
import '../data/team_repository.dart';
import 'campaign_members_view.dart';
import 'invite_person_sheet.dart';

/// El equipo del centro.
///
/// Lo lee cualquiera que pertenezca al centro —saber con quién se trabaja no
/// es un privilegio—, y solo la coordinación suma gente o reenvía un acceso.
/// El servidor exige ese rol y sigue decidiendo; aquí solo se evita ofrecer un
/// botón que responderá 403.
class TeamDirectoryView extends ConsumerWidget {
  const TeamDirectoryView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const TeamDirectoryView());

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final centerId = ref.read(myCenterIdProvider);
    if (centerId == null) return;

    final draft = await InvitePersonSheet.show(context);
    if (draft == null || !context.mounted) return;

    final outcome = await ref
        .read(teamRepositoryProvider)
        .invite(
          centerId: centerId,
          email: draft.email,
          username: draft.username,
          fullName: draft.fullName,
          centerRole: draft.centerRole,
        );
    if (!context.mounted) return;

    _report(context, ref, outcome);
  }

  Future<void> _reinvite(
    BuildContext context,
    WidgetRef ref,
    UserOut person,
  ) async {
    final centerId = ref.read(myCenterIdProvider);
    if (centerId == null) return;

    final outcome = await ref
        .read(teamRepositoryProvider)
        .reinvite(centerId: centerId, userId: person.id);
    if (!context.mounted) return;

    _report(context, ref, outcome);
  }

  void _report(BuildContext context, WidgetRef ref, TeamOutcome outcome) {
    switch (outcome) {
      case TeamChanged(:final notice):
        ref.invalidate(centerUsersProvider);
        if (notice != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(notice)));
        }
      case TeamRefused(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(centerUsersProvider);
    final canManage = ref.watch(isCenterCoordinatorProvider);
    final hasCenter = ref.watch(myCenterIdProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.shellEquipo),
        actions: [
          IconButton(
            tooltip: context.l10n.teamCampanas,
            icon: const Icon(Icons.groups_outlined),
            onPressed: () =>
                Navigator.of(context).push(CampaignMembersView.route()),
          ),
        ],
      ),
      floatingActionButton: canManage && hasCenter
          ? FloatingActionButton.extended(
              onPressed: () => _invite(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: Text(context.l10n.teamSumar),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(centerUsersProvider),
        child: switch (people) {
          AsyncData() when !hasCenter => const _Message(
            'Tu sesión no pertenece a un centro, así que no hay un equipo que '
            'mostrar aquí.',
          ),
          AsyncData(:final value) when value.isEmpty => const _Message(
            'Todavía no hay nadie más en este centro.',
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _Person(
              person: value[index],
              onReinvite: canManage
                  ? () => _reinvite(context, ref, value[index])
                  : null,
            ),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.person, this.onReinvite});

  final UserOut person;
  final VoidCallback? onReinvite;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      person.isActive ? Icons.person_outline : Icons.person_off_outlined,
    ),
    title: Text(person.fullName ?? person.username),
    subtitle: Text(
      [
        centerRoleLabel(person.centerRole),
        person.username,
        if (!person.isActive) 'cuenta desactivada',
      ].join(' · '),
    ),
    // Reenviar el acceso no se ofrece sobre una cuenta desactivada: el
    // servidor lo rechaza, y activarla es trabajo de escritorio.
    trailing: onReinvite != null && person.isActive
        ? IconButton(
            tooltip: context.l10n.teamReenviarAcceso,
            icon: const Icon(Icons.mail_outline),
            onPressed: onReinvite,
          )
        : null,
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
