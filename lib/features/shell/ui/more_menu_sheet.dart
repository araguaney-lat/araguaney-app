import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../account/ui/profile_view.dart';
import '../../catalog/ui/catalog_list_view.dart';
import '../../center_applications/data/center_applications_providers.dart';
import '../../center_applications/ui/application_queue_view.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/ui/centers_list_view.dart';
import '../../centers/ui/choose_center_view.dart';
import '../../dashboard/ui/stock_by_category_view.dart';
import '../../incidents/ui/incidents_list_view.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../intake/ui/pending_captures_view.dart';
import '../../pallets/ui/pallets_list_view.dart';
import '../../risk_reviews/ui/risk_reviews_view.dart';
import '../../shipments/ui/shipments_list_view.dart';
import '../../team/ui/team_directory_view.dart';
import '../../transfers/ui/transfers_list_view.dart';

/// Todo lo que no cabe en la barra.
///
/// Se abre desde el cuarto destino. Lo que entra aquí es lo que se consulta
/// cada varios días —tarimas, transferencias, el equipo— frente a lo que se
/// toca cada pocos minutos, que es lo que gana un sitio en la barra.
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  /// `isScrollControlled` porque el menú creció: sin él la hoja se topa en
  /// poco más de la mitad de la pantalla y las últimas entradas quedan bajo el
  /// pliegue, que en un menú es lo mismo que no existir. Con él se ajusta a su
  /// contenido, y el `ConstrainedBox` evita que llegue a tapar la pantalla
  /// entera cuando la lista siga creciendo.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
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
          title: Text(context.l10n.pendingCapturesTitle),
          onTap: () => _go(context, PendingCapturesView.route()),
        ),
        // Only for a session with no centre of its own. It sits high because
        // it is where somebody checks what they are about to write into, not
        // only where they change it.
        if (ref.watch(workingCenterProvider).valueOrNull case final center?)
          if (ref.watch(writeCenterIdProvider) != null)
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: Text(context.l10n.workingCenterTitle),
              subtitle: Text(center.name),
              trailing: Text(context.l10n.workingCenterChangeAction),
              onTap: () => _go(context, ChooseCenterView.route()),
            ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.l10n.profileTitle),
          onTap: () => _go(context, ProfileView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt_outlined),
          title: Text(context.l10n.navCaptures),
          onTap: () => _go(context, IntakeListView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.donut_small_outlined),
          title: Text(context.l10n.stockByCategoryTitle),
          onTap: () => _go(context, StockByCategoryView.route()),
        ),
        // Para todo el mundo: buscar un producto es de quien captura, y dar de
        // alta uno es lo único que la pantalla reserva por rol.
        ListTile(
          leading: const Icon(Icons.inventory_outlined),
          title: Text(context.l10n.catalogTitle),
          onTap: () => _go(context, CatalogListView.route()),
        ),
        ListTile(
          leading: const Icon(Icons.pallet),
          title: Text(context.l10n.palletsTitle),
          onTap: () => _go(context, PalletsListView.route()),
        ),
        if (coordinates)
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: Text(context.l10n.navShipments),
            onTap: () => _go(context, ShipmentsListView.route()),
          ),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: Text(context.l10n.navTransfers),
          onTap: () => _go(context, TransfersListView.route()),
        ),
        if (coordinates)
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(context.l10n.navRiskReviews),
            onTap: () => _go(context, RiskReviewsView.route()),
          ),
        if (coordinates)
          ListTile(
            leading: const Icon(Icons.report_gmailerrorred_outlined),
            title: Text(context.l10n.incidentsTitle),
            onTap: () => _go(context, IncidentsListView.route()),
          ),
        if (ref.watch(canReviewApplicationsProvider))
          ListTile(
            leading: const Icon(Icons.inbox_outlined),
            title: Text(context.l10n.applicationsTitle),
            onTap: () => _go(context, ApplicationQueueView.route()),
          ),
        if (ref.watch(canListCentersProvider))
          ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: Text(context.l10n.centersTitle),
            onTap: () => _go(context, CentersListView.route()),
          ),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(context.l10n.navTeam),
          onTap: () => _go(context, TeamDirectoryView.route()),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(context.l10n.navSignOut),
          onTap: () {
            Navigator.of(context).pop();
            ref.read(sessionControllerProvider.notifier).logOut();
          },
        ),
      ],
    );
  }
}
