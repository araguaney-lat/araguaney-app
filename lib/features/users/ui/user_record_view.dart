import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/user_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../centers/data/centers_providers.dart';
import '../../team/data/team_repository.dart';
import '../data/users_providers.dart';
import '../data/users_repository.dart';

/// Qué es una persona en la plataforma.
///
/// Solo lectura y una acción. Cambiar el rol o el centro de alguien tiene
/// consecuencias que duran más que el momento, y hacerlo desde un teléfono no
/// es mejor que hacerlo desde un escritorio; reenviarle el acceso, en cambio,
/// se pide de viva voz delante de ti.
class UserRecordView extends ConsumerStatefulWidget {
  const UserRecordView({super.key, required this.user});

  final UserOut user;

  static Route<void> route(UserOut user) =>
      MaterialPageRoute<void>(builder: (_) => UserRecordView(user: user));

  @override
  ConsumerState<UserRecordView> createState() => _UserRecordViewState();
}

class _UserRecordViewState extends ConsumerState<UserRecordView> {
  bool _sending = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    final outcome = await ref
        .read(usersRepositoryProvider)
        .resendAccess(widget.user.id);
    if (!mounted) return;
    setState(() => _sending = false);

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          UsersRead() => context.l10n.userAccessResent,
          UsersRefused(:final failure) => failure.operatorMessage(context.l10n),
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final centers = ref.watch(centerNamesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.userRecordTitle)),
      body: ListView(
        children: [
          RecordField(
            label: context.l10n.nameLabel,
            value: user.fullName ?? user.username,
          ),
          RecordField(label: context.l10n.usernameLabel, value: user.username),
          RecordField(label: context.l10n.emailLabel, value: user.email),
          RecordField(
            label: context.l10n.roleLabel,
            value: centerRoleLabel(context.l10n, user.centerRole),
          ),
          if (user.centerId case final centerId?)
            RecordField(
              label: context.l10n.centerLabel,
              // El nombre solo si esta sesión puede resolverlo; si no, nada,
              // porque un identificador no le dice a nadie de qué centro habla.
              value: centers[centerId] ?? context.l10n.usersCenterUnnamed,
            ),
          if (user.countryCode case final country?)
            RecordField(label: context.l10n.countryLabel, value: country),
          RecordField(
            label: context.l10n.statusLabel,
            value: user.isActive
                ? context.l10n.userActive
                : context.l10n.accountDisabledTag,
          ),
          // Dos señales de que una cuenta se usó de verdad: el segundo factor
          // se activa desde dentro, y los términos se aceptan al entrar.
          if (user.totpEnabled)
            RecordField(
              label: context.l10n.totpLabel,
              value: context.l10n.userTotpOn,
            ),
          if (user.mustAcceptTerms)
            RecordField(
              label: context.l10n.userPendingTermsLabel,
              value: context.l10n.userPendingTerms,
            ),
          const SizedBox(height: 16),
          // Reenviar sobre una cuenta desactivada lo rechaza el servidor, y
          // activarla es trabajo de escritorio.
          if (user.isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _sending ? null : _resend,
                icon: const Icon(Icons.mail_outline),
                label: Text(context.l10n.userResendAccess),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.userResendExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
