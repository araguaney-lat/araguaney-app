import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../data/donations_providers.dart';

/// A qué producto del catálogo se parece lo que el donante escribió a mano.
///
/// Existe para no teclear dos veces la misma lista: quien recibe ve «10 cajas
/// de paracetamol» escrito por otra persona y necesita saber cuál es en el
/// catálogo. Las sugerencias las calcula el servidor.
///
/// **Silencio absoluto cuando no hay nada.** El servidor devuelve lista vacía
/// si la capacidad está apagada, sin presupuesto o el proveedor no contesta, y
/// ninguno de esos casos es un error de esta pantalla: recibir a mano nunca
/// dependió de que esto respondiera.
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
