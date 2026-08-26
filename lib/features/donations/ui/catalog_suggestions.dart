import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../data/donations_providers.dart';

/// Which catalogue product resembles what the donor wrote by hand.
///
/// It exists so the same list is not typed twice: whoever receives sees «10
/// cajas de paracetamol» written by somebody else and needs to know which one
/// it is in the catalogue. The suggestions are computed by the server.
///
/// **Complete silence when there is nothing.** The server returns an empty list
/// if the capability is off, out of budget, or the provider does not answer,
/// and none of those is an error of this screen: receiving by hand never
/// depended on this answering.
class CatalogSuggestions extends ConsumerWidget {
  const CatalogSuggestions({super.key, required this.code, required this.text});

  final String code;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        ref
            .watch(catalogSuggestionsProvider((code: code, text: text)))
            .valueOrNull ??
        const [];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.donationSuggestionsTitle,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final product in suggestions)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(product.displayName),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
