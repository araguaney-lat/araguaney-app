import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';
import 'center_form_view.dart';

/// La ficha de un centro.
///
/// **No es administración.** Los tres casos que la justifican son estrechos y
/// se parecen entre sí: confirmar a qué centro va una transferencia, encontrar
/// un contacto cuando un envío se perdió, y ver que un centro recién aprobado
/// existe. Los tres empiezan lejos de un escritorio.
///
/// Configurar un centro es del panel, y por eso aquí no hay nada que escribir.
class CenterRecordView extends ConsumerWidget {
  const CenterRecordView({super.key, required this.centerId});

  final String centerId;

  static Route<void> route(String centerId) => MaterialPageRoute<void>(
    builder: (_) => CenterRecordView(centerId: centerId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(centerRecordProvider(centerId));

    final editable = switch (center) {
      AsyncData(value: CentersRead(:final value)) => value,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.centerLabel),
        actions: [
          if (editable != null)
            IconButton(
              onPressed: () => Navigator.of(
                context,
              ).push(CenterFormView.route(existing: editable)),
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.centerEditAction,
            ),
        ],
      ),
      body: switch (center) {
        AsyncData(value: CentersRead(:final value)) => _Body(center: value),
        AsyncData(value: CentersRefused(:final isForbidden, :final failure)) =>
          _Message(
            isForbidden
                ? 'Solo la administración nacional puede ver la ficha de un '
                      'centro.'
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.center});

  final CenterOut center;

  @override
  Widget build(BuildContext context) {
    // El modelo generado trae estos campos anulables aunque el contrato los
    // liste como requeridos, así que se omite lo que no venga en vez de pintar
    // una etiqueta sobre nada. Es la misma regla que las demás fichas: el
    // cliente no rellena un silencio.
    final place = [
      center.stateName,
      center.countryCode,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(center.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        // La razón social solo aparece cuando difiere del nombre de uso:
        // repetirlo dos veces no informa de nada.
        if (center.legalName case final legal?
            when legal.isNotEmpty && legal != center.name)
          RecordField(label: context.l10n.centerLegalNameLabel, value: legal),
        if (place.isNotEmpty)
          RecordField(label: context.l10n.centerPlaceLabel, value: place),
        if (center.address case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.addressLabel, value: value),
        if (center.contactName case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.contactLabel, value: value),
        if (center.contactEmail case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.emailLabel, value: value),
        if (center.contactPhone case final value? when value.isNotEmpty)
          RecordField(label: context.l10n.phoneLabel, value: value),
        if (!center.isActive)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(context.l10n.centerInactiveNotice),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    child: Text(text, textAlign: TextAlign.center),
  );
}
