import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import 'login_view.dart';

/// Segundo factor. Se llega aquí solo cuando el servidor lo pide, con un token
/// parcial que caduca en minutos y que nunca se guarda en el dispositivo.
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
    final failure = state is SessionAwaitingTotp ? state.failureMessage : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación en dos pasos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al inicio de sesión',
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
                    'Escribe el código de tu aplicación de autenticación.',
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
                    decoration: const InputDecoration(
                      labelText: 'Código de 6 dígitos',
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
                        : const Text('Verificar'),
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
