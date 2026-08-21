import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../dashboard/ui/stock_by_category_view.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../intake/ui/pending_captures_view.dart';
import '../../pallets/ui/pallets_list_view.dart';
import '../../risk_reviews/ui/risk_reviews_view.dart';
import '../../team/ui/team_directory_view.dart';
import '../../transfers/ui/transfers_list_view.dart';

/// Todo lo que no cabe en la barra.
///
/// Se abre desde el cuarto destino. Lo que entra aquí es lo que se consulta
/// cada varios días —tarimas, transferencias, el equipo— frente a lo que se
/// toca cada pocos minutos, que es lo que gana un sitio en la barra.
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const MoreMenuSheet(),
  );

  void _go(BuildContext context, Route<void> route) {
    Navigator.of(context).pop();
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(isCenterCoordinatorProvider);
    final pending = ref.watch(pendingCaptureCountProvider).valueOrNull ?? 0;

    return ListView(
      padding: EdgeInsets.only(bottom: sheetBottomInset(context, base: 8)),
      shrinkWrap: true,
      children: [
        // Siempre, no solo con la cola llena: aquí se reponen los códigos de
        // caja, y hacerlo hace falta **antes** de quedarse sin señal. Estaba
        // condicionado a `pending > 0`, así que la única puerta a reservar se
        // abría cuando ya era tarde.
        ListTile(
          leading: pending > 0
              ? Badge(
                  label: Text('$pending'),
                  child: const Icon(Icons.cloud_upload_outlined),
                )
              : const Icon(Icons.cloud_upload_outlined),
          title: const Text('Pendientes de envío'),
          onTap: () => _go(context, PendingCapturesView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt_outlined),
          title: const Text('Capturas'),
          onTap: () => _go(context, IntakeListView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.donut_small_outlined),
          title: const Text('Stock por categoría'),
          onTap: () => _go(context, StockByCategoryView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.pallet),
          title: const Text('Tarimas'),
          onTap: () => _go(context, PalletsListView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text('Transferencias'),
          onTap: () => _go(context, TransfersListView.route()),
        ),
        if (coordinates)
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Revisiones de riesgo'),
            onTap: () => _go(context, RiskReviewsView.route()),
          ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Equipo'),
          onTap: () => _go(context, TeamDirectoryView.route()),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: () {
            Navigator.of(context).pop();
            ref.read(sessionControllerProvider.notifier).logOut();
          },
        ),
      ],
    );
  }
}
