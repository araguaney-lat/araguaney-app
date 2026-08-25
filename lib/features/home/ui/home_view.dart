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

/// El destino «Inicio» de la barra inferior.
///
/// Dos pantallas, no una: quien coordina llega a decidir sobre lo que otra
/// persona capturó, y quien es voluntariado llega a capturar. Mostrarles lo
/// mismo obliga a las dos a buscar lo suyo entre lo ajeno.
///
/// Lo que ordena ambas es la misma regla: arriba va lo que espera una decisión
/// o se puede perder, y después lo que solo se consulta. Un número que nadie
/// va a mirar no gana un sitio por ser fácil de calcular.
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

/// Lo único que se puede perder: capturas que no salieron.
///
/// Va primero y no se puede cerrar. Una captura en cola no es un aviso, es
/// trabajo hecho que todavía no existe para nadie más.
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

/// Lo que espera una decisión de coordinación.
///
/// El aviso no dice por qué se levantó la revisión: eso se lee dentro, y en una
/// pantalla de inicio que alguien puede mirar por encima del hombro no tiene
/// nada que hacer.
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

/// La jornada de quien captura.
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

/// Lo que coordina alguien que no captura.
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

/// El peso sellado del centro.
///
/// Es lo que el servidor agrega para este centro: cajas selladas. Se dice
/// «sellado» y no «total» porque lo capturado sin sellar no pesa aquí, y quien
/// prepare un envío con este número tiene que saberlo.
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

/// Cuánto aguanta el dispositivo sin señal.
///
/// Las dos cifras que deciden si se puede trabajar en un sótano: catálogo
/// descargado y códigos de caja reservados. Sin códigos no se sella nada, y eso
/// se descubre en el peor momento si no se dice antes.
class _OfflineReadiness extends ConsumerWidget {
  const _OfflineReadiness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(offlineReadinessProvider);

    // Se toca para llegar a donde se reponen los códigos. Decir «sin códigos
    // no vas a poder sellar» sin ofrecer el camino para arreglarlo dejaba el
    // aviso siendo solo un reproche: reservar solo estaba dentro de la
    // pantalla de pendientes, y esa solo aparecía si ya había algo en la cola
    // — es decir, nunca antes de bajar al sótano, que es el único momento en
    // que reservar sirve de algo.
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

/// El nombre con el árbol delante.
///
/// Solo aquí. En las demás pantallas el título dice qué se está haciendo
/// —«Cajas», «Registrar entrada»— y anteponerle una marca lo convertiría en
/// decoración repetida; el inicio es la única pantalla cuyo título es el
/// nombre de la aplicación.
///
/// El activo es un archivo aparte y pequeño: el del splash mide más de medio
/// mega porque se dibuja a pantalla completa, y decodificarlo entero para
/// veintiocho píxeles en cada arranque sería caro en el tipo de teléfono al
/// que va esto.
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
        // El alto es el que manda: el árbol es más ancho que alto y dejarlo
        // ajustarse solo lo dejaría más bajo que el texto.
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
