import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/user_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../centers/data/centers_providers.dart';
import '../../team/data/team_repository.dart';
import '../data/users_providers.dart';
import '../data/users_repository.dart';

/// What a person is on the platform.
///
/// Read-only, and one action. Changing somebody's role or centre has
/// consequences that outlast the moment, and doing it from a phone is no better
/// than doing it from a desk; resending their access, on the other hand, is
/// asked for out loud in front of you.
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
              // The name only if this session can resolve it; otherwise
              // nothing, because an identifier tells nobody which centre it is
              // talking about.
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
          // Two signs that an account was really used: the second factor is
          // turned on from inside, and the terms are accepted on the way in.
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
          // Resending on a deactivated account is refused by the server, and
          // activating it is desk work.
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
