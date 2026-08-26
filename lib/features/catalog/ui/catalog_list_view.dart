import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../data/catalog_providers.dart';
import '../data/catalog_repository.dart';
import 'product_form_view.dart';
import 'product_record_view.dart';

/// The catalogue, searched from the phone.
///
/// **What was downloaded answers first and always.** It is the only thing that
/// works in a basement, and it answers while somebody types without spending a
/// request per letter. The server is consulted by hand and only when the local
/// one did not suffice, which is the one question the cache cannot answer:
/// whether what is missing does not exist or is simply not here.
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

  /// What the server answered to the last search that was asked for. Null while
  /// nobody has asked, which is not the same as having asked and found
  /// nothing.
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
                // An old search does not stay below a new query: it was asked
                // for with different text and no longer answers what is on
                // screen.
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

/// What the device does not have.
///
/// It is asked for with a button, not while typing: every search is a request,
/// and on a collection centre's connection one per letter is the difference
/// between searching and waiting.
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
