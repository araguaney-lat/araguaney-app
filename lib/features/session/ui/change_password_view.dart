import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import 'login_view.dart';

/// Cambiar la contraseña, por obligación o por decisión.
///
/// Es el mismo formulario en los dos casos porque es la misma operación; lo
/// único que cambia es por qué se está aquí.
///
/// Con [forced] el backend marcó `must_change_password`: la clave la generó
/// quien administra al crear o reiniciar la cuenta, y la pantalla se interpone
/// antes de operar sin forma de saltarla, porque su razón de existir es que una
/// clave temporal enviada por correo deje de servir en cuanto se usa.
///
/// Sin [forced] se llega desde el perfil, porque nadie debería tener que
/// esperar a que le obliguen para cambiar una contraseña que cree comprometida.
class ChangePasswordView extends ConsumerStatefulWidget {
  const ChangePasswordView({super.key, this.forced = true});

  final bool forced;

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
      // En el caso obligatorio no hay a dónde volver: la puerta de la sesión
      // deja de interponer esta pantalla sola. En el voluntario sí, y quedarse
      // aquí sin decir nada parecería que no pasó nada.
      if (!widget.forced && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.passwordUpdated)));
      }
    } on Object catch (error) {
      // La política de contraseñas la define y la aplica el servidor; su
      // mensaje es el que se muestra.
      if (mounted) {
        setState(
          () => _failure = ApiErrorMapper.fromAny(
            error,
          ).operatorMessage(context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.changePasswordTitle),
        automaticallyImplyLeading: !widget.forced,
      ),
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
                      widget.forced
                          ? context.l10n.forcedPasswordChangeExplanation
                          : context.l10n.deliberatePasswordChangeExplanation,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _current,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.currentPasswordLabel,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? context.l10n.currentPasswordRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _next,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.newPasswordLabel,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? context.l10n.newPasswordRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: context.l10n.repeatNewPasswordLabel,
                      ),
                      // Lo único que se valida aquí: que las dos coincidan. Es
                      // un dedazo que el servidor no puede detectar.
                      validator: (value) => value != _next.text
                          ? context.l10n.passwordsDoNotMatch
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
                          : Text(
                              widget.forced ? 'Guardar y continuar' : 'Guardar',
                            ),
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
