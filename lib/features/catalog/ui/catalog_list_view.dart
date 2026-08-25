import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../data/catalog_providers.dart';
import '../data/catalog_repository.dart';
import 'product_form_view.dart';
import 'product_record_view.dart';

/// El catálogo, buscado desde el teléfono.
///
/// **Lo descargado responde primero y siempre.** Es lo único que funciona en un
/// sótano, y responde mientras se teclea sin gastar una petición por letra. El
/// servidor se consulta a mano y solo cuando lo local no alcanzó, que es la
/// única pregunta que el cache no puede contestar: si lo que falta no existe o
/// simplemente no está aquí.
class CatalogListView extends ConsumerStatefulWidget {
  const CatalogListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CatalogListView());

  @override
  ConsumerState<CatalogListView> createState() => _CatalogListViewState();
}

class _CatalogListViewState extends ConsumerState<CatalogListView> {
  final _search = TextEditingController();
  String _query = '';

  /// Lo que respondió el servidor a la última búsqueda pedida. Nulo mientras
  /// nadie la pidió, que no es lo mismo que haberla pedido y no encontrar nada.
  CatalogQuery? _asked;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _ask() => setState(() => _asked = (category: null, search: _query));

  @override
  Widget build(BuildContext context) {
    final query = (category: null, search: _query.isEmpty ? null : _query);
    final cached = ref.watch(catalogSearchProvider(query)).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.catalogTitle)),
      floatingActionButton: ref.watch(canEditCatalogProvider)
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).push(ProductFormView.route()),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.productNewTitle),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: context.l10n.catalogSearchLabel,
              ),
              onChanged: (value) => setState(() {
                _query = value.trim();
                // Una búsqueda vieja no se queda debajo de una consulta nueva:
                // se pidió por otro texto y ya no responde a lo que se ve.
                _asked = null;
              }),
              onSubmitted: (_) => _ask(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final product in cached) _ProductTile(product: product),
                if (cached.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _query.isEmpty
                          ? context.l10n.catalogEmpty
                          : context.l10n.catalogNothingCachedFor(_query),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_query.isNotEmpty)
                  _ServerSearch(query: _asked, onAsk: _ask),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que el dispositivo no tiene.
///
/// Se pide con un botón, no al teclear: cada búsqueda es una petición, y en la
/// conexión de un centro de acopio una por letra es la diferencia entre buscar
/// y esperar.
class _ServerSearch extends ConsumerWidget {
  const _ServerSearch({required this.query, required this.onAsk});

  final CatalogQuery? query;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: OutlinedButton.icon(
          onPressed: onAsk,
          icon: const Icon(Icons.cloud_outlined),
          label: Text(context.l10n.catalogSearchServerAction),
        ),
      );
    }

    return switch (ref.watch(serverCatalogSearchProvider(query!))) {
      AsyncData(value: CatalogDone(:final value)) when value.isEmpty => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.catalogNotOnServerEither,
          textAlign: TextAlign.center,
        ),
      ),
      AsyncData(value: CatalogDone(:final value)) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              context.l10n.catalogFoundOnServer,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          for (final product in value) _ProductTile(product: product),
        ],
      ),
      AsyncData(value: CatalogRefused(:final failure)) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          failure.operatorMessage(context.l10n),
          textAlign: TextAlign.center,
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductTypeRow product;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(product.displayName),
    subtitle: Text(
      [
        categoryLabel(context.l10n, product.category),
        product.defaultUnit,
        ?product.brand,
      ].join(' · '),
    ),
    trailing: product.campaignId == null
        ? null
        : Chip(label: Text(context.l10n.productProposed)),
    onTap: () =>
        Navigator.of(context).push(ProductRecordView.route(product.id)),
  );
}
