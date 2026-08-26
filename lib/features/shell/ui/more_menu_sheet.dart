import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../account/ui/profile_view.dart';
import '../../campaigns/data/campaigns_providers.dart';
import '../../campaigns/ui/campaigns_list_view.dart';
import '../../catalog/ui/catalog_list_view.dart';
import '../../center_applications/data/center_applications_providers.dart';
import '../../center_applications/ui/application_queue_view.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/ui/centers_list_view.dart';
import '../../centers/ui/choose_center_view.dart';
import '../../dashboard/ui/stock_by_category_view.dart';
import '../../donations/ui/donations_list_view.dart';
import '../../incidents/ui/incidents_list_view.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../intake/ui/pending_captures_view.dart';
import '../../pallets/ui/pallets_list_view.dart';
import '../../reports/ui/reports_view.dart';
import '../../risk_reviews/ui/risk_reviews_view.dart';
import '../../shipments/ui/shipments_list_view.dart';
import '../../team/ui/team_directory_view.dart';
import '../../transfers/ui/transfers_list_view.dart';
import '../../users/data/users_providers.dart';
import '../../users/ui/users_list_view.dart';

/// Todo lo que no cabe en la barra.
///
/// Se abre desde el cuarto destino. Lo que entra aquí es lo que se consulta
/// cada varios días —tarimas, transferencias, el equipo— frente a lo que se
/// toca cada pocos minutos, que es lo que gana un sitio en la barra.
///
/// **Va en grupos porque dejó de caber.** Con dieciséis entradas seguidas hasta
/// una prueba tuvo que empezar a desplazarse para encontrar una, y una lista
/// larga sin agrupar se lee peor que la misma lista repartida: «Perfil» y
/// «Cerrar sesión» son la cuenta y estaban en extremos opuestos.
///
/// Los grupos son por **quién hace ese trabajo y dónde**: la jornada de quien
/// captura, lo que se coordina en el centro, y lo que se administra —que casi
/// siempre se hace desde un escritorio y va al final por eso—. Un grupo sin
/// entradas no se dibuja, así que quien es voluntariado ve dos.
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
    final reviewsApplications = ref.watch(canReviewApplicationsProvider);
    final listsCenters = ref.watch(canListCentersProvider);

    return ListView(
      padding: EdgeInsets.only(bottom: sheetBottomInset(context, base: 8)),
      shrinkWrap: true,
      children: [
        // El centro de trabajo va antes que cualquier grupo y sin encabezado:
        // no es un destino, es en dónde está escribiendo quien mira el menú.
        if (ref.watch(workingCenterProvider).valueOrNull case final center?)
          if (ref.watch(writeCenterIdProvider) != null)
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: Text(context.l10n.workingCenterTitle),
              subtitle: Text(center.name),
              trailing: Text(context.l10n.workingCenterChangeAction),
              onTap: () => _go(context, ChooseCenterView.route()),
            ),
        _Section(
          title: context.l10n.menuSectionDay,
          children: [
            // Siempre, no solo con la cola llena: aquí se reponen los códigos
            // de caja, y hacerlo hace falta **antes** de quedarse sin señal.
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
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(context.l10n.navCaptures),
              onTap: () => _go(context, IntakeListView.route()),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(context.l10n.donationsTitle),
              onTap: () => _go(context, DonationsListView.route()),
            ),
            // Para todo el mundo: buscar un producto es de quien captura, y
            // dar de alta uno es lo único que la pantalla reserva por rol.
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: Text(context.l10n.catalogTitle),
              onTap: () => _go(context, CatalogListView.route()),
            ),
          ],
        ),
        _Section(
          title: context.l10n.menuSectionCenter,
          children: [
            ListTile(
              leading: const Icon(Icons.donut_small_outlined),
              title: Text(context.l10n.stockByCategoryTitle),
              onTap: () => _go(context, StockByCategoryView.route()),
            ),
            // Va junto al stock porque es la pregunta siguiente: el stock dice
            // qué hay, el informe dice cómo va.
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(context.l10n.reportsTitle),
              onTap: () => _go(context, ReportsView.route()),
            ),
            if (ref.watch(canBrowseCampaignsProvider))
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text(context.l10n.campaignsTitle),
                onTap: () => _go(context, CampaignsListView.route()),
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
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(context.l10n.navTeam),
              onTap: () => _go(context, TeamDirectoryView.route()),
            ),
          ],
        ),
        // Trabajo de escritorio, y por eso va al final: se puede hacer desde
        // aquí, pero casi nadie lo hace con el teléfono en la mano.
        _Section(
          title: context.l10n.menuSectionAdmin,
          children: [
            if (reviewsApplications)
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: Text(context.l10n.applicationsTitle),
                onTap: () => _go(context, ApplicationQueueView.route()),
              ),
            if (listsCenters)
              ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(context.l10n.centersTitle),
                onTap: () => _go(context, CentersListView.route()),
              ),
            if (ref.watch(canManageUsersProvider))
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(context.l10n.usersTitle),
                onTap: () => _go(context, UsersListView.route()),
              ),
          ],
        ),
        _Section(
          title: context.l10n.menuSectionAccount,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(context.l10n.profileTitle),
              onTap: () => _go(context, ProfileView.route()),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.l10n.navSignOut),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(sessionControllerProvider.notifier).logOut();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Un grupo del menú, que desaparece entero cuando el rol lo deja vacío.
///
/// Es lo que hace que agrupar no le cueste nada a quien es voluntariado: sin
/// esto, «Administración» sería un encabezado con nada debajo, que es peor que
/// no agrupar.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
