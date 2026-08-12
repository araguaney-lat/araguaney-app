import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../boxes/ui/boxes_list_view.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../scanning/ui/scanner_view.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 16),
              if (session?.centerRole case final role?)
                Text(
                  _roleLabels[role] ?? role,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 8),
              Text(
                'Sesión iniciada. Las operaciones del centro llegan en las '
                'siguientes fases.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear código'),
                onPressed: () =>
                    Navigator.of(context).push(ScannerView.route()),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Capturas'),
                onPressed: () =>
                    Navigator.of(context).push(IntakeListView.route()),
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
