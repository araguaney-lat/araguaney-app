import 'package:flutter/material.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/i18n/l10n_extension.dart';

/// Elegir a qué campaña se imputa la captura.
///
/// La campaña dejó de ser un campo del formulario para pasar a la cabecera:
/// no es un dato de la donación que se escribe cada vez, es el contexto en el
/// que se trabaja toda la jornada. Se elige una vez y se ve siempre.
class CampaignSheet extends StatelessWidget {
  const CampaignSheet({
    super.key,
    required this.campaigns,
    required this.selected,
  });

  final List<CampaignOut> campaigns;
  final String? selected;

  /// Devuelve `(id,)` con la elección, o nulo si se cerró sin elegir. El
  /// registro envuelve el identificador porque «sin campaña» es una elección
  /// válida y también es nula.
  static Future<({String? id})?> show(
    BuildContext context, {
    required List<CampaignOut> campaigns,
    required String? selected,
  }) => showModalBottomSheet<({String? id})>(
    context: context,
    useSafeArea: true,
    builder: (_) => CampaignSheet(campaigns: campaigns, selected: selected),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            context.l10n.intakeCampana,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(context.l10n.intakeSinCampanaLaDonacionQueda),
        ),
        const Divider(),
        _Option(
          label: context.l10n.intakeCampanaGeneral,
          value: null,
          selected: selected,
        ),
        for (final campaign in campaigns)
          _Option(label: campaign.name, value: campaign.id, selected: selected),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final String? value;
  final String? selected;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: value == selected ? const Icon(Icons.check) : null,
    onTap: () => Navigator.of(context).pop((id: value)),
  );
}
