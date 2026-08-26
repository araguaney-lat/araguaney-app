import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/working_center_banner.dart';
import '../../dashboard/data/center_dashboard_providers.dart';
import '../../dashboard/ui/stock_by_category_view.dart';
import '../../intake/data/intake_providers.dart';
import '../../intake/ui/intake_list_view.dart';
import '../../intake/ui/pending_captures_view.dart';
import '../../pallets/ui/pallets_list_view.dart';
import '../../risk_reviews/ui/risk_reviews_view.dart';
import '../data/home_providers.dart';
import 'push_permission_card.dart';

/// The bottom bar's «Inicio» destination.
///
/// Two screens, not one: whoever coordinates comes to decide about what
/// somebody else captured, and whoever volunteers comes to capture. Showing
/// them the same thing forces both to hunt for theirs among the other's.
///
/// What orders both is the same rule: at the top goes what is waiting for a
/// decision or can be lost, and after it what is only consulted. A number
/// nobody is going to look at does not earn a place by being easy to compute.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static String _roleLabel(AppLocalizations l10n, String role) =>
      switch (role) {
        'volunteer' => l10n.roleVolunteerLabel,
        'coordinator' => l10n.roleCoordinatorLabel,
        'national_admin' => l10n.roleNationalAdminLabel,
        _ => role,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sessionControllerProvider);
    final session = state is SessionActive ? state.session : null;
    final coordinates = ref.watch(isCenterCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(title: _Wordmark(l10n.appTitle)),
      body: Column(
        children: [
          const WorkingCenterBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(centerAggregatesProvider)
                  ..invalidate(intakesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (session?.centerRole case final role?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _roleLabel(context.l10n, role),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  const PushPermissionCard(),
                  const _PendingCaptures(),
                  if (coordinates) const _PendingReviews(),
                  const SizedBox(height: 8),
                  if (coordinates)
                    const _CoordinatorGrid()
                  else
                    const _DayGrid(),
                  const SizedBox(height: 8),
                  const _CenterWeight(),
                  const _OfflineReadiness(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The only thing that can be lost: captures that did not go out.
///
/// It comes first and cannot be dismissed. A queued capture is not a notice, it
/// is work done that does not exist yet for anybody else.
class _PendingCaptures extends ConsumerWidget {
  const _PendingCaptures();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCaptureCountProvider).valueOrNull ?? 0;
    if (pending == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.cloud_upload_outlined),
        title: Text(context.l10n.homePendingCaptures(pending)),
        subtitle: Text(context.l10n.homeKeepAppOpenWhileSending),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(PendingCapturesView.route()),
      ),
    );
  }
}

/// What is waiting for a coordination decision.
///
/// The notice does not say why the review was raised: that is read inside, and
/// on a home screen somebody may glance at over a shoulder it has no business
/// being.
class _PendingReviews extends ConsumerWidget {
  const _PendingReviews();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingReviewCountProvider);
    if (pending == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text(context.l10n.homePendingReviews(pending)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(RiskReviewsView.route()),
      ),
    );
  }
}

/// The shift of whoever captures.
class _DayGrid extends ConsumerWidget {
  const _DayGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Grid(
    children: [
      _Tile(
        label: context.l10n.homeCapturesToday,
        value: '${ref.watch(todaysIntakeCountProvider)}',
        onTap: () => Navigator.of(context).push(IntakeListView.route()),
      ),
      _Tile(
        label: context.l10n.homeCenterStock,
        caption: context.l10n.byCategoryCaption,
        onTap: () => Navigator.of(context).push(StockByCategoryView.route()),
      ),
    ],
  );
}

/// What somebody who does not capture coordinates.
class _CoordinatorGrid extends ConsumerWidget {
  const _CoordinatorGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Grid(
    children: [
      _Tile(
        label: context.l10n.homeCapturesToday,
        value: '${ref.watch(todaysIntakeCountProvider)}',
        onTap: () => Navigator.of(context).push(IntakeListView.route()),
      ),
      _Tile(
        label: context.l10n.homeOpenPallets,
        value: '${ref.watch(openPalletCountProvider)}',
        onTap: () => Navigator.of(context).push(PalletsListView.route()),
      ),
      _Tile(
        label: context.l10n.homeCenterStock,
        caption: context.l10n.byCategoryCaption,
        onTap: () => Navigator.of(context).push(StockByCategoryView.route()),
      ),
    ],
  );
}

/// The centre's sealed weight.
///
/// It is what the server aggregates for this centre: sealed boxes. It says
/// «sealed» and not «total» because what was captured without being sealed does
/// not weigh here, and whoever prepares a shipment with this number has to know
/// that.
class _CenterWeight extends ConsumerWidget {
  const _CenterWeight();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(centerAggregatesProvider).valueOrNull?.totals;
    if (totals == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.scale_outlined),
        title: Text(context.l10n.homeSealedWeight('${totals.totalWeightKg}')),
        subtitle: Text(
          context.l10n.homeSealedCounts(
            totals.totalBoxesSealed,
            totals.totalUnitsSealed,
          ),
        ),
      ),
    );
  }
}

/// How long the device holds out without signal.
///
/// The two figures that decide whether work in a basement is possible: the
/// downloaded catalogue and the reserved box codes. With no codes nothing gets
/// sealed, and that is discovered at the worst moment if it is not said
/// beforehand.
class _OfflineReadiness extends ConsumerWidget {
  const _OfflineReadiness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(offlineReadinessProvider);

    // It is tapped to reach where the codes are topped up. Saying «with no
    // codes you will not be able to seal» without offering the road to fix it
    // left the notice as nothing but a reproach: reserving lived only inside
    // the pending screen, and that only appeared if there was already something
    // in the queue — that is, never before going down to the basement, which is
    // the only moment reserving is any use.
    return InkWell(
      onTap: () => Navigator.of(context).push(PendingCapturesView.route()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ready.codes == 0
                    ? context.l10n.offlineReadyWithoutCodes(ready.products)
                    : context.l10n.offlineReady(ready.products, ready.codes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

/// The name with the tree in front.
///
/// Only here. On the other screens the title says what is being done —
/// «Cajas», «Registrar entrada» — and putting a brand in front of it would turn
/// it into repeated decoration; home is the only screen whose title is the
/// application's name.
///
/// The asset is a separate, small file: the splash's weighs more than half a
/// megabyte because it is drawn full screen, and decoding all of it for
/// twenty-eight pixels at every launch would be expensive on the kind of phone
/// this is meant for.
class _Wordmark extends StatelessWidget {
  const _Wordmark(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/icon/ic_mark.png',
        height: 30,
        // Height is what decides: the tree is wider than it is tall, and
        // letting it size itself would leave it shorter than the text.
        fit: BoxFit.fitHeight,
        filterQuality: FilterQuality.medium,
      ),
      const SizedBox(width: 10),
      Text(title),
    ],
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.7,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children: children,
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    this.value,
    this.caption,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            if (value case final number?)
              Text(number, style: Theme.of(context).textTheme.headlineSmall)
            else if (caption case final text?)
              Text(text, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
