import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export_job.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/report_summary.dart';
import '../../../core/api/generated/models/shrinkage_summary.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/platform/open_link.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../intake/data/intake_providers.dart';
import '../data/reports_providers.dart';
import '../data/reports_repository.dart';

/// Cómo va la campaña, en una pantalla.
///
/// **No es el informe del panel hecho estrecho.** Un teléfono que enseña doce
/// columnas no enseña ninguna, así que aquí van los números sobre los que
/// alguien hace algo, en el orden de las dos preguntas que una coordinación le
/// hace a un teléfono: «¿nos falta algo?» y «¿llegó lo que mandamos?».
///
/// La hoja de cálculo no se dibuja: se le pide al servidor y se le entrega al
/// visor del sistema, igual que un manifiesto.
class ReportsView extends ConsumerWidget {
  const ReportsView({super.key, this.campaignId});

  /// La campaña con la que abrir. Se usa al llegar desde la recepción de un
  /// envío, que ya sabe de cuál es la merma que alguien fue a buscar.
  final String? campaignId;

  static Route<void> route({String? campaignId}) => MaterialPageRoute<void>(
    builder: (_) => ReportsView(campaignId: campaignId),
  );

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String campaign,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)
      ..showSnackBar(SnackBar(content: Text(l10n.exportPreparing)));

    final outcome = await ref
        .read(reportsRepositoryProvider)
        .exportCsv(campaign);
    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();
    switch (outcome) {
      case DocumentReady(:final downloadUrl):
        final opened = await ref.read(openLinkProvider)(downloadUrl);
        if (!opened) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.manifestOpenFailed)),
          );
        }
      case DocumentStillWorking():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.manifestStillWorking)),
        );
      case DocumentFailed(:final failure, :final serverError):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure?.operatorMessage(l10n) ??
                  serverError ??
                  l10n.manifestFailed,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(myCampaignsProvider).valueOrNull ?? const [];
    final selected =
        ref.watch(selectedCampaignProvider) ??
        campaignId ??
        (campaigns.isEmpty ? null : campaigns.first.id);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reportsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          if (selected == null) return;
          ref
            ..invalidate(reportSummaryProvider(selected))
            ..invalidate(reportShrinkageProvider(selected))
            ..invalidate(reportByCategoryProvider(selected))
            ..invalidate(reportCountriesProvider(selected))
            ..invalidate(reportActivityProvider(selected))
            ..invalidate(reportWeightProvider(selected));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (campaigns.isEmpty)
              Text(context.l10n.reportsNoCampaigns)
            else
              _CampaignPicker(campaigns: campaigns, selected: selected),
            if (selected case final campaign?) ...[
              const SizedBox(height: 16),
              _Weight(campaignId: campaign),
              const SizedBox(height: 8),
              _Summary(campaignId: campaign),
              const SizedBox(height: 16),
              _Shrinkage(campaignId: campaign),
              const SizedBox(height: 16),
              _ByCategory(campaignId: campaign),
              const SizedBox(height: 16),
              _Countries(campaignId: campaign),
              const SizedBox(height: 16),
              _Activity(campaignId: campaign),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _export(context, ref, campaign),
                icon: const Icon(Icons.table_view_outlined),
                label: Text(context.l10n.reportsExportAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CampaignPicker extends ConsumerWidget {
  const _CampaignPicker({required this.campaigns, required this.selected});

  final List<CampaignOut> campaigns;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: InputDecoration(labelText: context.l10n.campaignLabel),
        items: [
          for (final campaign in campaigns)
            DropdownMenuItem(value: campaign.id, child: Text(campaign.name)),
        ],
        onChanged: (value) =>
            ref.read(selectedCampaignProvider.notifier).state = value,
      );
}

/// El peso reunido y, si la campaña puso una meta, cuánto falta.
class _Weight extends ConsumerWidget {
  const _Weight({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = switch (ref.watch(reportWeightProvider(campaignId))) {
      AsyncData(value: ReportRead(:final value)) => value,
      _ => null,
    };
    final campaign = weight?.campaigns
        .where((entry) => entry.campaignId == campaignId)
        .firstOrNull;
    if (campaign == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.scale_outlined),
        title: Text(context.l10n.reportsWeightCollected('${campaign.totalKg}')),
        subtitle: switch ((campaign.goalKg, campaign.progressPct)) {
          (final goal?, final pct?) => Text(
            context.l10n.reportsWeightGoal('$goal', pct.round()),
          ),
          _ => null,
        },
      ),
    );
  }
}

/// Los números que se miran primero.
///
/// Diez llegan del servidor y aquí van seis: las cajas por estado, lo capturado
/// y lo enviado. Los otros cuatro —centros activos, unidades, tasa de
/// rechazo— o los responde otra sección o son del país, y una rejilla de diez
/// celdas en un teléfono es una rejilla que nadie lee.
class _Summary extends ConsumerWidget {
  const _Summary({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(reportSummaryProvider(campaignId))) {
        AsyncData(value: ReportRead(:final value)) => _Numbers(summary: value),
        AsyncData(value: ReportRefused(:final isForbidden, :final failure)) =>
          _Note(
            isForbidden
                ? context.l10n.reportsForbidden
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Note('$error'),
        _ => const _Loading(),
      };
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.15,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children: [
      _Cell(label: context.l10n.reportsBoxes, value: summary.totalBoxes),
      _Cell(label: context.l10n.reportsSealed, value: summary.sealedBoxes),
      _Cell(label: context.l10n.reportsShipped, value: summary.shippedBoxes),
      _Cell(label: context.l10n.reportsDraft, value: summary.draftBoxes),
      _Cell(label: context.l10n.reportsRejected, value: summary.rejectedBoxes),
      _Cell(label: context.l10n.reportsIntakes, value: summary.totalIntakes),
    ],
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    ),
  );
}

/// La diferencia entre lo que salió y lo que llegó.
///
/// Es el informe que se gana el sitio en un teléfono: quien lo necesita está
/// delante de las cajas que no cuadran.
class _Shrinkage extends ConsumerWidget {
  const _Shrinkage({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shrinkage = ref.watch(reportShrinkageProvider(campaignId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reportsShrinkageTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        switch (shrinkage) {
          AsyncData(value: ReportRead(:final value))
              when value.reconciledBoxes == 0 =>
            _Note(context.l10n.reportsNothingReconciled),
          AsyncData(value: ReportRead(:final value)) => _ShrinkageFigures(
            shrinkage: value,
          ),
          AsyncData(value: ReportRefused(:final failure)) => _Note(
            failure.operatorMessage(context.l10n),
          ),
          AsyncError(:final error) => _Note('$error'),
          _ => const _Loading(),
        },
      ],
    );
  }
}

class _ShrinkageFigures extends StatelessWidget {
  const _ShrinkageFigures({required this.shrinkage});

  final ShrinkageSummary shrinkage;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: shrinkage.shrinkagePct > 0 ? palette.noticeFill : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.reportsShrinkagePct(
                shrinkage.shrinkagePct.toStringAsFixed(1),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.reportsShrinkageOf(shrinkage.reconciledBoxes),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Pair(
                  label: context.l10n.reportsReceived,
                  value: shrinkage.received,
                ),
                _Pair(
                  label: context.l10n.reportsMissing,
                  value: shrinkage.missing,
                ),
                _Pair(
                  label: context.l10n.reportsDamaged,
                  value: shrinkage.damaged,
                ),
                _Pair(
                  label: context.l10n.reportsRetained,
                  value: shrinkage.retained,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) =>
      Text('$label: $value', style: Theme.of(context).textTheme.bodyMedium);
}

/// "¿Nos falta algo?", que se responde por categoría.
class _ByCategory extends ConsumerWidget {
  const _ByCategory({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.reportsByCategoryTitle,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      switch (ref.watch(reportByCategoryProvider(campaignId))) {
        AsyncData(value: ReportRead(:final value)) when value.isEmpty => _Note(
          context.l10n.reportsNothingYet,
        ),
        AsyncData(value: ReportRead(:final value)) => Column(
          children: [
            for (final row in value)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(categoryLabel(context.l10n, row.category)),
                subtitle: Text(context.l10n.boxCount(row.boxCount)),
                trailing: Text(
                  '${row.unitCount}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
        AsyncData(value: ReportRefused(:final failure)) => _Note(
          failure.operatorMessage(context.l10n),
        ),
        AsyncError(:final error) => _Note('$error'),
        _ => const _Loading(),
      },
    ],
  );
}

class _Countries extends ConsumerWidget {
  const _Countries({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = switch (ref.watch(reportCountriesProvider(campaignId))) {
      AsyncData(value: ReportRead(:final value)) => value,
      _ => null,
    };
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reportsCountriesTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final country in value)
          RecordField(
            label: country.countryCode,
            value: context.l10n.reportsCountryLine(
              country.boxCount,
              country.centerCount,
            ),
          ),
      ],
    );
  }
}

/// Los últimos días con movimiento.
///
/// **Se enseñan los siete más recientes y la pantalla lo dice.** Una serie
/// entera en un teléfono es una lista que se desplaza sola; recortarla en
/// silencio sería peor, porque parecería que no hubo más.
class _Activity extends ConsumerWidget {
  const _Activity({required this.campaignId});

  final String campaignId;

  static const _shown = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = switch (ref.watch(reportActivityProvider(campaignId))) {
      AsyncData(value: ReportRead(:final value)) => value,
      _ => null,
    };
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final recent = value.reversed.take(_shown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reportsActivityTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final point in recent)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(point.date),
            trailing: Text(context.l10n.boxCount(point.total)),
          ),
        if (value.length > _shown)
          Text(
            context.l10n.reportsActivityTruncated(value.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );
}
