import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/pending_captures_view.dart';
import 'push_permission_card.dart';

/// El destino «Inicio» de la barra inferior.
///
/// Ya no es un menú: navegar es trabajo de la barra y de su hoja de «Menú».
/// Aquí queda lo que hay que saber al abrir la aplicación —quién es quien
/// entró, si los avisos están activos y qué quedó a medias— y una sola acción,
/// la de la cola, que existe porque una captura sin enviar es lo único que se
/// puede perder.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static const _roleLabels = {
    'volunteer': 'Voluntariado',
    'coordinator': 'Coordinación',
    'national_admin': 'Administración nacional',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sessionControllerProvider);
    final session = state is SessionActive ? state.session : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      // Desplazable, no centrada: con la tarjeta del permiso y los accesos, el
      // contenido ya no cabe en una pantalla pequeña, y un `Column` centrado
      // desborda en vez de dejar bajar.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              if (session?.centerRole case final role?)
                Text(
                  _roleLabels[role] ?? role,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 8),
              Text(
                'Sesión iniciada.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const PushPermissionCard(),
              const SizedBox(height: 12),
              _PendingCapturesButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Acceso a la cola, con el contador siempre a la vista.
///
/// El contador es permanente y no un aviso que se cierra: una captura que
/// espera señal tiene que seguir molestando hasta que salga, porque nadie
/// recuerda por sí solo que dejó tres donaciones sin enviar.
class _PendingCapturesButton extends ConsumerWidget {
  const _PendingCapturesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCaptureCountProvider).valueOrNull ?? 0;
    if (pending == 0) return const SizedBox.shrink();

    return FilledButton.tonalIcon(
      icon: Badge(
        label: Text('$pending'),
        child: const Icon(Icons.cloud_upload_outlined),
      ),
      label: Text(
        pending == 1 ? '1 captura sin enviar' : '$pending capturas sin enviar',
      ),
      onPressed: () => Navigator.of(context).push(PendingCapturesView.route()),
    );
  }
}

/// Acceso a los mensajes, con los privados sin leer a la vista.
///
/// El contador cuenta solo los privados, que es lo que el servidor devuelve:
/// un hilo de campaña lo lee quien quiera cuando quiera, y contarlo como
/// pendiente convertiría el número en ruido.
