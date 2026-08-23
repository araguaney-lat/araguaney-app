import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/data/account_providers.dart';
import '../../account/data/account_repository.dart';
import 'login_view.dart';

/// Pedir el correo de recuperación.
///
/// Lo que llega al buzón es **un enlace a la web**, no un código para escribir
/// aquí. Por eso esta pantalla termina en una instrucción y no en otro campo:
/// prometer que se puede terminar dentro de la aplicación sería mentir, y quien
/// se quedó fuera de su cuenta es la peor persona a quien mentirle.
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
          _failure = failure.operatorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recuperar el acceso')),
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
          'Escribe el correo de tu cuenta y te enviamos un enlace para elegir '
          'una contraseña nueva.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Correo'),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Escribe tu correo'
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
              : const Text('Enviar el enlace'),
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
        // El servidor contesta lo mismo exista o no la cuenta, para que esta
        // pantalla no sirva para averiguar quién tiene una. Se repite tal cual.
        'Si ese correo tiene una cuenta, el enlace ya va en camino.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Text(
        'El enlace abre en el navegador y ahí eliges la contraseña nueva. '
        'Después vuelve aquí para entrar.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Volver'),
      ),
    ],
  );
}
