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
import '../../requests/ui/requests_list_view.dart';
import '../../risk_reviews/ui/risk_reviews_view.dart';
import '../../shipments/ui/shipments_list_view.dart';
import '../../team/ui/team_directory_view.dart';
import '../../transfers/ui/transfers_list_view.dart';
import '../../users/data/users_providers.dart';
import '../../users/ui/users_list_view.dart';

/// Everything that does not fit on the bar.
///
/// It opens from the fourth destination. What goes in here is what is consulted
/// every few days — pallets, transfers, the team — as against what is touched
/// every few minutes, which is what earns a place on the bar.
///
/// **It comes in groups because it stopped fitting.** With sixteen entries in a
/// row even a test had to start scrolling to find one, and a long ungrouped
/// list reads worse than the same list split up: «Perfil» and «Cerrar sesión»
/// are the account and sat at opposite ends.
///
/// The groups are by **who does that work and where**: the shift of whoever
/// captures, what is coordinated in the centre, and what is administered —
/// which is almost always done from a desk and goes last for that reason. A
/// group with no entries is not drawn, so whoever volunteers sees two.
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  /// `isScrollControlled` because the menu grew: without it the sheet stops at
  /// a little over half the screen and the last entries end up below the fold,
  /// which in a menu is the same as not existing. With it the sheet fits its
  /// content, and the `ConstrainedBox` keeps it from covering the whole screen
  /// as the list goes on growing.
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
        // The working centre goes before any group and with no header: it is
        // not a destination, it is where whoever is looking at the menu is
        // writing.
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
            // Always, and not only with a full queue: this is where box codes
            // are topped up, and that has to be done **before** running out of
            // signal.
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
            // For everybody: looking a product up belongs to whoever captures,
            // and adding one is the only thing the screen reserves by role.
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
            // Right after the stock, and for everybody: the stock says what
            // there is, and this is where somebody says what is missing. The
            // backend asks for a session and nothing else — only moving a
            // request's state is gated, and that lives inside the record.
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(context.l10n.requestsTitle),
              onTap: () => _go(context, RequestsListView.route()),
            ),
            // Next to the stock because it is the following question: the
            // stock says what there is, the report says how it is going.
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
        // Desk work, and that is why it goes last: it can be done from here,
        // but almost nobody does it with the phone in their hand.
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

/// A group of the menu, which disappears entirely when the role leaves it
/// empty.
///
/// It is what makes grouping cost whoever volunteers nothing: without it,
/// «Administración» would be a header with nothing under it, which is worse
/// than not grouping.
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
