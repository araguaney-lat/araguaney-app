import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';
import 'center_form_view.dart';
import 'center_record_view.dart';

/// Los centros de la plataforma.
///
/// Solo la ve quien puede listarlos, y por eso la entrada del menú tampoco
/// aparece para los demás: ofrecer una pantalla que va a responder 403 es peor
/// que no ofrecerla.
class CentersListView extends ConsumerWidget {
  const CentersListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CentersListView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.centersCentros)),
      floatingActionButton: ref.watch(canListCentersProvider)
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).push(CenterFormView.route()),
              tooltip: context.l10n.centersNuevoCentro,
              child: const Icon(Icons.add),
            )
          : null,
      body: switch (centers) {
        AsyncData(value: CentersRead(:final value)) when value.isEmpty =>
          const _Message('No hay centros registrados todavía.'),
        AsyncData(value: CentersRead(:final value)) => _List(centers: value),
        AsyncData(value: CentersRefused(:final isForbidden, :final failure)) =>
          _Message(
            isForbidden
                ? 'Solo la administración nacional puede ver los centros.'
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.centers});

  final List<CenterOut> centers;

  @override
  Widget build(BuildContext context) {
    // Los desactivados van al final: siguen existiendo y casi nunca son lo que
    // alguien viene a buscar.
    final sorted = [...centers]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final center = sorted[index];
        final place = [
          center.stateName,
          center.countryCode,
        ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

        return ListTile(
          title: Text(center.name),
          subtitle: place.isEmpty ? null : Text(place),
          trailing: center.isActive
              ? null
              : Chip(label: Text(context.l10n.centersDesactivado)),
          onTap: () =>
              Navigator.of(context).push(CenterRecordView.route(center.id)),
        );
      },
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
