import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/auth/auth_providers.dart';
import 'login_view.dart';

/// Cambio de contraseña obligatorio.
///
/// El backend marca `must_change_password` cuando la clave la generó quien
/// administra al crear o reiniciar la cuenta. Se interpone antes de operar: no
/// hay forma de saltarla, porque su razón de existir es que una clave temporal
/// enviada por correo deje de servir en cuanto se usa.
class ChangePasswordView extends ConsumerStatefulWidget {
  const ChangePasswordView({super.key});

  @override
  ConsumerState<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends ConsumerState<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _failure;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
    } on Object catch (error) {
      // La política de contraseñas la define y la aplica el servidor; su
      // mensaje es el que se muestra.
      if (mounted) {
        setState(
          () => _failure = ApiErrorMapper.fromAny(error).operatorMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambia tu contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tu contraseña actual es temporal. Elige una nueva para '
                      'continuar.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _current,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña actual',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Escribe tu contraseña actual'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _next,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña nueva',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Escribe tu contraseña nueva'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña nueva',
                        border: OutlineInputBorder(),
                      ),
                      // Lo único que se valida aquí: que las dos coincidan. Es
                      // un dedazo que el servidor no puede detectar.
                      validator: (value) => value != _next.text
                          ? 'Las contraseñas no coinciden'
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
                          : const Text('Guardar y continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
