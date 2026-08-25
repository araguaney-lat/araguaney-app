import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/category_stock_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../data/center_dashboard_providers.dart';

/// Lo que el centro tiene sellado, por categoría.
///
/// Sustituye a la pantalla anterior, que contaba lo capturado en una ventana de
/// treinta días sin mirar el estado de la caja. Esta cuenta cajas **selladas**,
/// que es lo que de verdad se puede enviar, y por eso puede llamarse stock sin
/// mentir.
class StockByCategoryView extends ConsumerWidget {
  const StockByCategoryView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const StockByCategoryView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregates = ref.watch(centerAggregatesProvider);
    // El mismo endpoint responde el centro propio o todos según el rol, así que
    // la pantalla tiene que decir de qué está hablando.
    final national = ref.watch(isNationalAdminProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.stockByCategoryTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(centerAggregatesProvider),
        child: switch (aggregates) {
          AsyncData(:final value) when value.byCategory.isEmpty => _Message(
            context.l10n.stockEmpty,
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.byCategory.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => index == 0
                ? _Scope(national: national)
                : _Row(row: value.byCategory[index - 1]),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Scope extends StatelessWidget {
  const _Scope({required this.national});

  final bool national;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Text(
      national
          ? context.l10n.stockNationalCaption
          : context.l10n.stockCenterCaption,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final CategoryStockOut row;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(categoryLabel(context.l10n, row.category)),
    subtitle: Text('${row.boxCount} cajas'),
    trailing: Text(
      '${row.totalUnits}',
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
