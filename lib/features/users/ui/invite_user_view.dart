import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/studio_user_create.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/data/centers_repository.dart';
import '../../team/data/team_repository.dart';
import '../data/users_providers.dart';
import '../data/users_repository.dart';

/// Dar de alta a alguien en cualquier centro.
///
/// El caso móvil es el de siempre: aparece una persona a ofrecerse y quien
/// administra tiene el teléfono en la mano. La diferencia con invitar al propio
/// centro —que ya funciona desde la fase 14— es que aquí se elige a cuál.
///
/// **La contraseña no se escribe ni se ve.** El servidor la genera y la manda
/// por correo; que este cliente nunca la toque es la única forma de que no
/// pueda filtrarla.
class InviteUserView extends ConsumerStatefulWidget {
  const InviteUserView({super.key});

  static Route<UserOut> route() =>
      MaterialPageRoute<UserOut>(builder: (_) => const InviteUserView());

  @override
  ConsumerState<InviteUserView> createState() => _InviteUserViewState();
}

class _InviteUserViewState extends ConsumerState<InviteUserView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _fullName = TextEditingController();

  String _centerRole = 'volunteer';
  String? _centerId;
  bool _sending = false;
  String? _failure;

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _failure = null;
    });

    final outcome = await ref
        .read(usersRepositoryProvider)
        .invite(
          StudioUserCreate(
            email: _email.text.trim(),
            username: _username.text.trim(),
            fullName: _fullName.text.trim().isEmpty
                ? null
                : _fullName.text.trim(),
            centerRole: _centerRole,
            centerId: _centerId,
          ),
        );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (outcome) {
      case UsersRead(:final value):
        Navigator.of(context).pop(value);
      // El motivo es del servidor: que el correo ya tiene cuenta, que el
      // usuario está tomado, que el rol no existe.
      case UsersRefused(:final failure):
        setState(() => _failure = failure.operatorMessage(context.l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final centers = switch (ref.watch(centersProvider).valueOrNull) {
      CentersRead(:final value) =>
        value.where((center) => center.isActive).toList(),
      _ => const <CenterOut>[],
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.userInviteTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.userInviteExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: context.l10n.emailLabel),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return context.l10n.emailRequired;
                return text.contains('@')
                    ? null
                    : context.l10n.emailLooksInvalid;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: context.l10n.usernameLabel,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? context.l10n.fieldRequiredGeneric
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.optionalField(context.l10n.nameLabel),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _centerRole,
              decoration: InputDecoration(labelText: context.l10n.roleLabel),
              items: [
                for (final role in const [
                  'volunteer',
                  'coordinator',
                  'national_admin',
                ])
                  DropdownMenuItem(
                    value: role,
                    child: Text(centerRoleLabel(context.l10n, role)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _centerRole = value ?? _centerRole),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _centerId,
              decoration: InputDecoration(
                labelText: context.l10n.optionalField(context.l10n.centerLabel),
                helperText: context.l10n.userInviteCenterHelper,
              ),
              items: [
                for (final center in centers)
                  DropdownMenuItem(value: center.id, child: Text(center.name)),
              ],
              onChanged: (value) => setState(() => _centerId = value),
            ),
            if (_failure case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _sending ? null : _invite,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.userInviteAction),
            ),
          ],
        ),
      ),
    );
  }
}
