import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/product_gtin_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/record_field.dart';
import '../data/catalog_providers.dart';
import '../data/catalog_repository.dart';
import 'product_form_view.dart';

/// La ficha de un producto del catálogo.
///
/// Se llega desde la búsqueda y desde un escaneo, y responde la pregunta que
/// se hace con el envase en la mano: si esto es lo que dice ser, y si el código
/// que acabo de leer apunta a donde debe.
class ProductRecordView extends ConsumerWidget {
  const ProductRecordView({super.key, required this.productId});

  final String productId;

  static Route<void> route(String productId) => MaterialPageRoute<void>(
    builder: (_) => ProductRecordView(productId: productId),
  );

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.productPromoteTitle),
        content: Text(context.l10n.productPromoteExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.productPromoteAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final outcome = await ref
        .read(catalogRepositoryProvider)
        .promote(productId);
    if (!context.mounted) return;

    switch (outcome) {
      case CatalogDone():
        ref.invalidate(productRecordProvider(productId));
      case CatalogRefused(:final failure):
        _say(context, failure.operatorMessage(context.l10n));
    }
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    ProductGtinOut gtin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.gtinUnlinkTitle),
        content: Text(context.l10n.gtinUnlinkExplanation(gtin.gtin)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.gtinUnlinkAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final outcome = await ref
        .read(catalogRepositoryProvider)
        .unlinkGtin(productId: productId, gtinId: gtin.id);
    if (!context.mounted) return;

    switch (outcome) {
      case CatalogDone():
        ref.invalidate(productGtinsProvider(productId));
      case CatalogRefused(:final failure):
        _say(context, failure.operatorMessage(context.l10n));
    }
  }

  static void _say(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(productRecordProvider(productId));
    final canEdit = ref.watch(canEditCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.productRecordTitle),
        actions: [
          if (canEdit)
            if (record.valueOrNull case CatalogDone(:final value))
              IconButton(
                tooltip: context.l10n.productEditTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).push(ProductFormView.route(existing: value));
                  ref.invalidate(productRecordProvider(productId));
                },
              ),
        ],
      ),
      body: switch (record) {
        AsyncData(value: CatalogDone(:final value)) => _Fields(
          product: value,
          canEdit: canEdit,
          onPromote: () => _promote(context, ref),
          onUnlink: (gtin) => _unlink(context, ref, gtin),
        ),
        AsyncData(value: CatalogRefused(:final failure)) => _Message(
          failure.operatorMessage(context.l10n),
        ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Fields extends ConsumerWidget {
  const _Fields({
    required this.product,
    required this.canEdit,
    required this.onPromote,
    required this.onUnlink,
  });

  final ProductTypeOut product;
  final bool canEdit;
  final VoidCallback onPromote;
  final ValueChanged<ProductGtinOut> onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El servidor promueve poniendo `campaign_id` en nulo: un producto sin
    // campaña es del catálogo de la plataforma, y uno con campaña es una
    // propuesta que todavía vive dentro de ella.
    final proposed = product.campaignId != null;

    return ListView(
      children: [
        RecordField(
          label: context.l10n.productLabel,
          value: product.displayName,
        ),
        RecordField(
          label: context.l10n.categoryFieldLabel,
          value: categoryLabel(context.l10n, product.category),
        ),
        if (product.defaultUnit case final unit?)
          RecordField(label: context.l10n.unitLabel, value: unit),
        if (product.brand case final brand?)
          RecordField(label: context.l10n.brandLabel, value: brand),
        if (product.form case final form?)
          RecordField(label: context.l10n.formLabel, value: form),
        if (product.strength case final strength?)
          RecordField(label: context.l10n.strengthLabel, value: strength),
        if (product.innName case final inn?)
          RecordField(label: context.l10n.innLabel, value: inn),
        if (product.unitWeightKg case final weight?)
          RecordField(label: context.l10n.unitWeightLabel, value: '$weight kg'),
        if (product.minShelfLifeDays case final days?)
          RecordField(
            label: context.l10n.minShelfLifeLabel,
            value: context.l10n.dayCount(days),
          ),
        if (product.isControlled)
          RecordField(
            label: context.l10n.controlledLabel,
            value: context.l10n.controlledYes,
          ),
        const Divider(),
        // Propuesto o aceptado: es lo que decide si alguien tiene que hacer
        // algo con esta ficha, así que va con su explicación y no como un
        // adjetivo suelto.
        ListTile(
          leading: Icon(proposed ? Icons.pending_outlined : Icons.verified),
          title: Text(
            proposed
                ? context.l10n.productProposed
                : context.l10n.productGlobal,
          ),
          subtitle: Text(
            proposed
                ? context.l10n.productProposedExplanation
                : context.l10n.productGlobalExplanation,
          ),
        ),
        if (proposed && canEdit)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton(
              onPressed: onPromote,
              child: Text(context.l10n.productPromoteAction),
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            context.l10n.gtinsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            context.l10n.gtinsExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        switch (ref.watch(productGtinsProvider(product.id))) {
          AsyncData(value: CatalogDone(:final value)) when value.isEmpty =>
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.gtinsEmpty),
            ),
          AsyncData(value: CatalogDone(:final value)) => Column(
            children: [
              for (final gtin in value)
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(gtin.gtin),
                  subtitle: Text(
                    [gtin.source, formatShortDate(gtin.createdAt)].join(' · '),
                  ),
                  trailing: canEdit
                      ? IconButton(
                          tooltip: context.l10n.gtinUnlinkAction,
                          icon: const Icon(Icons.link_off),
                          onPressed: () => onUnlink(gtin),
                        )
                      : null,
                ),
            ],
          ),
          AsyncData(value: CatalogRefused(:final failure)) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(failure.operatorMessage(context.l10n)),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
