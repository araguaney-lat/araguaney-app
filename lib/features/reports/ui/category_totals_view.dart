import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/category_breakdown.dart';
import '../../intake/data/intake_providers.dart';
import '../data/reports_providers.dart';

/// Cómo se lee una categoría del catálogo.
///
/// El backend las nombra en mayúsculas y en inglés porque son claves de
/// `PRODUCT_CATEGORIES`, no texto; quien opera lee otra cosa. Los ocho valores
/// se leyeron del modelo del backend después de que la pantalla mostrara
/// `MEDICAL_SUPPLY` en producción: la primera versión de esta tabla estaba
/// inventada y el respaldo la tapó sin que fallara nada. Una categoría que esta versión no conozca se muestra
/// tal cual: el catálogo puede crecer y un binario viejo no puede esconder una
/// fila entera por no reconocer su nombre.
String categoryLabel(String category) => switch (category) {
  'MEDICINE' => 'Medicamentos',
  'MEDICAL_SUPPLY' => 'Insumo médico',
  'FOOD' => 'Alimentos',
  'WATER' => 'Agua',
  'HYGIENE' => 'Higiene',
  'TOOL' => 'Herramientas',
  'RESCUE_GEAR' => 'Equipo de rescate',
  'OTHER' => 'Otros',
  _ => category,
};

/// Lo capturado por categoría en el centro de quien mira.
///
/// **No dice stock, y el título lo deja claro.** El servidor cuenta cajas
/// creadas dentro de su ventana, sin mirar el estado: lo que ya salió en un
/// envío sigue contando. Llamar «stock» a este número sería cómodo y falso, y
/// alguien tomaría una decisión de reposición con él.
class CategoryTotalsView extends ConsumerStatefulWidget {
  const CategoryTotalsView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CategoryTotalsView());

  @override
  ConsumerState<CategoryTotalsView> createState() => _CategoryTotalsViewState();
}

class _CategoryTotalsViewState extends ConsumerState<CategoryTotalsView> {
  String? _campaignId;

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(myCampaignsProvider).valueOrNull ?? const [];
    final selected = _resolve(campaigns);

    return Scaffold(
      appBar: AppBar(title: const Text('Capturado por categoría')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: selected?.id,
              decoration: const InputDecoration(labelText: 'Campaña'),
              items: [
                for (final campaign in campaigns)
                  DropdownMenuItem(
                    value: campaign.id,
                    child: Text(campaign.name),
                  ),
              ],
              onChanged: (value) => setState(() => _campaignId = value),
            ),
          ),
          if (selected == null)
            const Expanded(
              child: _Message(
                'No participas en ninguna campaña, así que no hay nada que '
                'contar todavía.',
              ),
            )
          else
            Expanded(child: _Totals(campaignId: selected.id)),
        ],
      ),
    );
  }

  /// La campaña elegida, o la primera que haya.
  ///
  /// Entrar y encontrar un desplegable vacío obliga a un toque para ver algo;
  /// la primera campaña es una respuesta tan buena como cualquiera y se puede
  /// cambiar.
  CampaignOut? _resolve(List<CampaignOut> campaigns) {
    for (final campaign in campaigns) {
      if (campaign.id == _campaignId) return campaign;
    }
    return campaigns.isEmpty ? null : campaigns.first;
  }
}

class _Totals extends ConsumerWidget {
  const _Totals({required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsProvider(campaignId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(categoryTotalsProvider(campaignId)),
      child: switch (totals) {
        AsyncData(:final value) when value.isEmpty => const _Message(
          'Este centro no capturó nada en esta campaña durante los últimos 30 '
          'días.',
        ),
        AsyncData(:final value) => ListView.separated(
          itemCount: value.length + 1,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              index == 0 ? const _Period() : _Row(row: value[index - 1]),
        ),
        AsyncError(:final error) => _Message(
          ApiErrorMapper.fromAny(error).operatorMessage,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Qué período cubre el número, y qué no es.
///
/// Va arriba y no en un pie: un número sin período se lee como un acumulado, y
/// quien reponga inventario con esta pantalla tiene que saber antes de mirarla
/// que lo despachado también cuenta.
class _Period extends StatelessWidget {
  const _Period();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Text(
      'Cajas registradas en los últimos 30 días por este centro. Incluye las '
      'que ya salieron en un envío: no es lo que hay en bodega ahora.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final CategoryBreakdown row;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(categoryLabel(row.category)),
    subtitle: Text('${row.boxCount} cajas'),
    trailing: Text(
      '${row.unitCount}',
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
