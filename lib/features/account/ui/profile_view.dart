import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/api/generated/models/user_profile_out.dart';
import '../../../core/ui/record_field.dart';
import '../../session/ui/change_password_view.dart';
import '../data/account_providers.dart';
import '../data/account_repository.dart';
import 'totp_setup_view.dart';

/// Quién eres y cómo está protegida tu cuenta.
///
/// Se consulta en línea siempre. Un perfil cacheado enseñaría un rol o un
/// centro que pudieron cambiar, y aquí eso no es un detalle: es lo que alguien
/// mira para saber qué puede hacer.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ProfileView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(myAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y seguridad')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myAccountProvider),
        child: switch (account) {
          AsyncData(:final value) => _Loaded(
            profile: value.profile,
            account: value.account,
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.profile, required this.account});

  final UserProfileOut profile;
  final UserOut account;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      RecordField(label: 'Nombre', value: profile.fullName ?? '—'),
      RecordField(label: 'Usuario', value: profile.username),
      RecordField(label: 'Correo', value: profile.email),
      if (profile.centerName case final center?)
        RecordField(label: 'Centro', value: center),
      if (profile.centerRole case final role?)
        RecordField(label: 'Rol', value: _roleLabel(role)),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: OutlinedButton(
          onPressed: () => _rename(context, ref, profile.fullName ?? ''),
          child: const Text('Cambiar mi nombre'),
        ),
      ),
      const Divider(height: 32),
      ListTile(
        title: const Text('Contraseña'),
        subtitle: const Text('Cámbiala cuando quieras, no solo cuando toca'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ChangePasswordView(forced: false),
          ),
        ),
      ),
      _TotpTile(enabled: account.totpEnabled),
      if (account.mustAcceptTerms) const _TermsTile(),
    ],
  );

  static String _roleLabel(String role) => switch (role) {
    'volunteer' => 'Voluntariado',
    'coordinator' => 'Coordinación',
    'national_admin' => 'Administración nacional',
    _ => role,
  };

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;

    final outcome = await ref.read(accountRepositoryProvider).rename(name);
    if (!context.mounted) return;

    if (outcome case AccountRefused(:final failure)) {
      _say(context, failure.operatorMessage);
      return;
    }
    ref.invalidate(myAccountProvider);
  }
}

class _TotpTile extends ConsumerWidget {
  const _TotpTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    title: const Text('Verificación en dos pasos'),
    subtitle: Text(
      enabled
          ? 'Activada: al entrar se te pide un código'
          : 'Desactivada: tu contraseña es lo único que protege la cuenta',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      if (enabled) {
        await _disable(context, ref);
      } else {
        final done = await Navigator.of(context).push(TotpSetupView.route());
        if (done ?? false) ref.invalidate(myAccountProvider);
      }
    },
  );

  /// Quitarlo pide un código, igual que ponerlo.
  ///
  /// No es un trámite de más: es lo que impide que quien encuentre un teléfono
  /// desbloqueado desactive la segunda barrera antes de llevarse la cuenta.
  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desactivar la verificación?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Después de esto, tu contraseña será lo único que proteja la '
              'cuenta. Escribe un código de tu aplicación para confirmarlo.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Código'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;

    final outcome = await ref.read(accountRepositoryProvider).disableTotp(code);
    if (!context.mounted) return;

    if (outcome case AccountRefused(:final failure)) {
      _say(context, failure.operatorMessage);
      return;
    }
    ref.invalidate(myAccountProvider);
  }
}

/// El servidor pide aceptar los términos y **no bloquea** por ello, así que
/// aquí tampoco: se ofrece, no se interpone.
class _TermsTile extends ConsumerWidget {
  const _TermsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.assignment_outlined),
    title: const Text('Términos pendientes de aceptar'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      final outcome = await ref
          .read(accountRepositoryProvider)
          .acceptTerms('current');
      if (!context.mounted) return;
      if (outcome case AccountRefused(:final failure)) {
        _say(context, failure.operatorMessage);
        return;
      }
      ref.invalidate(myAccountProvider);
    },
  );
}

void _say(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
