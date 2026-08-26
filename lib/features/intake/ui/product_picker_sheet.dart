import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../catalog/ui/product_scan_view.dart';

/// Picking a product type from the **local** catalogue.
///
/// It searches against the cache and not against the API: the catalogue is
/// already on the device with the per-campaign visibility the server served, so
/// this works the same without signal and does not spend a request per
/// keystroke.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  /// Returns the chosen product, or null if it was closed without choosing.
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
              decoration: InputDecoration(
                labelText: context.l10n.productSearchTitle,
                helperText: context.l10n.productSearchHint,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          // Scanning is here and not on the application's bottom bar because
          // it only makes sense while looking for a product: what gets read is
          // the package the person is holding.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final product = await ProductScanView.push(context);
                if (product != null && context.mounted) {
                  Navigator.of(context).pop(product);
                }
              },
              icon: const Icon(Icons.barcode_reader),
              label: Text(context.l10n.barcodeScanAction),
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
                        label: Text(categoryLabel(context.l10n, category)),
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
                    subtitle: Text(_describe(context.l10n, product)),
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

  static String _describe(AppLocalizations l10n, ProductTypeRow product) => [
    categoryLabel(l10n, product.category),
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
        context.l10n.productSearchNoMatch,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
