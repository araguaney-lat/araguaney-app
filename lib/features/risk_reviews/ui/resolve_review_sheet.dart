import 'package:flutter/material.dart';

import '../data/risk_reviews_repository.dart';

/// Cerrar una revisión: qué se decide y por qué.
///
/// Las dos salidas se ofrecen a la vez y con el mismo peso visual. Esconder
/// «rechazar» detrás de un paso más haría de la decisión difícil la incómoda, y
/// quien coordina necesita poder tomarla igual de rápido que la fácil.
class ResolveReviewSheet extends StatefulWidget {
  const ResolveReviewSheet({super.key, required this.reason});

  /// El motivo por el que se levantó, a la vista mientras se decide.
  final String reason;

  static Future<({String resolution, String? note})?> show(
    BuildContext context, {
    required String reason,
  }) => showModalBottomSheet<({String resolution, String? note})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ResolveReviewSheet(reason: reason),
  );

  @override
  State<ResolveReviewSheet> createState() => _ResolveReviewSheetState();
}

class _ResolveReviewSheetState extends State<ResolveReviewSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _resolve(String resolution) {
    final note = _note.text.trim();
    Navigator.of(
      context,
    ).pop((resolution: resolution, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolver la revisión',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.reason, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            helperText: 'Queda con la revisión, para quien la lea después',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _resolve(RiskResolution.reject),
                child: const Text('Rechazar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _resolve(RiskResolution.approve),
                child: const Text('Aprobar'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
