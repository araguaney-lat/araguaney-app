import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../account/data/account_providers.dart';
import '../../account/data/account_repository.dart';
import 'login_view.dart';

/// Asking for the recovery email.
///
/// What arrives in the inbox is **a link to the web**, not a code to type here.
/// That is why this screen ends in an instruction and not in another field:
/// promising it can be finished inside the application would be a lie, and
/// somebody locked out of their account is the worst person to lie to.
class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordView());

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _failure;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    final outcome = await ref
        .read(accountRepositoryProvider)
        .requestPasswordReset(_email.text.trim());
    if (!mounted) return;

    setState(() {
      _submitting = false;
      switch (outcome) {
        case AccountDone():
          _sent = true;
        case AccountRefused(:final failure):
          _failure = failure.operatorMessage(context.l10n);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.forgotPasswordTitle)),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _sent ? const _Sent() : _form(context),
          ),
        ),
      ),
    ),
  );

  Widget _form(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.forgotPasswordExplanation,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: context.l10n.emailLabel),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? context.l10n.emailRequired
              : null,
        ),
        if (_failure case final message?) ...[
          const SizedBox(height: 16),
          SessionFailureBanner(message: message),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.forgotPasswordSubmit),
        ),
      ],
    ),
  );
}

class _Sent extends StatelessWidget {
  const _Sent();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 48),
      const SizedBox(height: 16),
      Text(
        // The server answers the same whether or not the account exists, so
        // this screen cannot be used to find out who has one. It is repeated as
        // it is.
        context.l10n.forgotPasswordSent,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Text(
        context.l10n.forgotPasswordLinkOpensBrowser,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.backAction),
      ),
    ],
  );
}
