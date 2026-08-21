import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../catalog/data/catalog_providers.dart';

/// Selección de tipo de producto desde el catálogo **local**.
///
/// Busca contra el cache y no contra la API: el catálogo ya está en el
/// dispositivo con la visibilidad por campaña que sirvió el servidor, así que
/// esto funciona igual sin señal y no gasta una petición por tecla.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  /// Devuelve el producto elegido, o nulo si se cerró sin elegir.
  static Future<ProductTypeRow?> show(BuildContext context) =>
      showModalBottomSheet<ProductTypeRow>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const ProductPickerSheet(),
      );

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(
      catalogSearchProvider((category: _category, search: _search)),
    );
    final categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? [];

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('product-search'),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                helperText: 'Por nombre, marca o principio activo',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(categoryLabel(category)),
                        selected: _category == category,
                        onSelected: (selected) => setState(
                          () => _category = selected ? category : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: switch (results) {
              AsyncData(:final value) when value.isEmpty => const _NoMatches(),
              AsyncData(:final value) => ListView.builder(
                padding: EdgeInsets.only(bottom: sheetBottomInset(context)),
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final product = value[index];
                  return ListTile(
                    title: Text(product.displayName),
                    subtitle: Text(_describe(product)),
                    trailing: product.isControlled
                        ? const Icon(Icons.gpp_maybe_outlined)
                        : null,
                    onTap: () => Navigator.of(context).pop(product),
                  );
                },
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  static String _describe(ProductTypeRow product) => [
    categoryLabel(product.category),
    ?product.brand,
    ?product.strength,
  ].join(' · ');
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Ningún producto del catálogo coincide. Si falta algo que sí existe, '
        'sincroniza con conexión: el catálogo local es el que el servidor '
        'sirvió para esta campaña.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
