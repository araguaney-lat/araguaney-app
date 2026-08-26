import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../domain/login_failure_message.dart';
import 'login_view.dart';

/// The second factor. It is only reached when the server asks for it, with a
/// partial token that expires in minutes and is never stored on the device.
class TotpChallengeView extends ConsumerStatefulWidget {
  const TotpChallengeView({super.key});

  @override
  ConsumerState<TotpChallengeView> createState() => _TotpChallengeViewState();
}

class _TotpChallengeViewState extends ConsumerState<TotpChallengeView> {
  final _code = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.trim().length < 6) return;

    setState(() => _submitting = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .submitTotpCode(_code.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final failure = state is SessionAwaitingTotp && state.failure != null
        ? loginFailureMessage(context.l10n, state.failure!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.totpChallengeTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.backToLogin,
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).cancelTotp(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.totpChallengeExplanation,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: Theme.of(context).textTheme.headlineSmall,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.l10n.totpCodeLabel,
                      counterText: '',
                    ),
                  ),
                  if (failure != null) ...[
                    const SizedBox(height: 16),
                    SessionFailureBanner(message: failure),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.totpVerifySubmit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
