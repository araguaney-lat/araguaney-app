import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/intake_providers.dart';
import 'intake_detail_view.dart';
import 'intake_form_view.dart';

/// The centre's registered captures.
///
/// It is looked up online. The read the operation needs without signal is the
/// inventory's — catalogue and boxes — not the history's: nobody decides what
/// to do with a box by looking at the capture that created it.
class IntakeListView extends ConsumerWidget {
  const IntakeListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const IntakeListView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakes = ref.watch(intakesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.capturesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(IntakeFormView.route());
          ref.invalidate(intakesProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.captureNewAction),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(intakesProvider),
        child: switch (intakes) {
          AsyncData(:final value) when value.isEmpty => _Message(
            context.l10n.capturesEmpty,
          ),
          AsyncData(:final value) => _IntakeList(intakes: value),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
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
      // `GET /v1/intakes` does not bring the boxes: the schema declares them
      // with an empty list by default and the server does not fill them in when
      // listing. Counting that list gave «0 cajas» on every row, which is not a
      // missing figure but a false one. Until request 2 exists nothing is
      // counted.
      final parts = [
        if (boxes > 0) context.l10n.boxCount(boxes),
        ?donorLabel(intake),
      ];

      return ListTile(
        title: Text(formatShortDate(intake.createdAt)),
        subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
        onTap: () => Navigator.of(context).push(IntakeDetailView.route(intake)),
      );
    },
  );
}

/// How the donor is named, with whatever there is: the registered donor, the
/// loose name that was typed, or nothing.
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
