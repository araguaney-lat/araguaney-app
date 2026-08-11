import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/ui/record_field.dart';
import '../data/intake_providers.dart';
import 'intake_detail_view.dart';
import 'intake_form_view.dart';

/// Las capturas registradas del centro.
///
/// Se consulta en línea. La lectura que la operación necesita sin señal es la
/// del inventario —catálogo y cajas—, no la del historial: nadie decide qué
/// hacer con una caja mirando la captura que la creó.
class IntakeListView extends ConsumerWidget {
  const IntakeListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const IntakeListView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakes = ref.watch(intakesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Capturas del centro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(IntakeFormView.route());
          ref.invalidate(intakesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva captura'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(intakesProvider),
        child: switch (intakes) {
          AsyncData(:final value) when value.isEmpty => const _Message(
            'Este centro todavía no registró ninguna captura.',
          ),
          AsyncData(:final value) => _IntakeList(intakes: value),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _IntakeList extends StatelessWidget {
  const _IntakeList({required this.intakes});

  final List<IntakeOut> intakes;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: intakes.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final intake = intakes[index];
      final boxes = intake.boxes.length;

      return ListTile(
        title: Text(formatShortDate(intake.createdAt)),
        subtitle: Text(
          [
            '$boxes ${boxes == 1 ? 'caja' : 'cajas'}',
            ?donorLabel(intake),
          ].join(' · '),
        ),
        onTap: () => Navigator.of(context).push(IntakeDetailView.route(intake)),
      );
    },
  );
}

/// Cómo se nombra a quien donó, con lo que haya: el donante registrado, el
/// nombre suelto que se escribió, o nada.
String? donorLabel(IntakeOut intake) {
  if (intake.donor case final donor?) {
    return donor.legalName ?? '${donor.firstName} ${donor.lastName}';
  }
  return intake.donanteLibre;
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
