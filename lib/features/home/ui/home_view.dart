import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../boxes/ui/boxes_list_view.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../intake/ui/pending_captures_view.dart';
import '../../pallets/ui/pallets_list_view.dart';
import '../../scanning/ui/scanner_view.dart';
import '../../transfers/ui/transfers_list_view.dart';
import 'push_permission_card.dart';

/// Pantalla principal, todavía provisional: las features operativas llegan en
/// las fases siguientes. Hoy confirma quién inició sesión y permite cerrarla.
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
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logOut(),
          ),
        ],
      ),
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
              FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear código'),
                onPressed: () =>
                    Navigator.of(context).push(ScannerView.route()),
              ),
              const SizedBox(height: 12),
              _PendingCapturesButton(),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Capturas'),
                onPressed: () =>
                    Navigator.of(context).push(IntakeListView.route()),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.pallet),
                label: const Text('Tarimas'),
                onPressed: () =>
                    Navigator.of(context).push(PalletsListView.route()),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Transferencias'),
                onPressed: () =>
                    Navigator.of(context).push(TransfersListView.route()),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Cajas del centro'),
                onPressed: () =>
                    Navigator.of(context).push(BoxesListView.route()),
              ),
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
