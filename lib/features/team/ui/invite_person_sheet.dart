import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';

/// What is needed to add somebody at the centre.
typedef InviteDraft = ({
  String email,
  String username,
  String? fullName,
  String centerRole,
});

/// Adding a person at the own centre.
///
/// The centre is not chosen: it is that of whoever holds the session, and the
/// server refuses any other. The role does not offer national administration
/// either, because the backend does not allow creating one from here.
class InvitePersonSheet extends StatefulWidget {
  const InvitePersonSheet({super.key});

  static Future<InviteDraft?> show(BuildContext context) =>
      showModalBottomSheet<InviteDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const InvitePersonSheet(),
      );

  @override
  State<InvitePersonSheet> createState() => _InvitePersonSheetState();
}

class _InvitePersonSheetState extends State<InvitePersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  String _role = 'volunteer';

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _fullName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final fullName = _fullName.text.trim();
    Navigator.of(context).pop((
      email: _email.text.trim(),
      username: _username.text.trim(),
      fullName: fullName.isEmpty ? null : fullName,
      centerRole: _role,
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: sheetBottomInset(context),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.inviteToCenterTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.inviteExplanation,
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
              // A minimal check: the one that really validates is the server,
              // and a cleverer regular expression would reject valid
              // addresses.
              return text.contains('@') ? null : context.l10n.emailLooksInvalid;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _username,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: context.l10n.usernameFieldLabel,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.usernameRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: context.l10n.fullNameOptionalLabel,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(labelText: context.l10n.roleLabel),
            items: [
              DropdownMenuItem(
                value: 'volunteer',
                child: Text(context.l10n.roleVolunteer),
              ),
              DropdownMenuItem(
                value: 'coordinator',
                child: Text(context.l10n.roleCoordinator),
              ),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'volunteer'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submit,
              child: Text(context.l10n.inviteSubmit),
            ),
          ),
        ],
      ),
    ),
  );
}
